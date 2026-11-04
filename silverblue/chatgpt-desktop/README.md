# ChatGPT Desktop on Silverblue

OpenAI ships the official ChatGPT desktop app for Linux as an RPM from a signed
dnf repo:

    https://persistent.oaistatic.com/codex-app-prod/linux/rpm/$basearch

(The RPM is also published at a fixed "latest" URL, `…/linux/rpm/latest/chatgpt.x86_64.rpm`,
and installs the repo file itself.)

On an immutable Silverblue host we don't want to `rpm-ostree` layer a ~1.3 GiB
Electron app that has no repo behind it — every update would mean a new deployment
and a reboot.

So we run it in a **Distrobox**:

- **`Containerfile`** builds a `fedora-toolbox` image with exact versions of the
  `chatgpt` package and Google Chrome (see [Browser control](#browser-control))
  baked into layers. This is the reproducible, cacheable artifact — the app
  version is pinned to the image build, not to live network state.
- **`RPM-GPG-KEY-chatgpt.asc`** is the repo signing key (fingerprint
  `3BFA 0E4A E8B8 CC16 A2D9 BA68 4A3B 4A56 6C46 60E4`). OpenAI only publishes it
  inside the RPM; this copy was extracted from it and checked against the repo's
  `repomd.xml.asc` and the RPM's own signature.
- **`distrobox.ini`** creates a container from that image and exports the app
  to the host GNOME launcher (no manual `distrobox-export` needed).

This keeps the host immutable, needs no rebase or layering, and makes the setup
declarative and repeatable. Building the image (vs. an assemble-only manifest
with `init_hooks`) means recreating the container reuses cached layers instead
of re-downloading the RPM every time.

`chatgpt-desktop-install` and its update timer are thin wrappers around the
shared [`../lib/distrobox-app.sh`](../lib/distrobox-app.sh), also used by
[`../claude-desktop`](../claude-desktop).

## Install

```bash
./chatgpt-desktop-install
```

Then launch **ChatGPT (on chatgpt)** from the app grid, or `distrobox enter chatgpt`
and run `chatgpt-gui`.

## Update

Updates are automatic. Install also enables a systemd user timer,
`chatgpt-desktop-update.timer`, that once a day runs
`chatgpt-desktop-install --if-newer`:

1. Reads the newest `chatgpt` and `google-chrome-stable` versions from the two
   repos' metadata (a few KB) and compares them with the versions recorded in the
   image label `dev-machine-setup.versions`. If they match, it's done.
2. Otherwise rebuilds the image with the new versions as build args
   (`CHATGPT_VERSION`, `CHROME_VERSION`). Only the layers from the changed
   package on are rebuilt.
3. Recreates the `chatgpt` container on the new image — unless ChatGPT is running.
   Then it sends a desktop notification and applies the update on the first run
   after ChatGPT is closed.

Manually:

```bash
./chatgpt-desktop-install --check      # installed vs. latest; exit 100 if outdated
./chatgpt-desktop-install --if-newer   # what the timer runs
./chatgpt-desktop-install              # update now (closes ChatGPT if running)
systemctl --user list-timers chatgpt-desktop-update.timer
journalctl --user -u chatgpt-desktop-update.service
```

Use `./chatgpt-desktop-install --no-timer` to install without the timer. The
timer runs the script from this checkout, so re-run the install if you move it.

### Image layers

Layers are ordered so an update rebuilds as little as possible. Each layer is
rebuilt along with everything above it, so the most frequently changing layer
goes on top:

| Layer | Size | Rebuilt when |
|---|---|---|
| `fedora-toolbox:44` base | 1.1 GB | monthly |
| Dependencies of both apps | 0.6 GB | monthly (`DEPS_MONTH`) |
| Google Chrome | 0.5 GB | Chrome release (~weekly) |
| ChatGPT | 1.9 GB | ChatGPT release (several a week) |

A ChatGPT release rebuilds 1.9 GB; a Chrome release 2.4 GB. On the first
update of each month, the install script also passes `--pull=newer`, which
brings in a fresh `fedora-toolbox` base for OS updates and rebuilds everything.
(OS packages aren't upgraded inside a layer: that would store every upgraded
file twice.) To get OS updates sooner, `podman pull` the base and re-run the
install.

The ChatGPT app's own updater can't replace an RPM-installed package, so
rebuilding the image is the update path.

## Browser control

The app's built-in browser tab has no functional browser control bridge on Linux,
so it can't drive that tab itself. Instead, Google Chrome is installed in the
container and ChatGPT controls it through the ChatGPT Chrome extension:

<https://learn.chatgpt.com/docs/chrome-extension>

Install the extension in the container's Chrome (`distrobox enter chatgpt` and run
`google-chrome-stable`), not in the host's Chrome — the app can only reach the
browser that shares its container.

## Font cache

`/usr/local/bin/chatgpt-gui` wraps the real `/usr/bin/chatgpt` and points
`XDG_CACHE_HOME` at `~/.local/share/chatgpt-gui-container-cache`. It is named
`chatgpt-gui` so it can't collide with the binary and `chatgpt.desktop` entry the
RPM ships — the install script un-exports those by name. Sharing `~/.cache/fontconfig`
between the container and the host corrupts font availability for host apps —
Chrome and Electron apps like VSCode on the host stop seeing system fonts.
See [distrobox#358](https://github.com/89luca89/distrobox/issues/358).

## Other machines on the LAN

Other machines can copy the image from tt0 over SSH instead of building it:
`./chatgpt-desktop-install --from tt0-images`. See
[`../lib/README.md`](../lib/README.md#copying-the-images-to-other-machines-on-the-lan)
for the one-time SSH key setup.

## Alternative to watch: Universal Blue Homebrew cask

As of 2026-11-04, the Universal Blue (Bluefin / Aurora / Bazzite) project packages
ChatGPT Desktop as a Linux Homebrew cask, `chatgpt-linux`, in its **experimental**
tap:

- Cask: <https://github.com/ublue-os/experimental-tap/blob/main/Casks/chatgpt-linux.rb>
- Production tap (not there yet): <https://github.com/ublue-os/homebrew-tap>

```bash
brew tap ublue-os/experimental-tap
brew install --cask chatgpt-linux
```

The cask extracts OpenAI's RPM into the Homebrew prefix and runs it **on the host**
— no container. Running on the host would also make two parts of this setup
unnecessary: the container's own Chrome (the app could drive the host's Chrome) and
the [font cache](#font-cache) workaround. For now we're staying with the Distrobox:

- It's experimental (the tap's own README calls it in progress; the cask got a
  "allow normal brew upgrades" fix on 2026-10-31).
- The cask only checks a sha256 that the tap's bot recorded, not OpenAI's repo or
  RPM signatures.
- Bot version bumps come every few days. On 2026-11-04 the cask was at
  26.1027.51404 while the repo had 26.1029.61003.

Homebrew's own `chatgpt` cask is macOS-only.

**Monitor:** revisit when the cask moves to `ublue-os/homebrew-tap` (or into
homebrew-cask upstream). ChatGPT is the first one to switch, because a host install
removes the most special handling.
