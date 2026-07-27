$layoutPath   = "C:\VSLayout"
#$logPath      = $layoutPath + "\vs-install.log"

$setupPath = Join-Path $layoutPath 'vs_setup.exe'
if (-not (Test-Path -LiteralPath $setupPath -PathType Leaf)) {
  throw "Visual Studio layout is missing '$setupPath'. Run visual-studio-download-layout.ps1 first."
}

# Install from layout
Start-Process $setupPath -Wait -NoNewWindow -ArgumentList (@(
  "--noweb", "--wait",
  "--installPath", "`"C:\Program Files\Microsoft Visual Studio\2022\Community`""
))

# , "--norestart", requires eitehr "--quiet" or "--passive"
  #"--noweb", "--quiet", "--wait", "--norestart",
