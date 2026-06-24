# Add a user to the local Administrators group.
# Must be run from an elevated (Run as Administrator) PowerShell.
#
# Identifies the user by SID rather than by a "DOMAIN\name" string, so it works
# for local, domain, Entra (Azure AD), and Microsoft accounts. With no -User
# argument it adds the *current* user.
param(
    [string]$User
)

# Require elevation
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator."
    exit 1
}

# Resolve the target to a SID. Default to the current user.
if ([string]::IsNullOrEmpty($User)) {
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $label = [Security.Principal.WindowsIdentity]::GetCurrent().Name
} else {
    try {
        $sid = (New-Object Security.Principal.NTAccount($User)).Translate([Security.Principal.SecurityIdentifier])
        $label = $User
    } catch {
        Write-Error "Could not resolve user '$User' to a SID: $($_.Exception.Message)"
        exit 1
    }
}

$existing = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
if ($existing | Where-Object { $_.SID.Value -eq $sid.Value }) {
    Write-Output "$label is already a member of Administrators."
} else {
    Add-LocalGroupMember -Group "Administrators" -Member $sid
    Write-Output "Added $label to Administrators."
}

Write-Output "`nCurrent Administrators members:"
Get-LocalGroupMember -Group "Administrators" | Select-Object Name, ObjectClass
