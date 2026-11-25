#!/usr/bin/env python3
"""Expose outbound Remote Control in ChatGPT's Linux renderer."""

import argparse
from collections import Counter
import hashlib
import json
import mmap
from pathlib import Path
import re
import struct
import subprocess

# Keep substitutions the same size so offsets for packed and unpacked
# resources stay valid. Match counts are checked against verified builds.
# Changes to the upstream UI must be reviewed before a new image is published.
RULES = (
    (
        "start remote discovery",
        rb't=[is]\("1042620455"\)\|\|l',
        rb"t=!0",
        1,
    ),
    (
        "show remote controls when the service is available",
        rb"return [lst]&&\(e\?\.available\?\?!0\)&&e\?\.accessRequired!==!0",
        rb"return (e?.available??!0)&&e?.accessRequired!==!0",
        6,
    ),
    (
        "show the outbound tab",
        rb"tN=\(0,B\.Zj\)\(eI\.K0\)",
        rb"tN=!1",
        1,
    ),
    (
        "show the outbound tab in settings search",
        rb"([si])&&!e\([cd]\.P,f\)&&o\.push\((\w+)\(\"access-other-devices\",t\)\)",
        rb'\1&&o.push(\2("access-other-devices",t))',
        2,
    ),
)


def files(tree, parent=""):
    for name, entry in tree["files"].items():
        path = f"{parent}/{name}"
        if "files" in entry:
            yield from files(entry, path)
        elif "offset" in entry:
            yield path, entry


def padded_substitute(source, pattern, replacement):
    def substitute(match):
        value = match.expand(replacement)
        if len(value) > len(match[0]):
            raise ValueError("replacement would shift ASAR offsets")
        return value.ljust(len(match[0]))

    return re.subn(pattern, substitute, source)


def update_integrity(entry, original, patched):
    integrity = entry["integrity"]
    if integrity["algorithm"] != "SHA256":
        raise ValueError("unexpected ASAR integrity algorithm")
    if hashlib.sha256(original).hexdigest() != integrity["hash"]:
        raise ValueError("upstream asset does not match its ASAR hash")
    block_size = integrity["blockSize"]
    integrity["hash"] = hashlib.sha256(patched).hexdigest()
    integrity["blocks"] = [
        hashlib.sha256(patched[offset:offset + block_size]).hexdigest()
        for offset in range(0, len(patched), block_size)
    ]


def patch_archive(archive):
    counts = Counter()
    updates = []
    with archive.open("r+b") as handle, mmap.mmap(handle.fileno(), 0) as data:
        marker, header_size, payload_size, json_size = struct.unpack_from("<4I", data)
        header_end = 16 + json_size
        assets_start = 8 + header_size
        if (
            marker != 4
            or payload_size != header_size - 4
            or not header_end <= assets_start <= len(data)
        ):
            raise ValueError("unexpected ASAR header")
        tree = json.loads(data[16:header_end])
        for path, entry in files(tree):
            if not path.startswith("/webview/assets/") or not path.endswith(".js"):
                continue
            start = assets_start + int(entry["offset"])
            original = data[start:start + entry["size"]]
            patched = original
            for label, pattern, replacement, _ in RULES:
                patched, matches = padded_substitute(patched, pattern, replacement)
                counts[label] += matches
            if patched != original:
                update_integrity(entry, original, patched)
                updates.append((path, start, patched))

        for label, _, _, expected in RULES:
            if counts[label] != expected:
                raise ValueError(f"{label}: expected {expected} matches, found {counts[label]}")

        header = json.dumps(tree, ensure_ascii=False, separators=(",", ":")).encode()
        if len(header) != json_size:
            raise ValueError("rewritten header would shift ASAR offsets")

        node = archive.with_name("node")
        for path, _, patched in updates:
            # The bundled Node checks syntax without executing the renderer.
            result = subprocess.run(
                [node, "--input-type=module", "--check", "-"],
                input=patched,
                capture_output=True,
            )
            if result.returncode:
                raise ValueError(f"{path}: modified JavaScript failed syntax validation")

        # Validate the complete patch before writing any asset or header.
        for _, start, patched in updates:
            data[start:start + len(patched)] = patched
        data[16:header_end] = header
        data.flush()

    print(f"Enabled Control other devices in {len(updates)} renderer assets")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path, help="path to ChatGPT's app.asar")
    args = parser.parse_args()
    try:
        patch_archive(args.archive)
    except (OSError, ValueError, KeyError, struct.error) as error:
        parser.exit(1, f"{args.archive}: remote control patch failed: {error}\n")


if __name__ == "__main__":
    main()
