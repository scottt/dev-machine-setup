$components = @(
  # C++ desktop workload
  "Microsoft.VisualStudio.Workload.NativeDesktop",
  "Microsoft.VisualStudio.Workload.NativeCrossPlat",
  # CMake tools for Windows (CMake integration/tools)
  "Microsoft.VisualStudio.Component.VC.CMake.Project",
  # LLVM/Clang compiler + clang-cl toolset integration
  "Microsoft.VisualStudio.Component.VC.Llvm.Clang",
  "Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset",
  # Windows SDK
  "Microsoft.VisualStudio.Component.Windows11SDK.22621",
  # Active Template Library, required by llvm/debuginfo/DebugInfo/PDB/DIA
  "Microsoft.VisualStudio.Component.VC.14.44.17.14.ATL"
)

$layoutPath   = "C:\VSLayout"
$bootstrapper = $layoutPath +"\vs_Community.exe"
$logPath      = $layoutPath + "\vs-install.log"

$bootstrapperUri  = "https://aka.ms/vs/17/release/vs_community.exe"

if (-not (Test-Path -LiteralPath $bootstrapper)) {
  Invoke-WebRequest -Uri $bootstrapperUri -OutFile $bootstrapper
}
Unblock-File $bootstrapper

# Create layout containing only the workloads you care about
$components = $components | ForEach-Object { "-add $_" }
Start-Process $bootstrapper -Wait -NoNewWindow -ArgumentList (@(
  "--layout", "`"$layoutPath`"",
  "--lang", "en-US",
  "--includeRecommended",
  "--log", "`"$logPath`""
) + $components)
