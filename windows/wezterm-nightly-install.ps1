# Define the download URL and destination path
$installerUrl = "https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe"
$installerPath = "$env:TEMP\WezTerm-nightly-setup.exe"

# Download the installer
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Run the installer silently
Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

# Optionally remove the installer after installation
Remove-Item $installerPath