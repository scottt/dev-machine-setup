#!/usr/bin/env python3

import sys
import argparse
import subprocess
import grp
import pwd

import devsetup

def groups_get_all():
    '-> list of str, all local groups'
    return [ g.gr_name for g in grp.getgrall() ]

def groups_containing_user(username):
    '-> list of str'
    # NOTE: only works for local users, not LDAP, AD etc
    groups = [ g.gr_name for g in grp.getgrall() if username in g.gr_mem]
    primary_gid = pwd.getpwnam(username).pw_gid
    groups.append(grp.getgrgid(primary_gid).gr_name)
    return groups

def username_from_uid(uid):
    return pwd.getpwuid(uid).pw_name

def docker_nonroot_setup(username):
    # https://developer.fedoraproject.org/tools/docker/docker-installation.html
    devsetup.package_install(['docker'])
    subprocess.check_call(['systemctl', 'enable', 'docker'])
    subprocess.check_call(['systemctl', 'start', 'docker'])

    subprocess.check_call(['systemctl', 'start', 'docker'])

    groups = groups_containing_user(username)
    if 'docker' not in groups:
        if not 'docker' in groups_get_all():
            subprocess.check_call(['groupadd', 'docker'])
        subprocess.check_call(['gpasswd', '-a', username, 'docker'])
        subprocess.check_call(['systemctl', 'restart', 'docker'])

def setup(uid=None, username=None):
    if uid is None:
        uid = 1000
    else:
        assert(isinstance(uid, int))
    if username is None:
        username = username_from_uid(uid)
    else:
        username = username
    docker_nonroot_setup(username)

def main():
    parser = argparse.ArgumentParser(description='setup docker for non-root user')
    parser.add_argument('--uid', type=int, default=None)
    parser.add_argument('--username', default=None)

    args = parser.parse_args()
    setup(uid=args.uid, username=args.username)

if __name__ == '__main__':
    main()
