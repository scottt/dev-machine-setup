$wingetFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.winget" | ForEach-Object { $_.FullName }
& "$PSScriptRoot\winget-install.ps1" @wingetFiles
