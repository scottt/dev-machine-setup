# See dev.winget, agents.winget

param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$PackageFiles
)

# Read package names from each file, ignoring blank lines and comments
# (lines starting with '#').
$packages = Get-Content -Path $PackageFiles |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -and -not $_.StartsWith("#") }

# Loop through each package and install
foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    winget install --id=$pkg --source winget --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
}
