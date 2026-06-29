$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
$isAdministrator = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdministrator) {
	throw "Run this script from an elevated PowerShell session."
}

# Start the sshd service
Start-Service sshd

Set-Service -Name sshd -StartupType 'Automatic'

if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
	Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
	New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
	Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' already exists, ensuring it is enabled..."
	Enable-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
}
