# Create this file and edit it:
# $ New-Item $profile -Type File -Force
# $ code $profile
# https://superuser.com/questions/1090141/does-powershell-have-any-sort-of-bashrc-equivalent

# PSReadLine
Set-PSReadlineOption -BellStyle None
# PSReadLine vi mode
# https://prstat.blogspot.com/2021/07/vi-mode-in-powershell.html
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineKeyHandler -Chord Tab -Function Complete
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Chord Ctrl-r -Function ReverseSearchHistory -ViMode Insert
Set-PSReadLineKeyHandler -Chord Ctrl-r -Function ReverseSearchHistory -ViMode Command
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ViMode Insert
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ViMode Command
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ViMode Insert
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ViMode Command

# posh-git for git command completion https://github.com/dahlbyk/posh-git
# PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
Import-Module posh-git

# https://github.com/kelleyma49/PSFzf?tab=readme-ov-file#psreadline-integration
# PowerShellGet\Install-Module PSFzf -Scope CurrentUser -Force
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# $HOME/bin
$env:PATH += ";$HOME\bin"

# pkg-config-lite
# Strawberry Perl comes with pkg-config.bat
# $env:PATH += ";D:\pkg-config-lite-0.28-1\bin"

# cwRsync
$env:PATH += ";$HOME\cwrsync_6.4.2_x64_free\bin"

# imhex: installed by winget but not added to PATH
$env:PATH += ";C:\Program Files\ImHex"

# TheRock
#$env:PATH += ";D:\therock-output-gfx1151\build\dist\rocm\bin"
#$env:HIP_CLANG_PATH = "D:\therock-output-gfx1151\build\dist\rocm\lib\llvm\bin"
#$env:PATH += ";D:\therock-jammm-output-gfx1151\build\dist\rocm\bin"
#$env:HIP_CLANG_PATH = "D:\therock-jammm-output-gfx1151\build\dist\rocm\lib\llvm\bin"
#$env:PATH += ";D:\o\r-st-gfx1151\build\dist\rocm\bin"
#$env:HIP_CLANG_PATH = "D:\o\r-st-gfx1151\build\dist\rocm\lib\llvm\bin"
#$env:PATH += ";D:\o\r-st-gfx1151\build\dist\rocm\bin"
#$env:HIP_CLANG_PATH = "D:/o/r-st-gfx1151/build/dist/rocm/lib/llvm/bin"

# CMake 3.30 and Ninja 1.12.1 from VisualStudio 2022 instead of Strawberry Perl
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;$env:PATH"
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;$env:PATH"

# Use `vim.exe` from Git-for-Widnows
function vim { & "C:\Program Files\Git\usr\bin\vim.exe" $args }
