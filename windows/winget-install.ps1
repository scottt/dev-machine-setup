# List of packages to install
$packages = @(
    "Git.Git",
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Mozilla.Firefox",
    "Discord.Discord",
    "Google.Chrome",
    "OpenVPNTechnologies.OpenVPN",
    "LocalSend.LocalSend",
    "KDE.KDEConnect"
)

# Loop through each package and install
foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    winget install --id=$pkg --silent --accept-package-agreements --accept-source-agreements
}
