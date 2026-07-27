# Smart App Control blocks unsigned developer-built executables, including the
# Python launcher that uv creates in project virtual environments. This is a
# development-machine policy choice, not an exception for one project.
# Smart App Control has no per-app bypass:
# https://support.microsoft.com/en-us/windows/smart-app-control-frequently-asked-questions-285ea03d-fa88-4d56-882e-6698afdb7003
#
# Microsoft documents this registry value for proactively configuring Smart
# App Control across managed endpoints:
# https://learn.microsoft.com/windows/security/application-security/application-control/app-control-for-business/appcontrol
. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$ErrorActionPreference = 'Stop'

$policyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy'
$valueName = 'VerifiedAndReputablePolicyState'
$disabledState = 0

$currentState = Get-ItemPropertyValue `
    -Path $policyPath `
    -Name $valueName `
    -ErrorAction SilentlyContinue

if ($currentState -eq $disabledState) {
    Write-Output 'Smart App Control is already disabled.'
} else {
    Write-Output "Disabling Smart App Control (previous state: $currentState)..."
    New-ItemProperty `
        -Path $policyPath `
        -Name $valueName `
        -Value $disabledState `
        -PropertyType DWord `
        -Force | Out-Null
}

# Refresh active Code Integrity policies so the change takes effect without
# waiting for the next restart.
& "$env:SystemRoot\System32\CiTool.exe" -r
if ($LASTEXITCODE -ne 0) {
    throw "CiTool.exe failed to refresh Code Integrity policies (exit code $LASTEXITCODE)."
}

$effectiveState = Get-ItemPropertyValue -Path $policyPath -Name $valueName
if ($effectiveState -ne $disabledState) {
    throw "Smart App Control state is $effectiveState after configuration; expected $disabledState."
}

Get-ItemProperty -Path $policyPath -Name $valueName |
    Select-Object $valueName
