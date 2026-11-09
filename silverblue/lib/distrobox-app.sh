# shellcheck shell=bash disable=SC2154 # app_* / image / container are set by the sourcing script
# Shared install / update flow for desktop apps baked into a locally built
# image and run from a Distrobox. Sourced by */<app_id>-install.
#
# The sourcing script sets:
#   app_name     human-readable name for messages and notifications ("Claude")
#   app_id       prefix for the install script and systemd units ("claude-desktop")
#   app_dir      directory holding Containerfile and distrobox.ini
#   app_icon     icon name for notifications
#   app_process  process name (comm) of the running app, matched with `pgrep -x`
#   image        local image tag
#   container    Distrobox container name
# and defines:
#   app_versions                 print "BUILD_ARG=VERSION" lines, one per pinned
#                                package, for the newest upstream versions
#   app_remove_stale_launchers   (optional) run after the container is recreated
# and optionally sets:
#   app_timer_calendar   OnCalendar= of the update timer, e.g. "*-*-* 02:30:00
#                        Asia/Taipei" to run soon after upstream usually publishes.
#                        Default: daily, at a random time in the first hour.
#
# The pinned versions are passed to `podman build` as build args, which is what
# invalidates the layer cache when (and only when) upstream ships a new version.
# They are also recorded in the image label below, so an update check is a
# metadata fetch plus `podman image inspect`.

#
# With `--from HOST`, the image is instead copied over SSH from another machine
# that builds it (`ssh HOST podman save | podman load`), and "latest" means that
# machine's current image. HOST can restrict the key to this with
# lib/distrobox-app-serve.

versions_label="dev-machine-setup.versions"
source_host="" # set by --from

usage() {
	cat <<EOF
usage: $(basename "$0") [--check | --if-newer | --no-timer | --timer] [--from HOST]

  (no option)  build the image with the newest upstream versions, (re)create the
               '$container' Distrobox, and install the ${app_id}-update.timer
  --no-timer   same, without installing the systemd user timer
  --timer      only (re)install the ${app_id}-update.timer
  --check      print installed and latest versions; exit 0 if up to date,
               100 if an update is available
  --if-newer   unattended update (what the timer runs): rebuild only if upstream
               changed; recreate the container only while $app_name isn't running,
               otherwise notify and retry on the next run
  --from HOST  copy the image from HOST over SSH instead of building it here;
               "latest" is HOST's current image. Combines with the modes above,
               and the timer keeps using HOST.
EOF
}

log() { printf '%s: %s\n' "$app_id" "$*" >&2; }

# rpm_repo_latest BASEURL PACKAGE: print VERSION-RELEASE of the newest PACKAGE
# in an rpm-md repo (dnf `NAME-VERSION-RELEASE` pin syntax). Fetches with curl:
# OpenAI's CDN rejects Python's urllib user agent with 403.
rpm_repo_latest() {
	local base="${1%/}" name="$2" primary
	primary="$(curl -fsSL "$base/repodata/repomd.xml" | python3 -I -c '
import sys, xml.etree.ElementTree as ET
ns = {"repo": "http://linux.duke.edu/metadata/repo"}
for data in ET.parse(sys.stdin).iterfind("repo:data", ns):
    if data.get("type") == "primary":
        print(data.find("repo:location", ns).get("href"))
')"
	curl -fsSL "$base/$primary" | gzip -dc | python3 -I -c '
import sys, xml.etree.ElementTree as ET
ns = {"c": "http://linux.duke.edu/metadata/common"}
for pkg in ET.parse(sys.stdin).iterfind("c:package", ns):
    if pkg.findtext("c:name", namespaces=ns) == sys.argv[1]:
        v = pkg.find("c:version", ns)
        print(v.get("ver") + "-" + v.get("rel"))
' "$name" | sort -V | tail -n 1
}

# apt_repo_latest PACKAGES_URL PACKAGE: print the newest Version of PACKAGE in
# an apt Packages index (apt `NAME=VERSION` pin syntax).
apt_repo_latest() {
	curl -fsSL "$1" | awk -v pkg="$2" '
		/^Package:/ { p = $2 }
		/^Version:/ && p == pkg { print $2 }' | sort -V | tail -n 1
}

latest_versions() {
	local out
	out="$(app_versions)" || return 1
	# Fail rather than build with an empty pin if a metadata fetch came back empty.
	if grep -qE '^[A-Z_]+=$' <<<"$out" || [ -z "$out" ]; then
		log "could not resolve upstream versions:"$'\n'"$out"
		return 1
	fi
	# DEPS_MONTH keys the Containerfiles' dependency layer, below the app
	# layers: it's rebuilt (with a full OS package upgrade) once a month, and
	# app releases in between reuse it.
	printf '%s\nDEPS_MONTH=%s\n' "$out" "$(date -u +%Y-%m)" | sort | paste -sd ' '
}

installed_versions() {
	podman image inspect --format "{{index .Labels \"$versions_label\"}}" "$image" 2>/dev/null || true
}

image_id() { podman image inspect --format '{{.Id}}' "$image" 2>/dev/null || true; }
container_image_id() { podman container inspect --format '{{.Image}}' "$container" 2>/dev/null || true; }

# Distrobox shares the host PID namespace, so the app's processes are visible here.
app_running() { pgrep -x "$app_process" >/dev/null; }

notify() {
	command -v notify-send >/dev/null || return 0
	notify-send --app-name="$app_name" --icon="$app_icon" "$@" 2>/dev/null || true
}

# Remove an image we replaced, unless a container still uses it (rmi refuses).
remove_image() {
	local old="$1"
	[ -n "$old" ] && [ "$old" != "$(image_id)" ] || return 0
	podman rmi "$old" >/dev/null 2>&1 || true
}

build_image() {
	local versions="$1" old_id args=() kv
	old_id="$(image_id)"
	for kv in $versions; do args+=(--build-arg "$kv"); done
	# A new DEPS_MONTH rebuilds everything anyway, so take that build as the
	# monthly chance to pick up OS updates from a fresh base image. Upgrading
	# packages inside a layer instead would store each upgraded file twice.
	local month="DEPS_MONTH=${versions##*DEPS_MONTH=}"
	month="${month%% *}"
	[[ " $(installed_versions) " == *" $month "* ]] || args+=(--pull=newer)
	podman build --label "$versions_label=$versions" "${args[@]}" -t "$image" "$app_dir"
	# A superseded build that never made it into the container is garbage now.
	[ "$old_id" = "$(container_image_id)" ] || remove_image "$old_id"
}

recreate_container() {
	local old_id
	old_id="$(container_image_id)"
	# (Re)create the Distrobox from the manifest and export the app to the host
	# launcher. --replace makes this idempotent.
	distrobox assemble create --replace --file "$app_dir/distrobox.ini"
	if declare -F app_remove_stale_launchers >/dev/null; then
		app_remove_stale_launchers
	fi
	remove_image "$old_id"
}

install_timer() {
	local units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user" when
	if [ -n "${app_timer_calendar:-}" ]; then
		when="OnCalendar=$app_timer_calendar"
	else
		when=$'OnCalendar=daily\nRandomizedDelaySec=1h'
	fi
	mkdir -p "$units"
	cat >"$units/${app_id}-update.service" <<EOF
# Generated by $app_dir/${app_id}-install
[Unit]
Description=Update the $app_name Desktop Distrobox image

[Service]
Type=oneshot
ExecStart="$app_dir/${app_id}-install" --if-newer${source_host:+ --from "$source_host"}
Nice=10
IOSchedulingClass=idle
EOF
	cat >"$units/${app_id}-update.timer" <<EOF
# Generated by $app_dir/${app_id}-install
[Unit]
Description=Check for $app_name Desktop updates

[Timer]
# Once a day. An update found while the app is open is applied on the first
# run after it's closed. Persistent: a run missed while the machine was off
# happens soon after it's back.
$when
Persistent=true

[Install]
WantedBy=timers.target
EOF
	systemctl --user daemon-reload
	systemctl --user enable --now "${app_id}-update.timer"
}

ssh_source() { ssh -o BatchMode=yes "$source_host" "$@"; }

# Set `latest` (versions string) and, with --from, `latest_id` (HOST's image ID).
resolve_latest() {
	latest_id=""
	if [ -z "$source_host" ]; then
		latest="$(latest_versions)"
		return
	fi
	local out
	if ! out="$(ssh_source podman image inspect "$image" | python3 -I -c '
import json, sys
img = json.load(sys.stdin)[0]
print(img["Id"])
print((img.get("Labels") or {}).get(sys.argv[1], ""))
' "$versions_label")"; then
		log "can't inspect $image on $source_host"
		return 1
	fi
	latest_id="${out%%$'\n'*}"
	latest="${out#*$'\n'}"
}

# With --from, compare image IDs: exact, and also catches a rebuild on HOST
# that didn't change versions (e.g. an edited Containerfile).
up_to_date() {
	if [ -n "$source_host" ]; then
		[ "$(image_id)" = "$latest_id" ]
	else
		[ "$(installed_versions)" = "$latest" ]
	fi
}

# Stream HOST's image by ID (not tag, so a rebuild there mid-copy can't swap it),
# check the ID survived the trip, then tag it here.
copy_image() {
	local old_id
	old_id="$(image_id)"
	log "copying $latest from $source_host"
	ssh_source podman save "$latest_id" | podman load --quiet >/dev/null
	if ! podman image exists "$latest_id"; then
		log "image $latest_id from $source_host didn't load"
		return 1
	fi
	podman tag "$latest_id" "$image"
	[ "$old_id" = "$(container_image_id)" ] || remove_image "$old_id"
}

obtain_image() {
	if [ -n "$source_host" ]; then
		copy_image
	else
		build_image "$latest"
	fi
}

do_check() {
	local installed latest latest_id
	installed="$(installed_versions)"
	resolve_latest
	printf 'installed: %s\nlatest:    %s%s\n' "${installed:-(none)}" "$latest" \
		"${source_host:+ (on $source_host)}"
	up_to_date || return 100
}

do_install() {
	local timer="$1" latest latest_id
	resolve_latest
	# Building is always run: it's instant when cached, and picks up local
	# Containerfile edits that don't change any version.
	if [ -z "$source_host" ] || ! up_to_date; then
		obtain_image
	fi
	app_running && log "$app_name is running; recreating the container will close it"
	recreate_container
	[ "$timer" = no ] || install_timer
}

do_if_newer() {
	local latest latest_id built=no
	resolve_latest
	if ! up_to_date; then
		log "updating to $latest"
		obtain_image
		built=yes
	fi
	# Covers both a fresh build and one left pending by an earlier run.
	if [ "$(container_image_id)" != "$(image_id)" ]; then
		if app_running; then
			log "$app_name is running; update pending until it's closed"
			[ "$built" = no ] || notify "$app_name update ready" \
				"Quit $app_name to let the next update check install it, or run ${app_id}-install."
		else
			recreate_container
			log "installed $latest"
		fi
	fi
}

distrobox_app_main() {
	local mode=install timer=yes
	while [ $# -gt 0 ]; do
		case "$1" in
		--check | --if-newer) mode="${1#--}" ;;
		--no-timer) timer=no ;;
		--timer) mode=timer ;;
		--from)
			[ $# -ge 2 ] || { usage >&2; return 2; }
			source_host="$2"
			shift
			;;
		-h | --help) usage; return ;;
		*) usage >&2; return 2 ;;
		esac
		shift
	done
	case "$mode" in
	install) do_install "$timer" ;;
	check) do_check ;;
	if-newer) do_if_newer ;;
	timer) install_timer ;;
	esac
}
