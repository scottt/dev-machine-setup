#!/usr/bin/env python3

# RPMFusion
# https://forums.fedoraforum.org/showthread.php?317721-fedora-28-and-firefox-video(h264-youtube-gstreamer1)

import sys
import os
import subprocess

RPMFUSION_URL_PREFIX = 'https://download1.rpmfusion.org'

# e.g. fedora_version == '28'
fedora_version = subprocess.Popen(['rpm', '-E', '%fedora'], stdout=subprocess.PIPE).stdout.read().strip().decode('ascii')

REPO_PACKAGES = [
        RPMFUSION_URL_PREFIX + '/free/fedora/rpmfusion-free-release-%s.noarch.rpm' % (fedora_version,),
        RPMFUSION_URL_PREFIX + '/nonfree/fedora/rpmfusion-nonfree-release-%s.noarch.rpm' % (fedora_version,),
]

PACKAGES = [
    'gstreamer1-libav', 'gstreamer1-plugins-ugly', 'unrar', 'compat-ffmpeg28', 'ffmpeg-libs',
    'smplayer', 'mpv',
    'libva-intel-driver.x86_64', 'libva-intel-driver.i686',
]

def package_is_installed(pkg):
    r = subprocess.call(['rpm', '-q', pkg], stdout=subprocess.DEVNULL)
    return (r == 0)

def rpmfusion_repo_setup():
    for i in REPO_PACKAGES:
        pkg = os.path.basename(i)
        # 'X.noarch.rpm' -> 'X'
        pkg = pkg[:pkg.find('.')]
        if not package_is_installed(pkg):
            subprocess.check_call(['dnf', 'install', '-y'] + REPO_PACKAGES)
            break

def main():
    rpmfusion_repo_setup()
    subprocess.check_call(['dnf', 'install', '-y'] + PACKAGES)

if __name__ == '__main__':
    main()
