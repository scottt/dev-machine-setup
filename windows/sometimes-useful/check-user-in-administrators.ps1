# Check whether the current user is in the local Administrators group.
# Matches by SID rather than by name, so it works for local, domain, Entra
# (Azure AD), and Microsoft accounts regardless of the USERDOMAIN prefix.
# Checks group membership directly (not the elevation state of this process),
# so it reports True even when running from a non-elevated shell.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$mySid = $identity.User.Value

try {
    $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
} catch {
    # Don't collapse a failed query into "not a member": surface it instead.
    Write-Error "Could not read Administrators membership: $($_.Exception.Message)"
    exit 2
}

$isMember = [bool]($members | Where-Object { $_.SID.Value -eq $mySid })

if ($isMember) {
    Write-Output "$($identity.Name) IS a member of Administrators."
} else {
    Write-Output "$($identity.Name) is NOT a member of Administrators."
}

exit ([int](-not $isMember))
