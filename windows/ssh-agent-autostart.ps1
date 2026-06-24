Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent

# Load your keys
# ssh-add $env:USERPROFILE\.ssh\id_ed25519