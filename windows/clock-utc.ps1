Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name RealTimeIsUniversal -Value 1 -Type DWord

Get-ItemProperty -Path "Registry::HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" | Select-Object RealTimeIsUniversal
