# Install the winget packages listed in agents.winget
& "$PSScriptRoot\winget-install.ps1" "$PSScriptRoot\agents.winget"

$storeApps = @(
    "Codex"
)

foreach ($i in $storeApps) {
    Write-Host "Installing $i from msstore..."
    winget install $i --silent --accept-package-agreements --accept-source-agreements --source msstore
}
