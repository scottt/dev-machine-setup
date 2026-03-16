#!/usr/bin/env python3
"""
vscode-ext-install.py

Read a file of VS Code extension IDs, skip blank lines and comments starting
with '#', and install each extension via the `code` CLI.

Usage:
    python vscode-ext-install.py extensions.txt
    python vscode-ext-install.py extensions.txt --code-bin code-insiders
    python vscode-ext-install.py extensions.txt --no-force
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import platform
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install VS Code extensions from a file."
    )
    parser.add_argument(
        "extension_file",
        type=Path,
        help="Path to a text file containing VS Code extension IDs.",
    )
    vscode_binary_name = "code.cmd" if platform.system() == "Windows" else "code"
    parser.add_argument(
        "--code-bin",
        default="code.cmd",
        help="VS Code CLI executable to use (default: code).",
    )
    parser.add_argument(
        "--no-force",
        action="store_true",
        help="Do not pass --force to the VS Code CLI.",
    )
    return parser.parse_args()


def iter_extensions(path: Path) -> list[str]:
    extensions: list[str] = []

    with path.open("r", encoding="utf-8") as f:
        for lineno, raw_line in enumerate(f, start=1):
            line = raw_line.strip()

            if not line:
                continue

            if line.startswith("#"):
                continue

            # Allow inline comments: ms-python.python  # Python support
            if "#" in line:
                line = line.split("#", 1)[0].strip()

            if not line:
                continue

            extensions.append(line)

    return extensions


def install_extension(code_bin: str, extension: str, force: bool) -> int:
    cmd = [code_bin, "--install-extension", extension]
    if force:
        cmd.append("--force")

    result = subprocess.run(cmd, check=False)
    return result.returncode


def main() -> int:
    args = parse_args()

    if shutil.which(args.code_bin) is None:
        print(
            f"Error: VS Code CLI '{args.code_bin}' was not found in PATH.",
            file=sys.stderr,
        )
        return 1

    if not args.extension_file.is_file():
        print(
            f"Error: extension file not found: {args.extension_file}",
            file=sys.stderr,
        )
        return 1

    extensions = iter_extensions(args.extension_file)

    if not extensions:
        print("No extensions to install.")
        return 0

    failures = 0
    force = not args.no_force

    for ext in extensions:
        print(f"Installing {ext}...")
        rc = install_extension(args.code_bin, ext, force=force)
        if rc != 0:
            failures += 1
            print(f"Failed: {ext}", file=sys.stderr)

    if failures:
        print(f"Completed with {failures} failure(s).", file=sys.stderr)
        return 2

    print("All extensions installed successfully.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
