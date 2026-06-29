# Append a public key to C:\ProgramData\ssh\administrators_authorized_keys with the
# privileges and ACLs OpenSSH requires: UTF-8 without BOM, and access restricted to
# Administrators and SYSTEM only (sshd ignores the file otherwise).
#
# Usage: .\authorized-keys-add.ps1 "ssh-ed25519 AAAA... user@host"

param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$PublicKey
)

$ErrorActionPreference = 'Stop'

$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
$isAdministrator = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdministrator) {
	throw "Run this script from an elevated PowerShell session."
}

$key = $PublicKey.Trim()
if (-not $key) {
	throw "Public key is empty."
}

$path = 'C:\ProgramData\ssh\administrators_authorized_keys'

# Read existing lines (if any), skip blanks so we can dedupe reliably.
$lines = @()
if (Test-Path $path) {
	$lines = @(Get-Content -Path $path | Where-Object { $_.Trim() -ne '' })
}

if ($lines -contains $key) {
	Write-Output "Key already present in $path; nothing to do."
} else {
	Write-Output "Appending key to $path..."
	$lines += $key
	# WriteAllLines with UTF8Encoding($false) guarantees no BOM (Add-Content / >> in
	# Windows PowerShell 5.1 write a BOM that sshd silently rejects).
	[System.IO.File]::WriteAllLines($path, $lines, (New-Object System.Text.UTF8Encoding $false))
}

# Lock down ACLs: only Administrators and SYSTEM, no inheritance.
Write-Output "Setting ACLs on $path (Administrators + SYSTEM only)..."
$acl = New-Object System.Security.AccessControl.FileSecurity
$acl.SetAccessRuleProtection($true, $false)  # disable inheritance, drop inherited rules

$admins = New-Object System.Security.Principal.SecurityIdentifier(
	[System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid, $null)
$system = New-Object System.Security.Principal.SecurityIdentifier(
	[System.Security.Principal.WellKnownSidType]::LocalSystemSid, $null)

foreach ($sid in @($admins, $system)) {
	$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
		$sid, 'FullControl', 'Allow')
	$acl.AddAccessRule($rule)
}
$acl.SetOwner($admins)

Set-Acl -Path $path -AclObject $acl

Write-Output "Done."
icacls $path
