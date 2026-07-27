. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ErrorActionPreference = 'Stop'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
