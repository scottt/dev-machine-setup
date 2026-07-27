. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ruleName = 'OpenSSH-Server-In-TCP'
$rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue

if (-not $rule) {
  Write-Output "Firewall rule '$ruleName' does not exist; creating it..."
  New-NetFirewallRule -Name $ruleName `
    -DisplayName 'OpenSSH SSH Server (sshd)' `
    -Enabled True -Profile Private -Direction Inbound `
    -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
} else {
  Write-Output "Normalizing firewall rule '$ruleName'..."
  Set-NetFirewallRule -Name $ruleName -Enabled True -Profile Private `
    -Direction Inbound -Action Allow | Out-Null
  $rule | Get-NetFirewallPortFilter |
    Set-NetFirewallPortFilter -Protocol TCP -LocalPort 22 -RemotePort Any | Out-Null
}
