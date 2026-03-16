param(
    [string]$ShareName = "CDrive",
    [string[]]$FullAccess
)

$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
$isAdministrator = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdministrator) {
    throw "Run this script from an elevated PowerShell session."
}

if (-not $FullAccess -or $FullAccess.Count -eq 0) {
    $FullAccess = @($currentIdentity.Name)
}

$existingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue

if ($existingShare -and $existingShare.Path -ne "C:\") {
    throw "Share '$ShareName' already exists and points to '$($existingShare.Path)'."
}

Write-Host "Enabling File and Printer Sharing firewall rules..."
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing" | Out-Null

if (-not $existingShare) {
    Write-Host "Creating SMB share '$ShareName' for C:\..."
    New-SmbShare -Name $ShareName -Path "C:\" -FullAccess $FullAccess | Out-Null
}

foreach ($account in $FullAccess) {
    Write-Host "Granting full access to $account..."
    Grant-SmbShareAccess -Name $ShareName -AccountName $account -AccessRight Full -Force | Out-Null
}

Write-Host "Share '$ShareName' is ready."
Write-Host "UNC path: \\$env:COMPUTERNAME\$ShareName"
