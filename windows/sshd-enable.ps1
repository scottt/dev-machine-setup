. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ErrorActionPreference = 'Stop'

# Start the sshd service
Set-Service -Name sshd -StartupType 'Automatic'
if ((Get-Service -Name sshd).Status -ne 'Running') {
	Start-Service -Name sshd
}

& "$PSScriptRoot\firewall-allow-ssh.ps1"
