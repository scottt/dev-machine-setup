# Firefox Add-on Policy Installer

Install Firefox add-ons from `add-ons.toml` by writing Firefox Enterprise Policy settings.

Install the managed Python version, then run with uv:

```powershell
uv python install 3.13
```

```powershell
uv run .\firefox-install-add-ons.py
```

On Windows, the default policy target is `auto`: the script writes `distribution\policies.json` next to the detected `firefox.exe`, then falls back to the current-user registry policy if that file write is denied.

To force the registry policy path on Windows:

```powershell
uv run .\firefox-install-add-ons.py --windows-policy-target registry
```

Restart Firefox after running, then check `about:policies`.
