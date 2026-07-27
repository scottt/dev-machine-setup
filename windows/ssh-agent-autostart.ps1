. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ErrorActionPreference = 'Stop'
Set-Service -Name ssh-agent -StartupType Automatic
if ((Get-Service -Name ssh-agent).Status -ne 'Running') {
    Start-Service -Name ssh-agent
}

# Load your keys
# ssh-add $env:USERPROFILE\.ssh\id_ed25519
