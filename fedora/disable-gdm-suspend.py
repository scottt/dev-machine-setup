#!/usr/bin/env python3
import os
import subprocess
import sys
import textwrap

OVERRIDE_PATH = "/etc/dconf/db/gdm.d/00-disable-suspend"

OVERRIDE = textwrap.dedent("""\
    [org/gnome/settings-daemon/plugins/power]
    sleep-inactive-ac-type='nothing'
    sleep-inactive-battery-type='nothing'
    sleep-inactive-ac-timeout=0
    sleep-inactive-battery-timeout=0
""")

def main():
    if os.geteuid() != 0:
        sys.exit("must run as root (writes to /etc/dconf/db/gdm.d/)")

    os.makedirs(os.path.dirname(OVERRIDE_PATH), exist_ok=True)
    with open(OVERRIDE_PATH, "w") as f:
        f.write(OVERRIDE)
    print(f"wrote {OVERRIDE_PATH}")

    subprocess.run(["dconf", "update"], check=True)
    print("ran dconf update")

if __name__ == "__main__":
    main()
