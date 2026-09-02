# ChatGPT Desktop on Silverblue

OpenAI ships the official ChatGPT desktop app for Linux as an **RPM published at
a fixed "latest" URL**, not through a yum repo:

    https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm

On an immutable Silverblue host we don't want to `rpm-ostree` layer a ~1.3 GiB
Electron app that has no repo behind it — every update would mean a new deployment
and a reboot.

So we run it in a **Distrobox**:

- **`Containerfile`** builds a `fedora-toolbox` image with the `chatgpt` package
  baked into a layer. This is the reproducible, cacheable artifact — the app
  version is pinned to the image build, not to live network state. Google Chrome
  is installed from Google's rpm repo in the same image — see
  [Browser control](#browser-control).
- **`distrobox.ini`** creates a container from that image and exports the app
  to the host GNOME launcher (no manual `distrobox-export` needed).

This keeps the host immutable, needs no rebase or layering, and makes the setup
declarative and repeatable. Building the image (vs. an assemble-only manifest
with `init_hooks`) means recreating the container reuses cached layers instead
of re-downloading the RPM every time.

## Install

```bash
./chatgpt-desktop-install
```

Then launch **ChatGPT (on chatgpt)** from the app grid, or `distrobox enter chatgpt`
and run `chatgpt-gui`.

## Update

The URL above always points at the current release, and the `dnf5 install` layer
is cached, so a rebuild only picks up a new version once that layer is invalidated:

```bash
podman build --no-cache -t localhost/chatgpt-desktop:latest .
./chatgpt-desktop-install
```

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
