# Several scripts below change machine-wide settings. Elevate once so the
# sequence does not fail partway through after applying only user settings.
. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ErrorActionPreference = 'Stop'

# Preferences
& "$PSScriptRoot\dark-mode.ps1"
& "$PSScriptRoot\time-format.ps1"
& "$PSScriptRoot\clock-utc.ps1"
& "$PSScriptRoot\network-set-default-private.ps1"
function Get-DefaultNetworkContext {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 |
        Sort-Object {
            $_.RouteMetric +
                (Get-NetIPInterface -InterfaceIndex $_.ifIndex -AddressFamily IPv4).InterfaceMetric
        } |
        Select-Object -First 1

    [pscustomobject]@{
        InterfaceIndex = $route.ifIndex
        Address = Get-NetIPAddress -InterfaceIndex $route.ifIndex -AddressFamily IPv4 |
            Where-Object AddressState -eq Preferred |
            Select-Object -First 1 -ExpandProperty IPAddress
    }
}

function Write-NetworkSetDefaultPrivateVerification {
    param([Parameter(Mandatory)] $NetworkContext)

    Write-Output '=== NETWORK ==='
    Get-NetConnectionProfile -InterfaceIndex $NetworkContext.InterfaceIndex |
        Format-List InterfaceAlias, Name, NetworkCategory
}

& "$PSScriptRoot\firewall-allow-ping.ps1"
function Write-FirewallAllowPingVerification {
    Write-Output '=== PING RULES ==='
    Get-NetFirewallRule `
        -Name 'DevSetup-Allow-ICMPv4-Echo-In', 'DevSetup-Allow-ICMPv6-Echo-In' |
        Format-Table Name, Enabled, Profile, Direction, Action -AutoSize
}

# SSH Client
& "$PSScriptRoot\ssh-agent-autostart.ps1"
function Write-SshAgentAutostartVerification {
    Write-Output '=== SSH AGENT SERVICE ==='
    Get-Service ssh-agent | Format-Table Name, Status, StartType -AutoSize
}

# SSH Server
& "$PSScriptRoot\sshd-install.ps1"
& "$PSScriptRoot\sshd-enable.ps1"
function Write-SshdEnableVerification {
    param([Parameter(Mandatory)] $NetworkContext)

    Write-Output '=== SSHD SERVICE ==='
    Get-Service sshd | Format-Table Name, Status, StartType -AutoSize

    Write-Output '=== SSH LISTENER ==='
    netstat -ano -p tcp | Select-String -Pattern ':22\s+.*LISTENING'

    Write-Output '=== SSH RULE ==='
    Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' |
        Format-List Enabled, Profile, Direction, Action, PrimaryStatus
    Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' |
        Get-NetFirewallPortFilter |
        Format-List Protocol, LocalPort, RemotePort

    Write-Output '=== TCP CHECK ==='
    Test-NetConnection -ComputerName $NetworkContext.Address -Port 22 -InformationLevel Quiet
}

& "$PSScriptRoot\sshd-start-pwsh.ps1"
function Write-SshdStartPwshVerification {
    Write-Output '=== DEFAULT SSH SHELL ==='
    Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell
}

$networkContext = Get-DefaultNetworkContext
Write-NetworkSetDefaultPrivateVerification -NetworkContext $networkContext
Write-SshAgentAutostartVerification
Write-SshdEnableVerification -NetworkContext $networkContext
Write-FirewallAllowPingVerification
Write-SshdStartPwshVerification
