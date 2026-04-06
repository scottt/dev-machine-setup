Modify the @desktop-background-install Python script to:

* Copy `data/bg.png` to `$HOME/.local/share/backgrounds/`
* Set the path to `bg.png` in gsettings `org.gnome.desktop.background picture-uri` to 'file:///var/home/scottt/.local/share/backgrounds/bg.png',
  where `/var/home/scottt` is replaced with the `$HOME` value
* Set gsettings `org.gnome.desktop.background picture-options` to 'zoom'
