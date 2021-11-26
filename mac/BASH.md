# Bash on macOS

```
echo $(which bash) >> /etc/shells
chsh -s $(which bash) $(whoami)
```

# Brew Packages and Setup

`dev.brew-bundle`:
```
brew 'bash'
brew 'bash-completion@2'
```

`mac.env`:
```
BREW_PREFIX="$(brew --prefix)"
export BASH_COMPLETION_COMPAT_DIR="$BREW_PREFIX/etc/bash_completion.d"
[[ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"
```
