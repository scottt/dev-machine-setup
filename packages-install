#!/usr/bin/env python3

import sys
import subprocess

PACKAGES = [
    '/usr/bin/vimx',                     # vim with X11 clipboard support
    'nss-mdns.x86_64',  'nss-mdns.i686', # MDNS .local domain resolution
    'htop', 'iotop', 'nethogs',
    'kdiff3',
]

def main():
    subprocess.check_call(['dnf', 'install', '-y'] + PACKAGES)

if __name__ == '__main__':
    main()
