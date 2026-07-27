# Mark the default network interface (the one carrying the default route) as Private.
# Useful so Private-scoped firewall rules (e.g. OpenSSH-Server-In-TCP) apply to it.
. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ErrorActionPreference = 'Stop'

# Pick the active default route: lowest combined (interface metric + route metric),
# matching how Windows chooses the route used for off-link traffic.
$defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction Stop |
	Sort-Object {
		$_.RouteMetric + (Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily IPv4).InterfaceMetric
	} |
	Select-Object -First 1

if (-not $defaultRoute) {
	throw "No IPv4 default route found; cannot determine the default network interface."
}

$connProfile = Get-NetConnectionProfile -InterfaceIndex $defaultRoute.ifIndex -ErrorAction Stop

if ($connProfile.NetworkCategory -eq 'Private') {
	Write-Output "Default interface '$($connProfile.InterfaceAlias)' is already Private."
} else {
	Write-Output "Setting default interface '$($connProfile.InterfaceAlias)' from $($connProfile.NetworkCategory) to Private..."
	Set-NetConnectionProfile -InterfaceIndex $defaultRoute.ifIndex -NetworkCategory Private
}
