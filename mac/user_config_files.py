import os
import shutil

def copy():
    h = os.path.expanduser('~')
    y = os.path.join(h, '.config', 'yabai')
    s = os.path.join(h, '.config', 'skhd')
    os.makedirs(y, exist_ok=True)
    os.makedirs(s, exist_ok=True)
    shutil.copy2(os.path.join('config', 'yabairc'), y)
    shutil.copy2(os.path.join('config', 'skhdrc'), y)

def main(args):
    copy()

if __name__ == '__main__':
    main(sys.argv[1:])
