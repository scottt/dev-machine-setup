#!/usr/bin/env python3

# RPMFusion

import sys
import os
import subprocess

import devsetup

def rpmfusion_repo_setup(uname_machine):
    repo_rpm_urls = devsetup.repo_rpm_urls_load('rpmfusion.repo-rpm-urls', uname_machine)
    pkg_ops = devsetup.PackageOps()
    for i in repo_rpm_urls:
        pkg = os.path.basename(i)
        # 'X.noarch.rpm' -> 'X'
        pkg = pkg[:pkg.find('.')]
        if not pkg_ops.package_is_installed(pkg):
            pkg_ops.package_install(repo_rpm_urls)
            break

def install(uname_machine):
    pkgs = devsetup.package_list_load('rpmfusion.packages', uname_machine)
    rpmfusion_repo_setup(uname_machine)
    pkg_ops = devsetup.PackageOps()
    pkg_ops.package_install(pkgs)

def main():
    install(os.uname().machine)

if __name__ == '__main__':
    main()
