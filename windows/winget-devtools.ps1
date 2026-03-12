# List of packages to install
$packages = @(
    # nvm-windows: Node Version Manager, for `npm i -g @openai/codex`
    "CoreyButler.NVMforWindows",
    "Anthropic.ClaudeCode"
)

$storeApps = @(
    "Codex"
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    winget install --id=$pkg --silent --accept-package-agreements --accept-source-agreements
}

foreach ($i in $storeApps) {
    Write-Host "Installing $pkg from msstore..."
    winget install $i --silent --accept-package-agreements --accept-source-agreements --source msstore
}
