#!/usr/bin/env python3

import argparse
import plistlib
import subprocess
import sys


SYMBOLIC_HOTKEY_IDS = {
    1: 118,
    2: 119,
    3: 120,
    4: 121,
}

NUMBER_KEY_CODES = {
    1: 18,
    2: 19,
    3: 20,
    4: 21,
}

CTRL_MODIFIER = 262144


def hotkey_entry(number):
    return {
        "enabled": True,
        "value": {
            "type": "standard",
            "parameters": [ord(str(number)), NUMBER_KEY_CODES[number], CTRL_MODIFIER],
        },
    }


def load_preferences():
    result = subprocess.run(
        ["defaults", "export", "com.apple.symbolichotkeys", "-"],
        check=True,
        capture_output=True,
    )
    return plistlib.loads(result.stdout)


def save_preferences(preferences):
    payload = plistlib.dumps(preferences, fmt=plistlib.FMT_XML)
    subprocess.run(
        ["defaults", "import", "com.apple.symbolichotkeys", "-"],
        input=payload,
        check=True,
    )


def apply_hotkeys():
    preferences = load_preferences()
    hotkeys = preferences.setdefault("AppleSymbolicHotKeys", {})
    for desktop, hotkey_id in SYMBOLIC_HOTKEY_IDS.items():
        hotkeys[str(hotkey_id)] = hotkey_entry(desktop)
    save_preferences(preferences)


def restart_services():
    subprocess.run(["/usr/bin/killall", "cfprefsd"], check=False)
    subprocess.run(["/usr/bin/killall", "Dock"], check=False)


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Set Mission Control desktop shortcuts to Ctrl+1 through Ctrl+4."
    )
    parser.add_argument(
        "--no-restart",
        action="store_true",
        help="Do not restart Dock or cfprefsd after updating preferences.",
    )
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    apply_hotkeys()
    if not args.no_restart:
        restart_services()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
