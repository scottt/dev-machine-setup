# Dictation: "Your microphone isn't available"

Found on 2026-11-23 with Claude Desktop **6.28899.2** in the `claude` distrobox
(Ubuntu 24.04). The Code tab's dictation button failed with "Couldn't start
dictation" and "Your microphone isn't available".

## Cause

The container has no `libpulse.so.0`, because the image doesn't install
`libpulse0`.

- Permissions are fine. Every `Media permission probe` in
  `~/.config/Claude/logs/main.log` shows `result: 'granted'` for audio.
- Chromium loads libpulse on the fly and quietly falls back to ALSA when it's
  missing. The app's `AudioService` utility process had only `libasound.so.2`
  mapped, with no libpulse.
- The container's ALSA can't reach the host's audio: it has no `pipewire-alsa`
  or `libasound2-plugins`, so no default device leads to PipeWire. Chromium
  finds no capture device.
- The host sockets are visible in the container
  (`/run/user/1000/pulse/native`, `/run/user/1000/pipewire-0`). Only the
  client library is missing.
- The logs don't record the failed library load, so check the process maps:
  `grep -E 'pulse|asound' /proc/$(pgrep -f AudioService | head -1)/maps`

## Fix

```bash
distrobox enter claude -- sudo apt install -y libpulse0
```

Then quit Claude Desktop completely and start it again. The Containerfile's
dependency layer now installs `libpulse0`, so rebuilt images
(`./claude-desktop-install`) include it.

To verify, install `pulseaudio-utils` and run `pactl list short sources`
inside the container.
