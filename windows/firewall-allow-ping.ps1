# ICMPv4 ping
New-NetFirewallRule `
  -DisplayName "Allow ICMPv4 Echo Request Inbound" `
  -Direction Inbound `
  -Action Allow `
  -Protocol ICMPv4 `
  -IcmpType 8

# ICMPv6 ping
New-NetFirewallRule `
  -DisplayName "Allow ICMPv6 Echo Request Inbound" `
  -Direction Inbound `
  -Action Allow `
  -Protocol ICMPv6 `
  -IcmpType 128
