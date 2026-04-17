#!/usr/bin/env python3

import argparse
import json
import plistlib
import subprocess
import sys


LEFT_OPTION = 0x7000000E2
LEFT_COMMAND = 0x7000000E3
RIGHT_OPTION = 0x7000000E6
RIGHT_COMMAND = 0x7000000E7


def modifier_entry(src, dst):
    return {
        "HIDKeyboardModifierMappingSrc": src,
        "HIDKeyboardModifierMappingDst": dst,
    }


def option_command_swap():
    return [
        modifier_entry(LEFT_OPTION, LEFT_COMMAND),
        modifier_entry(LEFT_COMMAND, LEFT_OPTION),
        modifier_entry(RIGHT_OPTION, RIGHT_COMMAND),
        modifier_entry(RIGHT_COMMAND, RIGHT_OPTION),
    ]


def load_current_host_preferences():
    result = subprocess.run(
        ["defaults", "-currentHost", "export", "-g", "-"],
        check=True,
        capture_output=True,
    )
    return plistlib.loads(result.stdout)


def save_current_host_preferences(preferences):
    payload = plistlib.dumps(preferences, fmt=plistlib.FMT_XML)
    subprocess.run(
        ["defaults", "-currentHost", "import", "-g", "-"],
        input=payload,
        check=True,
    )


def parse_hidutil_devices():
    result = subprocess.run(
        ["hidutil", "list", "--matching", '{"DeviceUsagePage":1,"DeviceUsage":6}'],
        check=True,
        capture_output=True,
        text=True,
    )
    lines = result.stdout.splitlines()
    devices = []
    in_devices = False
    for line in lines:
        line = line.rstrip()
        if line.strip() == "Devices:":
            in_devices = True
            continue
        if not in_devices or not line.strip():
            continue
        if line.lstrip().startswith("VendorID"):
            continue

        parts = line.split()
        if len(parts) < 9:
            continue
        built_in = parts[-1]
        user_class = parts[-2]
        product = " ".join(parts[8:-2])
        devices.append(
            {
                "vendor_id": int(parts[0], 16),
                "product_id": int(parts[1], 16),
                "location_id": int(parts[2], 16),
                "usage_page": int(parts[3]),
                "usage": int(parts[4]),
                "registry_id": parts[5],
                "transport": parts[6],
                "class": parts[7],
                "product": product,
                "user_class": user_class,
                "built_in": built_in == "1",
            }
        )
    return devices


def current_external_keyboard():
    devices = parse_hidutil_devices()
    keyboards = [
        device
        for device in devices
        if device["usage_page"] == 1
        and device["usage"] == 6
        and not device["built_in"]
        and device["transport"] != "Virtual"
    ]
    if not keyboards:
        raise RuntimeError("no external keyboard found")

    keyboards.sort(key=lambda device: (device["location_id"], device["vendor_id"], device["product_id"]))
    return keyboards[0]


def profile_name_for_device(device):
    return f'{device["vendor_id"]}-{device["product_id"]}-0'


def apply_mapping():
    device = current_external_keyboard()
    profile_name = profile_name_for_device(device)
    key = f"com.apple.keyboard.modifiermapping.{profile_name}"

    preferences = load_current_host_preferences()
    preferences[key] = option_command_swap()
    save_current_host_preferences(preferences)

    return {
        "profile_name": profile_name,
        "product": device["product"],
        "vendor_id": device["vendor_id"],
        "product_id": device["product_id"],
        "location_id": device["location_id"],
    }


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Swap Option and Command for the current external keyboard profile."
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print the selected keyboard and profile as JSON.",
    )
    return parser.parse_args(argv)


def main(argv):
    args = parse_args(argv)
    info = apply_mapping()
    if args.json:
        print(json.dumps(info, indent=2, sort_keys=True))
    else:
        print(info["profile_name"])
        print(info["product"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
