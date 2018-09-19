#!/usr/bin/env python3

# RPMFusion

import sys
import os
import subprocess

import devsetup

def rpmfusion_repo_setup(uname_machine):
    repo_rpm_urls = devsetup.repo_rpm_urls_load('rpmfusion.repo-rpm-urls', uname_machine)
    for i in repo_rpm_urls:
        pkg = os.path.basename(i)
        # 'X.noarch.rpm' -> 'X'
        pkg = pkg[:pkg.find('.')]
        if not devsetup.package_is_installed(pkg):
            devsetup.package_install(repo_rpm_urls)
            break

def install(uname_machine):
    pkgs = devsetup.package_list_load('rpmfusion.packages', uname_machine)
    rpmfusion_repo_setup(uname_machine)
    devsetup.package_install(pkgs)

def main():
    install(os.uname().machine)

if __name__ == '__main__':
    main()
