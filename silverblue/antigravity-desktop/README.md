# Google Antigravity on Silverblue

Run Google's [Antigravity desktop app](https://antigravity.google/download) in
a Fedora Toolbox image managed by Distrobox and Podman. The installer selects
the official Linux tarball for x86-64 or ARM64 and pins its release in the image.

```bash
./antigravity-desktop-install
```

Open **Google Antigravity (on antigravity)** from the app grid. Deployment
removes the separate Distrobox shell shortcut (`antigravity.desktop`). Sign-in
opens in the host's default browser and returns through the exported
`antigravity://` handler.

The installer uses the [shared Distrobox update workflow](../lib/README.md).
It installs a daily `antigravity-desktop-update.timer` and defers deployment
while the app is open. Pass `--no-timer` to skip installing the timer.

```bash
./antigravity-desktop-install --check   # exit 100 if an update is available
./antigravity-desktop-install --build   # build the image while the app is open
./antigravity-desktop-install --deploy  # deploy the image after quitting the app
```
