# Mac Window Management

See `wm.brewfile`.
Requires: skhd (global hotkeys), yabai (tiling window manager), karabiner-elements (hot key remapper)

New Mac Hardware & OS Support: https://github.com/koekeishiya/yabai/issues/1035

## Installation
* [yabai: Installation Guide](https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)): `brew install koekeishiya/formulae/yabai`
* skhd: brew install koekeishiya/formulae/skhd

https://github.com/koekeishiya/skhd
https://github.com/koekeishiya/yabai/wiki/Configuration#configuration-file

## Configuration

### AltTab
* Mac Menu Bar -> AltTab Icon -> Preferences... -> Controls Tab -> Shortcut 1 -> "Hold `Command` key"

### Yabai and Skhd
* See `config/...`
* Install into `$HOME/.config/{yabai,skhd}/{yabai,skhd}rc`

## Workspace Movement with Hotkey

macOS does not natively let you assign arbitrary keys like Cmd + Shift + H directly to a Space switch, but remapping to the built-in Ctrl + 2 shortcut works.

Karabiner-elements is used to map `Cmd + Shift + h` to `Ctrl + 1` etc.
This repo also installs a LaunchAgent so `Karabiner-Elements` opens automatically at login.
