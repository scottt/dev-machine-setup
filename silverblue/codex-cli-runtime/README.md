# Standalone Codex primary runtime on Linux

Run `./install` as the desktop user. The one-time setup starts the verified runtime update, installs the read-only dependency locator in an isolated Python environment, registers it with Codex, and exposes the Presentations, Documents, PDF and Spreadsheets skills in `~/.agents/skills`. Setup requires uv, a configured Codex CLI and user systemd. The runtime updater uses system Python 3.11+, GNU tar with xz support, and curl.

## Scheduled work

`codex-cli-runtime.timer` triggers only `codex-cli-runtime.service`. Its sole command is the installed `bin/update` script. It checks the OpenAI primary runtime manifest daily at 03:30 local time plus up to 30 minutes of jitter. Persistent scheduling catches a missed run when the user's systemd manager next starts. Homebrew and its Codex CLI follow the user's existing upgrade process. MCP registration, skill smoke tests, and CLI executions are manual setup or acceptance operations.

The updater derives the stable manifest URL from the Linux host architecture. For x86-64 it uses [Linux x64 LATEST.json](https://persistent.oaistatic.com/codex-primary-runtime/latest/linux-x64/LATEST.json). It verifies archive size and SHA-256, checks runtime metadata, probes Python and Artifact Tool, and checks required helpers and skill files. Releases live under `~/.local/share/codex-cli-runtime/releases/<archive-sha256>/` with the release receipt. An atomic `current` symlink selects a validated release. Earlier releases remain available for rollback. The runtime resolver returns paths to the selected release. The desktop-managed runtime continues to use its original cache directory.

```sh
systemctl --user list-timers codex-cli-runtime.timer
systemctl --user start codex-cli-runtime.service
journalctl --user -u codex-cli-runtime.service -n 20
readlink -f ~/.local/share/codex-cli-runtime/current
```

## Manual verification

Run `./smoke-test documents`, `./smoke-test pdf`, `./smoke-test spreadsheets`, or `./smoke-test presentations`. Each uses a fresh directory, an authenticated Homebrew CLI, and strace. Inspect the printed directory for the artifact, model events, and file trace. These checks require Homebrew, strace, timeout and pdftotext. They incur normal model usage.
