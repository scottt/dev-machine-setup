# Claude Desktop on Silverblue

Anthropic ships the official Claude Desktop for Linux (beta) **only as a
Debian/Ubuntu `.deb`** from their apt repo. Fedora and RHEL are not supported,
and there is no rpm, Flatpak. On an immutable Silverblue host we
don't want to `rpm-ostree` layer a foreign `.deb` either.

So we run it in a **Distrobox**:

- **`Containerfile`** builds an Ubuntu 24.04 OCI image with the `claude-desktop`
  package baked into a layer. This is the reproducible, cacheable artifact —
  the app version is pinned to the image build, not to live network state.
- **`distrobox.ini`** creates a container from that image and exports the app
  to the host GNOME launcher (no manual `distrobox-export` needed).

This keeps the host immutable, needs no rebase or layering, and makes the setup
declarative and repeatable. Building the image (vs. an assemble-only manifest
with `init_hooks`) means recreating the container reuses cached layers instead
of re-hitting the apt repo every time.

## Install

```bash
./claude-desktop-install
```

Then launch **Claude (on claude)** from the app grid, or `distrobox enter claude`
and run `claude-desktop`.

## Update

Claude Desktop does not self-update on Linux. Rebuild the image and recreate the
container:

```bash
./claude-desktop-install
```

## Beta limitations

- Computer Use (app/screen control) is not available on Linux.
- Dictation / voice input is not available.
- Quick Entry global hotkey works on X11; on native Wayland it needs the
  desktop's GlobalShortcuts portal.
