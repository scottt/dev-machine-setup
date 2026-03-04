# List of packages to install
$packages = @(
    # nvm-windows: Node Version Manager
    "CoreyButler.NVMforWindows"
)

# Loop through each package and install
foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    winget install --id=$pkg --silent --accept-package-agreements --accept-source-agreements
}
