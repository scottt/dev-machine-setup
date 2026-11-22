# Linux CLI and workspace runtime experiments

Run on the Linux x64 host from this directory. Both tracks use the same authenticated host account, read-only workspace-runtime MCP locator, and user Presentations skill symlink into the standard runtime location. The desktop track runs the RPM's CLI as a standalone host executable. Electron participates in release selection. Desktop viewer and Space tools are outside this experiment.

```sh
logs=$(./capture-runtime-selection chatgpt)
./runtime-track desktop --desktop-log-dir "$logs"
./runtime-track homebrew
```

The capture helper starts the installed RPM in a temporary headless profile. The selection is for that profile and launch. Targeted configuration for a signed-in profile can differ. Use a fresh log directory from that profile to test its selection. An explicit desktop selection is required. The desktop track records the stable channel's Linux platform entry, source, timestamp and RPM version and copies the packaged CLI, code-mode host and ripgrep from the container.

The Homebrew track resolves the CLI through `brew --prefix` and saves the exact [Linux stable release manifest](https://persistent.oaistatic.com/codex-primary-runtime/latest/linux-x64/LATEST.json). Each run verifies the archive size and SHA-256. A per-digest cache allows both tracks to share one download. Bubblewrap mounts the extracted runtime read-only over the standard installation path only in the run's process namespace. The host installation and the desktop RPM remain separate.

Both tracks ask for a one-slide PowerPoint named `probe.pptx` containing only `Hello`. The runner records CLI version and binary hash, runtime metadata, plugin versions, release provenance, child process trace, and model events. A passing run requires a successful CLI exit, a read of the Presentations skill and Artifact Tool entry module, and a valid PPTX containing one slide and the expected text. The full records, prompt, and deck are in the private run directory printed at startup under `~/.cache/codex-runtime-tracks/`. Release receipts and result summaries from the initial comparison are in `runtime-track-evidence/`.

The desktop updater checks on startup and periodically while the app runs, at a randomized minute each hour, subject to release configuration and workspace-dependency gates. Building the RPM container alone does not trigger that poll.
