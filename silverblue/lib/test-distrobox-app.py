"""Lifecycle regression tests; all container/network operations are mocked.

Run: python3 lib/test-distrobox-app.py
"""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


LIB = Path(__file__).resolve().parent
HARNESS = r'''
set -euo pipefail
. "$LIB/distrobox-app.sh"
app_name=Test
app_id=test-desktop
app_dir=/unused
image=localhost/test-desktop:latest
container=test
app_process=Test
app_icon=test
latest_versions() { echo VERSION=2; }
installed_versions() { echo VERSION=1; }
image_id() { echo "${LOCAL_IMAGE-new}"; }
container_image_id() { echo "${CONTAINER_IMAGE-old}"; }
app_running() { [ "${RUNNING-no}" = yes ]; }
build_image() { echo build; }
recreate_container() { echo deploy; }
install_timer() { echo timer; }
notify() { echo notify; }
remove_image() { echo cleanup; }
# Remote commands deliberately support images only, never containers.
ssh_source() {
    case "$*" in
    "podman image inspect $image")
        echo '[{"Id":"remote","Labels":{"dev-machine-setup.versions":"VERSION=2"}}]' ;;
    "podman save remote") echo archive ;;
    *) echo "unexpected SSH: $*" >&2; return 99 ;;
    esac
}
podman() {
    case "$*" in
    "load --quiet") [ "$(cat)" = archive ] ;;
    "image exists remote") return 0 ;;
    "tag remote $image") echo copy ;;
    *) echo "unexpected podman: $*" >&2; return 99 ;;
    esac
}
distrobox_app_main "$@"
'''


class LifecycleTests(unittest.TestCase):
    def run_mode(self, *args, code=0, **env):
        result = subprocess.run(
            ["bash", "-c", HARNESS, "test", *args],
            env={**os.environ, "LIB": str(LIB), **env},
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, code, result.stderr)
        return result.stdout.splitlines()

    def test_build_leaves_running_app_and_timer_alone(self):
        self.assertEqual(self.run_mode("--build", RUNNING="yes"), ["build"])

    def test_build_without_container(self):
        self.assertEqual(self.run_mode("--build", CONTAINER_IMAGE=""), ["build"])

    def test_deploy_only_uses_local_image(self):
        self.assertEqual(self.run_mode("--deploy"), ["deploy"])

    def test_deploy_refuses_running_app(self):
        self.assertEqual(self.run_mode("--deploy", RUNNING="yes", code=1), [])

    def test_force_deploy_closes_running_app(self):
        self.assertEqual(self.run_mode("--deploy", "--force", RUNNING="yes"), ["deploy"])

    def test_deploy_requires_image_even_with_force(self):
        self.assertEqual(self.run_mode("--deploy", "--force", LOCAL_IMAGE="", code=1), [])

    def test_combined_install(self):
        self.assertEqual(self.run_mode(), ["build", "deploy", "timer"])

    def test_combined_install_does_not_close_app_implicitly(self):
        self.assertEqual(self.run_mode(RUNNING="yes", code=1), ["build"])

    def test_combined_force_and_no_timer(self):
        self.assertEqual(self.run_mode("--force", "--no-timer", RUNNING="yes"), ["build", "deploy"])

    def test_unattended_defers_deployment(self):
        self.assertEqual(self.run_mode("--if-newer", RUNNING="yes"), ["build", "notify"])

    def test_unattended_deploys_when_closed(self):
        self.assertEqual(self.run_mode("--if-newer"), ["build", "deploy"])

    def test_remote_build_without_any_remote_container_commands(self):
        self.assertEqual(
            self.run_mode("--build", "--from", "tt0-images", RUNNING="yes", CONTAINER_IMAGE=""),
            ["copy", "cleanup"],
        )

    def test_remote_install_without_any_remote_container_commands(self):
        self.assertEqual(
            self.run_mode("--from", "tt0-images"), ["copy", "cleanup", "deploy", "timer"]
        )

    def test_invalid_combinations_have_no_side_effects(self):
        for args in [
            ["--build", "--deploy"], ["--deploy", "--from", "tt0-images"],
            ["--build", "--force"], ["--if-newer", "--force"],
            ["--build", "--no-timer"], ["--from"],
        ]:
            with self.subTest(args=args):
                self.assertEqual(self.run_mode(*args, code=2), [])

    def test_ssh_server_needs_only_built_images(self):
        with tempfile.TemporaryDirectory() as directory:
            podman = Path(directory) / "podman"
            podman.write_text('''#!/bin/bash
set -eu
case "$*" in
  "image inspect localhost/chatgpt-desktop:latest"|"image inspect localhost/claude-desktop:latest"|"image inspect localhost/antigravity-desktop:latest") echo image ;;
  "image inspect --format {{.Id}} localhost/chatgpt-desktop:latest"|"image inspect --format {{.Id}} localhost/claude-desktop:latest") printf '%064d\\n' 1 ;;
  "save "*) echo archive ;;
  *) exit 99 ;;
esac
''')
            podman.chmod(0o755)
            for command, expected in [
                ("podman image inspect localhost/chatgpt-desktop:latest", "image"),
                ("podman image inspect localhost/claude-desktop:latest", "image"),
                ("podman image inspect localhost/antigravity-desktop:latest", "image"),
                (f"podman save {1:064d}", "archive"),
            ]:
                with self.subTest(command=command):
                    result = subprocess.run(
                        ["bash", str(LIB / "distrobox-app-serve")],
                        env={**os.environ, "PATH": directory + os.pathsep + os.environ["PATH"],
                             "SSH_ORIGINAL_COMMAND": command},
                        text=True, capture_output=True,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.strip(), expected)


if __name__ == "__main__":
    unittest.main()
