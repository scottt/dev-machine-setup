# Set 24-hour time format for short and long time
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sShortTime" -Value "HH:mm"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name "sTimeFormat" -Value "HH:mm:ss"

# Notify the system of the change
$signature = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
Add-Type $signature
[Win32]::SendMessageTimeout([IntPtr]::Zero, 0x1A, [UIntPtr]::Zero, "International", 0, 1000, [ref]([UIntPtr]::Zero))