#!/usr/bin/env python3

import sys
import os
import subprocess

def add_to_etc_shells(shell_path):
    etc_shells = '/etc/shells'
    with open(etc_shells) as f:
        for i in f.readlines():
            if i.strip() == shell_path:
                return
    with open(etc_shells, mode='a') as f:
        f.write(shell_path.strip() + '\n')

def chsh_homebrew_bash():
    p = subprocess.run(['brew', '--prefix'], capture_output=1)
    bash_path = os.path.join(p.stdout.decode('utf-8').strip(), 'bin', 'bash')
    subprocess.run(['chsh', '-s', bash_path])

def main(args):
    chsh_homebrew_bash()

if __name__ == '__main__':
    main(sys.argv[1:])
