. "$PSScriptRoot\require-elevated.ps1"
Start-ElevatedSelfIfNeeded -ScriptPath $PSCommandPath

$rules = @(
  @{ Name = 'DevSetup-Allow-ICMPv4-Echo-In'; DisplayName = 'Allow ICMPv4 Echo Request Inbound'; Protocol = 'ICMPv4'; IcmpType = 8 }
  @{ Name = 'DevSetup-Allow-ICMPv6-Echo-In'; DisplayName = 'Allow ICMPv6 Echo Request Inbound'; Protocol = 'ICMPv6'; IcmpType = 128 }
)

foreach ($definition in $rules) {
  $rule = Get-NetFirewallRule -Name $definition.Name -ErrorAction SilentlyContinue
  if (-not $rule) {
    New-NetFirewallRule -Name $definition.Name `
      -DisplayName $definition.DisplayName -Enabled True -Profile Private `
      -Direction Inbound -Action Allow -Protocol $definition.Protocol `
      -IcmpType $definition.IcmpType | Out-Null
  } else {
    Set-NetFirewallRule -Name $definition.Name -Enabled True -Profile Private `
      -Direction Inbound -Action Allow | Out-Null
  }
}
