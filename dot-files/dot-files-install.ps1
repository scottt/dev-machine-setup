PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
 
New-Item $profile -Type File -Force
cp Microsoft.PowerShell_profile.ps1 $profile