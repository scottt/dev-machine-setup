# Windows dev machine setup

## Installing packages with winget

Package lists are stored in `.winget` files — one winget package ID per line.
Blank lines and lines starting with `#` are ignored, so you can add comments.

- `dev.winget` — general development tools (Git, PowerShell, VS Code, browsers, etc.).
- `agents.winget` — AI coding agents (OpenAI Codex, Claude Code).

`winget-install.ps1` installs every package listed in the files passed on the
command line. Pass one or more `.winget` files:

```powershell
.\winget-install.ps1 dev.winget
.\winget-install.ps1 dev.winget agents.winget
```

To add or remove a package, edit the relevant `.winget` file — no script
changes needed.

`winget-agents.ps1` installs `agents.winget` and then installs any Microsoft
Store-only apps:

```powershell
.\winget-agents.ps1
```
