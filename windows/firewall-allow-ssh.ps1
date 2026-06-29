# Allow inbound SSH (TCP 22)
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
  Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
  New-NetFirewallRule `
    -Name 'OpenSSH-Server-In-TCP' `
    -DisplayName 'OpenSSH Server (sshd)' `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort 22
} else {
  Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' already exists, ensuring it is enabled..."
  Enable-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
}
