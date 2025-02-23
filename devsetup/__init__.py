__all__ = ['package_list_translate', 'package_list_file_load',
           'package_install', 'package_is_installed', 'fedora_version_get', 'repo_rpm_urls_load',
           'gsettings_patch_apply', 'dbus_user_session_run', 'gnome_custom_keybindings_apply'
]

import sys
import os
import subprocess
import pwd
import shutil
import tempfile

import yaml
try:
    from yaml import CLoader as YamlLoader
except ImportError:
    from yaml import Loader as YamlLoader

from .gsettings import gsettings_patch_apply
from .dbus import dbus_user_session_run
from .gnome_custom_keybindings import gnome_custom_keybindings_apply

machine_to_archs_in_repo = {
        'x86_64': ['x86_64', 'i686'],
}

def package_list_translate(pkgs, target_arch):
    # handle __ARCHS_IN_REPO_FOR_CPU__
    out = []
    archs = machine_to_archs_in_repo.get(target_arch, [target_arch])
    for i in pkgs:
        if i.endswith('.__ARCHS_IN_REPO_FOR_CPU__'):
            pkg = i[:-len('.__ARCHS_IN_REPO_FOR_CPU__')]
            for a in archs:
                out.append('%s.%s' % (pkg, a))
        else:
            out.append(i)
    pkgs = out
    return pkgs

def lines_strip_comments(lines):
    # strip comments till end of line
    out = []
    for l in lines:
        in_quote = 0
        for (i, c) in enumerate(l):
            if in_quote:
                if c == "'":
                    in_quote = 0
            else:
                if c == "'":
                    in_quote = 1
                elif c == '#':
                    if i != 0:
                        out.append(l[:i] + '\n')
                    break
        else:
            out.append(l)
    return out

def package_list_file_load(filename, target_arch):
    '''target_arch: uname().machine

    Input Format:
/usr/bin/vimx                        # vim with X11 clipboard support
nss-mdns.__ARCHS_IN_REPO_FOR_CPU__  # MDNS .local domain resolution
htop iotop nethogs'''

    with open(filename) as f:
        lines = f.readlines()

    pkgs = []
    # support multiple package names on same line
    # while assuming no space in package names
    for i in lines_strip_comments(lines):
        for j in i.split():
            pkgs.append(j)
    return package_list_translate(pkgs, target_arch)

def package_list_file_install(filename, target_arch):
    pkgs = package_list_file_load(filename, target_arch)
    pkg_ops = PackageOps()
    pkg_ops.package_install(pkgs)

def PackageOps():
    if sys.platform.startswith('linux'): # TODO: error out on non-DNF distros
        return FedoraPackageOps
    elif sys.platform.startswith('darwin'):
        return MacPackageOps
    else:
        raise RuntimeError(f'Unsupported OS: "{sys.platform}"')

class MacPackageOps:
    @staticmethod
    def package_install(pkgs):
        # https://github.com/Homebrew/brew/issues/2491
        with tempfile.NamedTemporaryFile() as tf:
            tf.write(('\n'.join([ 'brew "%s"' % (x,) for x in pkgs ])).encode('utf-8'))
            tf.seek(0)
            subprocess.check_call(['brew', 'bundle', '--file=%s' % (tf.name,)])

    @staticmethod
    def pacakge_is_installed(pkg):
        r = subprocess.call(['brew', 'list', pkg], stdout=subprocess.DEVNULL)
        return (r == 0)

class FedoraPackageOps:
    @staticmethod
    def package_install(pkgs):
        subprocess.check_call(['dnf', 'install', '-y', '--skip-unavailable'] + pkgs)

    @staticmethod
    def package_is_installed(pkg):
        r = subprocess.call(['rpm', '-q', pkg], stdout=subprocess.DEVNULL)
        return (r == 0)

def brew_bundle_install(filename):
    # https://github.com/Homebrew/homebrew-bundle#usage
    subprocess.check_call(['brew', 'bundle', '--file', filename])

def rpm_urls_file_install(filename):
    with open(filename) as f:
        lines = f.readlines()
    urls = [ x[:-1] for x in lines_strip_comments(lines) ]
    subprocess.check_call(['dnf', 'install', '-y'] + urls)

def fedora_version_get():
    '-> "28"'
    fedora_version = subprocess.Popen(['rpm', '-E', '%fedora'], stdout=subprocess.PIPE).stdout.read().strip().decode('ascii')
    return fedora_version

def repo_rpm_urls_load(filename, target_arch):
    '''Input Format:
https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-{fedora_version!s}.noarch.rpm
'''
    d = dict(fedora_version=fedora_version_get(),
             target_arch=target_arch)

    with open(filename) as f:
        lines = f.readlines()
    out = []
    for l in lines:
        out.append(l.format_map(d))
    return out

DEFAULT_UID = 1000

def default_target_user():
    uid = os.getuid()
    if uid == 0:
        try:
            uid = int(os.environ['SUDO_UID'])
        except (ValueError, KeyError):
            uid = DEFAULT_UID
    return pwd.getpwuid(uid).pw_name

DNF_REPO_DIR = '/etc/yum.repos.d'

def repo_and_packages_install(repo_and_packages, target_arch):
    repo_file = repo_and_packages.get('repo-file')
    if repo_file is not None:
        shutil.copy2(repo_file, DNF_REPO_DIR)

    packages = repo_and_packages.get('packages')
    pkg_ops = PackageOps()
    if packages is not None:
        pkg_ops.package_install(package_list_translate(packages, target_arch))

def repo_and_packages_file_install(filename, target_arch):
    with open(filename) as f:
        repo_and_packages = yaml.load(f, YamlLoader)

    repo_and_packages_install(repo_and_packages, target_arch)

def sysctl_file_install(filename):
    # Don't use shutil.copy2. It copies the wrong SELinux file label
    # user_home_t vs. etc_t
    shutil.copy(filename, '/etc/sysctl.d')
    subprocess.check_call(['systemctl', 'restart', 'systemd-sysctl.service'])
