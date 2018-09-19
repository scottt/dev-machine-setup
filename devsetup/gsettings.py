import sys
import os
import pwd
import argparse

import ast
import subprocess
import json

from .dbus import priv_set_fn_get

DEBUG = 2

def gvariant_loads(s):
    # The real format of value_str is GVariant Text Format
    # https://developer.gnome.org/glib/stable/gvariant-text.html
    # 
    # The Variants, Maybe types(just, nothing), Boolean(true, false) are
    # all problamtic for Python's ast.literal_eval.

    # Skip type annotations e.g. `@as []' -> []
    if s.startswith('@'):
        s0 = s.find(' ')
        s = s[s0+1:]

    # Handle a single true, false, nothing
    if s == 'true':
        s = 'True'
    elif s == 'false':
        s = 'False'
    elif s == 'nothing':
        s = 'None'

    if DEBUG > 1:
        sys.stderr.write('gvariant_loads: literal_eval(%r)\n' % (s,))
    try:
        v = ast.literal_eval(s)
    except ValueError:
        sys.stderr.write('gvariant_loads: literal_eval(%r)\n' % (s,))
        raise
    return v

def gsettings_line_parse(line):
    '''

    >>> gsettings_line_parse('org.gnome.shell.overrides workspaces-only-on-primary true')
    ('org.gnome.shell.overrides', 'workspaces-only-on-primary', True)
    '''
    s0 = line.find(' ')
    s1 = line.find(' ', s0+1)

    value_str = line[s1+1:].strip()
    value = gvariant_loads(value_str)
    return (line[:s0], line[s0+1:s1].strip(), value)

def is_scaler(value):
    # str's are collection.Sequence's
    # GVariant doesn't have sets
    return (not isinstance(value, list)) and (not isinstance(value, tuple)) and (not isinstance(value, dict))

def gsettings_patch_parse(lines):
    '''-> [ ("set", "org.gnome.desktop.interface" "gtk-key-theme", "Emacs"), 
("append", "org.gnome.shell", "enabled-extensions", ["alternative-tab@...", ...]),
...'''

    in_hunk = 0
    (schema0, key0, value0) = (None, None, None)
    (schema, key, value)    = (None, None, None)
    out = []
    for (lineno, l) in enumerate(lines):
        # strip comments
        if l.startswith('#'):
            continue
        elif l.startswith('+'):
            in_hunk = 0
            (schema, key, value) = gsettings_line_parse(l[1:])
            if (schema != schema0) or (key != key0):
                raise ValueError(filename, lineno, 'Expected %r %r, got %r %r' % (schema0, key0, schema, key))
            if is_scaler(value):
                out.append(('set', schema, key, value))
            else:
                (set0, set1) = (set(value0), set(value))
                if (set0 == set1):
                    if value0 == value:
                        continue
                    # reorder
                    out.append(('set', schema, key, value))
                elif set0.issuperset(set1): # removed items
                    out.append(('remove', schema, key, (type(value))(set0 - set1)))
                elif set1.issuperset(set0): # append or (reorder + add)
                    # maintain order for 'value'
                    for (i, v) in enumerate(value0):
                        if value[i] != v:
                            break
                    else: # value0 is prefix of value, append
                        out.append(('append', schema, key, value[i:]))
                        continue
                    # reorder + add, set
                    out.append(('set', schema, key, value))
                else: # remove + add
                    out.append(('remove', schema, key, (type(value))(set0 - set1)))
                    out.append(('append', schema, key, (type(value))(set1 - set0)))
        elif l.startswith('-'):
            in_hunk = 1
            (schema0, key0, value0) = gsettings_line_parse(l[1:])
        # skip empty lines
        elif l.strip() == '':
            pass
        else:
            raise ValueError(filename, lineno, "Line not starting with '#', '-', or '+'")
    return out

def gvariant_serialize(value):
    if isinstance(value, tuple):
        out = [ gvariant_serialize(x) for x in value ]
        return '(' + ','.join(out) + ')'
    elif isinstance(value, list):
        out = [ gvariant_serialize(x) for x in value ]
        return '[' + ','.join(out) + ']'
    else:
        return json.dumps(value)

def gsettings_set(schema, key, value):
    subprocess.check_call(['gsettings', 'set', schema, key, gvariant_serialize(value)])

def gsettings_get(schema, key):
    p = subprocess.Popen(['gsettings', 'get', schema, key], stdout=subprocess.PIPE)
    out = []
    while 1:
        r = p.stdout.read()
        if r == b'':
            break
        else:
            out.append(r)
    p.wait()
    value_str = (b''.join(out)).decode('ascii')
    return gvariant_loads(value_str)

def gsettings_append(schema, key, value):
    v0 = gsettings_get(schema, key)
    set0 = set(v0)
    # maintain order for 'value'
    vdelta = []
    for v in value:
        if v in set0:
            continue
        vdelta.append(v)
    subprocess.check_call(['gsettings', 'set', schema, key, gvariant_serialize(v0 + vdelta)])

def gsettings_remove(schema, key, value):
    set1 = set(value)
    v0 = gsettings_get(schema, key)
    out = [ v for v in v0 if v not in set1 ]
    gsettings_set(schema, key, (type(value))(out))

# DBUS_SESSION_BUS_ADDRESS is set for console root logins as well
# sudo -u vagrant HOME=/home/vagrant dbus-launch --exit-with-session gsettings set org.freedesktop.ibus.general use-system-keyboard-layout true
# https://superuser.com/questions/726550/use-dconf-or-comparable-to-set-configs-for-another-user

def gsettings_patch_apply_current_user(lines):
    # FIXME: apply to 'username'
    for (action, schema, key, value) in gsettings_patch_parse(lines):
        if action == 'set':
            gsettings_set(schema, key, value)
        elif action == 'append':
            gsettings_append(schema, key, value)
        elif action == 'remove':
            gsettings_remove(schema, key, value)
        else:
            assert(0)

def gsettings_patch_apply(filename, users):
    for user in users:
        p = pwd.getpwnam(user)
        (uid, gid) = (p.pw_uid, p.pw_gid)
        # Apply gsettings in new process with specified UID, GID
        subprocess.check_call(['dbus-launch', sys.executable, '-m', 'devsetup.gsettings', '-'],
                env={},
                preexec_fn=priv_set_fn_get(uid, gid),
                stdin=open(filename))

def main():
    parser = argparse.ArgumentParser(description='apply gsettings patch')
    parser.add_argument('patches', metavar='GSETTINGS-PATCH', nargs='+')
    args = parser.parse_args()

    if len(args.patches) == 1 and args.patches[0] == '-':
        # read patch from STDIN
        gsettings_patch_apply_current_user(sys.stdin.readlines())
        return

    for i in args.patches:
        with open(i) as f:
            lines = f.readlines()
        gsettings_patch_apply_current_user(lines)

if __name__ == '__main__':
    main()
