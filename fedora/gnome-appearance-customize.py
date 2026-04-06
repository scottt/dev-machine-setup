import sys
import subprocess

def dconf_write(key, value):
    subprocess.run(['dconf', 'write', key, value])

def main():
    pass

if __name__ == '__main__':
    main(sys.argv[1:])
