$ErrorActionPreference = 'Stop'

PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
function Get-PoshGitVerification {
    Get-Module -ListAvailable posh-git |
        Sort-Object Version -Descending |
        Select-Object -First 1 Name, Version, Path
}

PowerShellGet\Install-Module PSFzf -Scope CurrentUser -Force
function Get-PSFzfVerification {
    Get-Module -ListAvailable PSFzf |
        Sort-Object Version -Descending |
        Select-Object -First 1 Name, Version, Path
}

$profileSource = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
$profileDestination = $PROFILE.CurrentUserCurrentHost
New-Item $profileDestination -ItemType File -Force | Out-Null
Copy-Item -LiteralPath $profileSource -Destination $profileDestination -Force
function Get-PowerShellProfileVerification {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    $file = Get-Item -LiteralPath $Destination
    [pscustomobject]@{
        FullName = $file.FullName
        Length = $file.Length
        LastWriteTime = $file.LastWriteTime
        ContentMatches = (Get-FileHash -LiteralPath $Destination).Hash -eq
            (Get-FileHash -LiteralPath $Source).Hash
    }
}

# wezterm
$weztermSource = Join-Path $PSScriptRoot 'wezterm.lua'
$weztermDirectory = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.config\wezterm'
$weztermDestination = Join-Path $weztermDirectory 'wezterm.lua'
New-Item -ItemType Directory -Force -Path $weztermDirectory | Out-Null
Copy-Item -LiteralPath $weztermSource -Destination $weztermDestination -Force
function Get-WezTermVerification {
    param(
        [Parameter(Mandatory)] [string] $Source,
        [Parameter(Mandatory)] [string] $Destination
    )

    $file = Get-Item -LiteralPath $Destination
    [pscustomobject]@{
        FullName = $file.FullName
        Length = $file.Length
        LastWriteTime = $file.LastWriteTime
        ContentMatches = (Get-FileHash -LiteralPath $Destination).Hash -eq
            (Get-FileHash -LiteralPath $Source).Hash
    }
}

$profileVerification = Get-PowerShellProfileVerification `
    -Source $profileSource -Destination $profileDestination
$weztermVerification = Get-WezTermVerification `
    -Source $weztermSource -Destination $weztermDestination

Write-Output '=== MODULES ==='
@(Get-PoshGitVerification; Get-PSFzfVerification) |
    Sort-Object Name |
    Format-Table Name, Version, Path -AutoSize

Write-Output '=== DEPLOYED FILES ==='
@($profileVerification; $weztermVerification) |
    Format-Table FullName, Length, LastWriteTime -AutoSize

Write-Output '=== CONTENT MATCH ==='
[pscustomobject]@{
    ProfileMatches = $profileVerification.ContentMatches
    WezTermMatches = $weztermVerification.ContentMatches
} | Format-List
