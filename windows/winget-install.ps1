# See dev.winget, agents.winget

param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$PackageFiles
)

. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath -ArgumentList $PackageFiles

function Read-WingetPackageOptions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $options = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $options
    }

    $currentPackage = $null
    $lineNumber = 0

    foreach ($line in Get-Content -LiteralPath $Path) {
        $lineNumber += 1
        $trimmed = $line.Trim()

        if (-not $trimmed -or $trimmed.StartsWith("#")) {
            continue
        }

        if ($trimmed -match '^\[packages\."([^"]+)"\]$') {
            $currentPackage = $Matches[1]
            if (-not $options.ContainsKey($currentPackage)) {
                $options[$currentPackage] = @()
            }
            continue
        }

        if ($trimmed -match '^args\s*=\s*\[(.*)\]$') {
            if (-not $currentPackage) {
                throw "$Path line ${lineNumber}: args must be inside a [packages.`"package-id`"] section."
            }

            $argsText = $Matches[1]
            if ($argsText -and $argsText -notmatch '^\s*"((?:[^"\\]|\\.)*)"\s*(,\s*"((?:[^"\\]|\\.)*)"\s*)*$') {
                throw "$Path line ${lineNumber}: args must be an array of quoted strings."
            }

            $matches = [regex]::Matches($argsText, '"((?:[^"\\]|\\.)*)"')
            $args = @()
            foreach ($match in $matches) {
                $args += $match.Groups[1].Value -replace '\\"', '"' -replace '\\\\', '\'
            }

            $options[$currentPackage] = $args
            continue
        }

        throw "$Path line ${lineNumber}: unsupported TOML syntax."
    }

    return $options
}

$packageOptions = Read-WingetPackageOptions -Path (Join-Path $PSScriptRoot "winget-options.toml")

# Read package names from each file, ignoring blank lines and comments
# (lines starting with '#').
$packages = Get-Content -Path $PackageFiles |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

# Loop through each package and install
foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."

    $wingetArgs = @(
        "install",
        "--id=$pkg",
        "--source", "winget",
        "--scope", "machine",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--disable-interactivity"
    )

    if ($packageOptions.ContainsKey($pkg)) {
        $wingetArgs += $packageOptions[$pkg]
    }

    winget @wingetArgs
    if ($LASTEXITCODE -eq -1978335189) {
        Write-Host "Package $pkg is already current."
        continue
    }
    if ($LASTEXITCODE -ne 0) {
        throw "winget install failed for $pkg with exit code $LASTEXITCODE."
    }
}
