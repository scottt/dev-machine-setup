# SSH config

`apply-ssh-config` ensures the user's SSH config contains a global:

```sshconfig
AddKeysToAgent yes
```

With `AddKeysToAgent yes`, OpenSSH asks `ssh-agent` to remember private keys
after they are used. Later SSH commands can then reuse the agent instead of
prompting again for the same key.

This is more useful on macOS than on a GNOME desktop. macOS commonly relies on
the login-session SSH agent behavior, while GNOME environments often already
handle SSH keys through `gnome-keyring` or another desktop-managed agent.

Run:

```sh
./apply-ssh-config
```
