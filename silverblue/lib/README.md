# Shared Distrobox desktop-app tooling

- **`distrobox-app.sh`** — install / update logic behind
  [`../chatgpt-desktop/chatgpt-desktop-install`](../chatgpt-desktop) and
  [`../claude-desktop/claude-desktop-install`](../claude-desktop): version-pinned
  image builds, separate `--build` / `--deploy` modes, the `--check` / `--if-newer`
  modes, the update timer, and `--from`.
- **`distrobox-app-serve`** — SSH forced command that lets other machines copy
  the images from this one (below).

## Build and deploy separately

Both installers support the same two phases:

```bash
./chatgpt-desktop/chatgpt-desktop-install --build
./claude-desktop/claude-desktop-install --build

# Later, after closing each app:
./chatgpt-desktop/chatgpt-desktop-install --deploy
./claude-desktop/claude-desktop-install --deploy
```

`--build` produces the tagged image without replacing a container, exporting
launchers, or changing timers. It works while the app is running and on a build
host with no app container. `--deploy` uses the existing local image without
fetching metadata or building anything, and exports the launcher. It leaves
timers alone and fails before replacing anything if the image is missing or
the app is running. Use `--deploy --force` to explicitly close a running app.
Distrobox's first-start setup may still install container integration packages.

With no mode, the installer still builds and deploys, then installs the update
timer. This combined mode also requires `--force` to close a running app.
`--no-timer` skips timer installation for the combined mode.

Existing timers still run `--if-newer`: build/copy if needed, then deploy when
the app is closed. A manual `--build` does not disable those timers. To keep tt0
strictly build-only, disable any previously installed timers there:

```bash
systemctl --user disable --now chatgpt-desktop-update.timer claude-desktop-update.timer
```

## Copying the images to other machines on the LAN

One machine (tt0) builds the images; the others copy them from it over SSH
instead of building their own:

    ssh tt0 podman save <image-id> | podman load

On tt0, run the two `--build` commands above. Clients read the tagged image,
not the deployed container: tt0 can keep running an older image or have no
container at all. A successful build is immediately available to clients.

There's no registry or TLS to set up, and nothing is published anywhere: the
images contain proprietary apps (Claude Desktop, ChatGPT, Google Chrome) and
must stay on our own machines.

The image is requested by ID rather than tag, so a rebuild on tt0 can't swap it
mid-copy, and the client checks the ID it loaded. The ID is a digest of the
image config, which in turn pins every layer's digest.

The client's update timer runs `<app>-install --if-newer --from <host>` once a
day. It compares its image ID with tt0's (one `podman image inspect` over SSH),
copies on a mismatch, and installs the new image like a local build would —
deferred while the app is running. tt0's own timer picks up upstream releases on
the same daily schedule, so a client can be up to ~2 days behind upstream.

### Setup on a client

The timer runs unattended, so it needs a key without a passphrase. Use a
dedicated one that tt0 restricts to `distrobox-app-serve`. That key can then
only inspect the two app images and download their current IDs — no shell, no
port forwarding, nothing else.

1. On the client, create the key and an SSH host alias for it:

   ```bash
   ssh-keygen -t ed25519 -N '' -C "$(hostname) desktop-app images" \
       -f ~/.ssh/id_ed25519_tt0_images
   cat >>~/.ssh/config <<'EOF'

   Host tt0-images
       HostName tt0
       User scottt
       IdentityFile ~/.ssh/id_ed25519_tt0_images
       IdentitiesOnly yes
   EOF
   ```

2. On tt0, append the public key to `~/.ssh/authorized_keys` with the forced
   command:

   ```
   restrict,command="/var/home/scottt/work/dev-machine-setup/silverblue/lib/distrobox-app-serve" ssh-ed25519 AAAA... <client> desktop-app images
   ```

3. On the client, connect once interactively to accept tt0's host key (the
   timer uses `BatchMode`, so it can't answer that prompt), then install:

   ```bash
   ssh tt0-images podman image inspect localhost/claude-desktop:latest >/dev/null
   ./claude-desktop/claude-desktop-install --from tt0-images
   ./chatgpt-desktop/chatgpt-desktop-install --from tt0-images
   ```

`--from` works with `--build`, `--check`, `--if-newer`, the combined install
(including `--no-timer`), and `--timer`. The generated timer keeps it. To copy
now and deploy later on a client:

```bash
./chatgpt-desktop/chatgpt-desktop-install --build --from tt0-images
./chatgpt-desktop/chatgpt-desktop-install --deploy
```

`--deploy` accepts no `--from` because it uses only the local image. To switch a
client back to building locally, re-run the combined install or `--timer`
without `--from`.

A full copy is the whole image (Claude ~1.3 GB, ChatGPT ~4.1 GB uncompressed);
`podman save` doesn't skip layers the client already has. That's under a minute
on gigabit Ethernet.
