# Windows dev machine setup

## Developer application policy

`windows-preferences-apply-all.ps1` disables Smart App Control as a deliberate
development-machine policy. Smart App Control has no per-application bypass and
blocks unsigned developer-built executables, including Python launchers created
by uv in project virtual environments.

The setup writes Microsoft's documented
`VerifiedAndReputablePolicyState = 0` machine policy and refreshes Code
Integrity policies with `CiTool.exe`. Run the standalone policy step with:

```powershell
.\smart-app-control-disable.ps1
```

This lowers application-control protection for the whole machine and should be
used only on machines intended for software development.

## Installing packages with winget

Package lists are stored in `.winget` files — one winget package ID per line.
Blank lines and lines starting with `#` are ignored, so you can add comments.

- `dev.winget` — general development tools (Git, PowerShell, VS Code, browsers, etc.).
- `agents.winget` — AI coding agents (OpenAI Codex, Claude Code).

`winget-install.ps1` installs every package listed in the files passed on the
command line using machine scope by default. It requests elevated privileges
automatically when needed. Pass one or more `.winget` files:

```powershell
.\winget-install.ps1 dev.winget
.\winget-install.ps1 dev.winget agents.winget
```

To add or remove a package, edit the relevant `.winget` file — no script
changes needed.

Package-specific winget arguments are stored in `winget-options.toml`:

```toml
[packages."Microsoft.PowerShell"]
args = ["--installer-type", "wix"]
```

Keep package membership in `.winget` files. Use `winget-options.toml` only when
a package needs extra install arguments. A package can request user scope by
adding `["--scope", "user"]` to its args.

`winget-agents.ps1` requests elevated privileges automatically, installs
`agents.winget`, and then installs any Microsoft Store-only apps:

```powershell
.\winget-agents.ps1
```
