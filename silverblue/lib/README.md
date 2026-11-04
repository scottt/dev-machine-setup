# Shared Distrobox desktop-app tooling

- **`distrobox-app.sh`** — install / update logic behind
  [`../chatgpt-desktop/chatgpt-desktop-install`](../chatgpt-desktop) and
  [`../claude-desktop/claude-desktop-install`](../claude-desktop): version-pinned
  image builds, the `--check` / `--if-newer` modes, the update timer, and `--from`.
- **`distrobox-app-serve`** — SSH forced command that lets other machines copy
  the images from this one (below).

## Copying the images to other machines on the LAN

One machine (tt0) builds the images; the others copy them from it over SSH
instead of building their own:

    ssh tt0 podman save <image-id> | podman load

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

`--from` works with every mode (`--check`, `--if-newer`, `--no-timer`), and the
generated timer keeps it. To switch a client back to building locally, re-run
the install without `--from`.

A full copy is the whole image (Claude ~1.3 GB, ChatGPT ~4.1 GB uncompressed);
`podman save` doesn't skip layers the client already has. That's under a minute
on gigabit Ethernet.
