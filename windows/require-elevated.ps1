function Test-IsAdministrator {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-PowerShellSingleQuotedLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return "'" + ($Value -replace "'", "''") + "'"
}

function Start-ElevatedSelfIfNeeded {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [string[]]$ArgumentList = @()
    )

    if (Test-IsAdministrator) {
        return
    }

    $powerShellExe = (Get-Process -Id $PID).Path
    $scriptPathLiteral = ConvertTo-PowerShellSingleQuotedLiteral $ScriptPath
    $scriptArgumentLiterals = $ArgumentList |
        ForEach-Object { "    $(ConvertTo-PowerShellSingleQuotedLiteral $_)" }

    $encodedScript = @"
`$ErrorActionPreference = 'Stop'
`$scriptPath = $scriptPathLiteral
`$scriptArgs = @(
$($scriptArgumentLiterals -join "`r`n")
)
& `$scriptPath @scriptArgs
if (`$global:LASTEXITCODE -is [int]) {
    exit `$global:LASTEXITCODE
}
exit 0
"@

    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($encodedScript))
    $processArguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-EncodedCommand", $encodedCommand
    )

    Write-Host "Requesting elevated privileges for $ScriptPath..."

    $process = Start-Process `
        -FilePath $powerShellExe `
        -ArgumentList $processArguments `
        -Verb RunAs `
        -Wait `
        -PassThru

    exit $process.ExitCode
}
