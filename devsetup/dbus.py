import sys
import os
import subprocess
import pwd

def priv_set_fn_get(uid, gid):
    def priv_set():
        os.setgid(gid)
        os.setuid(uid)
    return priv_set

def dbus_user_session_run(uid, args):
    if uid == os.geteuid():
        # NOTE: assume DBus would be autostarted
        subprocess.ccheck_call(args)
    else:
        gid = pwd.getpwuid(uid).pw_gid
        subprocess.check_call(['dbus-launch'] + args, env={}, preexec_fn=priv_set_fn_get(uid, gid))
