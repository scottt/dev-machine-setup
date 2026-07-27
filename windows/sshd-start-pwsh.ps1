. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$shellPath = 'C:\Program Files\PowerShell\7\pwsh.exe'
if (-not (Test-Path -LiteralPath $shellPath -PathType Leaf)) {
    throw "PowerShell 7 was not found at '$shellPath'."
}

New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
    -Value $shellPath -PropertyType String -Force | Out-Null

Restart-Service -Name sshd
