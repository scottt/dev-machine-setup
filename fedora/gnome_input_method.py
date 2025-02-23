#!/usr/bin/env python3 
import os
import pwd
import logging
import subprocess

import devsetup

def install(target_arch):
    devsetup.package_list_file_install('input-method.packages', target_arch)

def setup(target_arch, username):
    install(target_arch)
    # Need to restart ibus for it to see new input methods:
    # $ ibus restart
    # $ ibus list-engine | grep -i chewing
    # chewing - Chewing
    uid = pwd.getpwnam(username).pw_uid
    try:
        devsetup.dbus_user_session_run(uid, ['ibus', 'restart'])
    except subprocess.CalledProcessError:
        logging.info('ibus restart failed')
    devsetup.gsettings_patch_apply('input-method.gsettings-patch', [username])

def main():
    username = devsetup.default_target_user()
    setup(os.uname().machine, username)

if __name__ == '__main__':
    main()
