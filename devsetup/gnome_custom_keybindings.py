import sys
import json
import pwd
import subprocess
import argparse
import itertools

from .dbus import priv_set_fn_get
from .gsettings import (gsettings_get, gsettings_set)

def gnome_custom_keybindings_apply_current_user(json_config_str):
    bindings = json.loads(json_config_str)
    bindings_name_to_data = { x['name']: (x['binding'], x['command']) for x in bindings }

    for i in itertools.count():
        path = ('org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom%d/' % (i,))
        name = gsettings_get(path, 'name')
        d = bindings_name_to_data.get(name)
        if d is not None:
            gsettings_set(path, 'binding', d[0])
            gsettings_set(path, 'command', d[1])
            del bindings_name_to_data[name]
        elif name == '':
            break

    for (name, d) in bindings_name_to_data.items():
        path = ('org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom%d/' % (i,))
        gsettings_set(path, 'name', name)
        gsettings_set(path, 'binding', d[0])
        gsettings_set(path, 'command', d[1])
        i += 1

    t = [ '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom%d/' % (x,) for x in range(i) ]
    gsettings_set('org.gnome.settings-daemon.plugins.media-keys', 'custom-keybindings', t)

def gnome_custom_keybindings_apply(filename, uids):
    for uid in uids:
        p = pwd.getpwuid(uid)
        (uid, gid) = (p.pw_uid, p.pw_gid)
        try:
            subprocess.check_call(['dbus-launch', sys.executable, '-m', 'devsetup.gnome_custom_keybindings', '-'],
                    env={},
                    preexec_fn=priv_set_fn_get(uid, gid),
                    stdin=open(filename))
        except subprocess.SubprocessError as e:
            # FIXME:
            import pprint; pprint.pprint(dir(e))

def main():
    parser = argparse.ArgumentParser(description='apply custom keybindings config (JSON)')
    parser.add_argument('filenames', nargs=1)
    args = parser.parse_args()

    if args.filenames == ['-']:
        # read patch from STDIN
        gnome_custom_keybindings_apply_current_user(sys.stdin.read())
        return

    with open(args.filenames[0]) as f:
        t = f.read()
    gnome_custom_keybindings_apply_current_user(t)

if __name__ == '__main__':
    main()
