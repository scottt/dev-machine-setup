$layoutPath   = "C:\VSLayout"
$bootstrapper = $layoutPath +"\vs_Community.exe"
#$logPath      = $layoutPath + "\vs-install.log"

$bootstrapperUri  = "https://aka.ms/vs/17/release/vs_community.exe"

if (-not (Test-Path -LiteralPath $bootstrapper)) {
  Invoke-WebRequest -Uri $bootstrapperUri -OutFile $bootstrapper
}
Unblock-File $bootstrapper

# Install from layout
Start-Process "$layoutPath\vs_setup.exe" -Wait -NoNewWindow -ArgumentList (@(
  "--noweb", "--wait"
  "--installPath", "`"C:\Program Files\Microsoft Visual Studio\2022\Community`""
))

# , "--norestart", requires eitehr "--quiet" or "--passive"
  #"--noweb", "--quiet", "--wait", "--norestart",
