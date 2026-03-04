$bootstrapper = "C:\Temp\vs_Community.exe"
$layoutPath   = "D:\VSLayout"
$logPath      = "D:\VSLayout\vs-install.log"

$uri  = "https://aka.ms/vs/17/release/vs_community.exe"

Invoke-WebRequest -Uri $uri -OutFile $bootstrapper
Unblock-File $bootstrapper

# Create layout containing only the workloads you care about
Start-Process $bootstrapper -Wait -NoNewWindow -ArgumentList @(
  "--layout", "`"$layoutPath`"",
  "--lang", "en-US",
  # C++ desktop workload
  "--add", "Microsoft.VisualStudio.Workload.NativeDesktop",
  "--add", "Microsoft.VisualStudio.Workload.NativeCrossPlat",
  # CMake tools for Windows (CMake integration/tools)
  "--add", "Microsoft.VisualStudio.Component.VC.CMake.Project",
    # LLVM/Clang compiler + clang-cl toolset integration
  "--add", "Microsoft.VisualStudio.Component.VC.Llvm.Clang",
  "--add", "Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset",
  "--includeRecommended",
  "--log", "`"$logPath`""
)

# Install from layout
Start-Process "$layoutPath\vs_Community.exe" -Wait -NoNewWindow -ArgumentList @(
  "--noweb", "--quiet", "--wait", "--norestart",
  "--installPath", "`"C:\Program Files\Microsoft Visual Studio\2022\Community`"",
  "--add", "Microsoft.VisualStudio.Workload.NativeDesktop",
  "--add", "Microsoft.VisualStudio.Workload.NativeCrossPlat",
  "--includeRecommended",
  "--lang", "en-US"
)