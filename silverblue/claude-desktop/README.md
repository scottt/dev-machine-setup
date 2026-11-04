# Claude Desktop on Silverblue

Anthropic ships the official Claude Desktop for Linux (beta) **only as a
Debian/Ubuntu `.deb`** from their apt repo. Fedora and RHEL are not supported,
and there is no rpm, Flatpak. On an immutable Silverblue host we
don't want to `rpm-ostree` layer a foreign `.deb` either.

So we run it in a **Distrobox**:

- **`Containerfile`** builds an Ubuntu 24.04 OCI image with an exact version of
  the `claude-desktop` package baked into a layer. This is the reproducible, cacheable artifact —
  the app version is pinned to the image build, not to live network state.
- **`distrobox.ini`** creates a container from that image and exports the app
  to the host GNOME launcher (no manual `distrobox-export` needed).

This keeps the host immutable, needs no rebase or layering, and makes the setup
declarative and repeatable. Building the image (vs. an assemble-only manifest
with `init_hooks`) means recreating the container reuses cached layers instead
of re-hitting the apt repo every time.

`claude-desktop-install` and its update timer are thin wrappers around the
shared [`../lib/distrobox-app.sh`](../lib/distrobox-app.sh), also used by
[`../chatgpt-desktop`](../chatgpt-desktop).

## Install

```bash
./claude-desktop-install
```

Then launch **Claude (on claude)** from the app grid, or `distrobox enter claude`
and run `claude-gui`.

## Update

Claude Desktop does not self-update on Linux, so updates come from rebuilding the
image. This is automatic: install also enables a systemd user timer,
`claude-desktop-update.timer`, that once a day runs
`claude-desktop-install --if-newer`:

1. Reads the newest `claude-desktop` version from the apt repo's `Packages` index
   and compares it with the version recorded in the image label
   `dev-machine-setup.versions`. If they match, it's done.
2. Otherwise rebuilds the image with `CLAUDE_VERSION` as a build arg, which
   invalidates the cached `apt-get install` layer. (A plain `podman build`
   would reuse that cached layer and never pick up a new release.)
3. Recreates the `claude` container on the new image — unless Claude is running.
   Then it sends a desktop notification and applies the update on the first run
   after Claude is closed.

Manually:

```bash
./claude-desktop-install --check      # installed vs. latest; exit 100 if outdated
./claude-desktop-install --if-newer   # what the timer runs
./claude-desktop-install              # update now (closes Claude if running)
systemctl --user list-timers claude-desktop-update.timer
journalctl --user -u claude-desktop-update.service
```

Use `./claude-desktop-install --no-timer` to install without the timer. The
timer runs the script from this checkout, so re-run the install if you move it.

The apt repo keeps old releases, so a specific version can be pinned by hand:
`podman build --build-arg CLAUDE_VERSION=<version> -t localhost/claude-desktop:latest .`
(disable the timer first, or its next run moves you back to the latest version).

### Image layers

The app's dependencies (0.5 GB) are in their own layer below the app (0.65 GB),
so a release rebuilds only the app layer. The dependency layer is rebuilt
monthly (`DEPS_MONTH`). On the first update of each month, the install script
also passes `--pull=newer`, which brings in a fresh `ubuntu:24.04` base for OS
updates. To get OS updates sooner, `podman pull` the base and re-run the
install.

## Beta limitations

- Computer Use (app/screen control) is not available on Linux.
- Dictation / voice input is not available.
- Quick Entry global hotkey works on X11; on native Wayland it needs the
  desktop's GlobalShortcuts portal.

## Other machines on the LAN

Other machines can copy the image from tt0 over SSH instead of building it:
`./claude-desktop-install --from tt0-images`. See
[`../lib/README.md`](../lib/README.md#copying-the-images-to-other-machines-on-the-lan)
for the one-time SSH key setup.

## Alternative to watch: Universal Blue Homebrew cask

As of 2026-11-04, the Universal Blue (Bluefin / Aurora / Bazzite) project packages
Claude Desktop as a Linux Homebrew cask, `claude-desktop-linux`, in its
**experimental** tap:

- Cask: <https://github.com/ublue-os/experimental-tap/blob/main/Casks/claude-desktop-linux.rb>
- Production tap (not there yet): <https://github.com/ublue-os/homebrew-tap>

```bash
brew tap ublue-os/experimental-tap
brew install --cask claude-desktop-linux
```

The cask extracts Anthropic's `.deb` into the Homebrew prefix and runs it **on the
host** — no container. It's simpler than this setup, but for now we're staying with
the Distrobox:

- It's experimental (the tap's own README calls it in progress).
- The Ubuntu-built app runs against Fedora's libraries, which Anthropic doesn't
  support. The container gives it Ubuntu 24.04.
- The cask only checks a sha256 that the tap's bot recorded, not the signature
  on Anthropic's apt repo.
- Bot version bumps come every few days. On 2026-11-04 the cask was at 4.4212.0
  while the apt repo had 4.16336.0.

Homebrew's own `claude` cask is macOS-only.

**Monitor:** revisit when the cask moves to `ublue-os/homebrew-tap` (or into
homebrew-cask upstream). Switching would replace this directory's Containerfile,
install script and update timer with `brew install --cask` + `brew upgrade`.
