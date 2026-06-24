PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
PowerShellGet\Install-Module PSFzf -Scope CurrentUser -Force
 
New-Item $profile -Type File -Force
Copy-Item Microsoft.PowerShell_profile.ps1 $profile -Force

# wezterm
New-Item -ItemType Directory -Force -Path "$HOME\.config\wezterm" | Out-Null
Copy-Item -Path ".\wezterm.lua" -Destination "$HOME\.config\wezterm\" -Force