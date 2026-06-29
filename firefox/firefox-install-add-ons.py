# /// script
# requires-python = ">=3.13"
# ///
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen

try:
    import tomllib  # Python 3.13+
except ModuleNotFoundError:
    raise SystemExit("ERROR: tomllib not found. Use Python 3.13+ (stdlib-only requirement).")

AMO_API_ADDON = "https://addons.mozilla.org/api/v5/addons/addon/{slug}/"
AMO_LATEST_XPI = "https://addons.mozilla.org/firefox/downloads/latest/{slug}/latest.xpi"

FIREFOX_FLATPAK_APPIDS = ["org.mozilla.firefox", "org.mozilla.Firefox"]


# ---------- generic helpers ----------

def deep_merge(dst, src):
    """Recursively merge src into dst (dicts only)."""
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            deep_merge(dst[k], v)
        else:
            dst[k] = v
    return dst


def load_json(path: Path):
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8")) or {}
    except json.JSONDecodeError:
        raise SystemExit(f"ERROR: Existing JSON is invalid: {path}")


def save_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    tmp.replace(path)


def http_get_json(url: str) -> dict:
    req = Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "firefox-addon-policy-installer/1.0 (stdlib urllib)",
        },
        method="GET",
    )
    try:
        with urlopen(req, timeout=20) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            return json.loads(body)
    except Exception as e:
        raise RuntimeError(f"HTTP/JSON error for {url}: {e}") from e


# ---------- AMO parsing + GUID lookup ----------

def parse_amo_slug(addon_url: str) -> str:
    """
    Accepts URLs like:
      https://addons.mozilla.org/en-US/firefox/addon/<slug>/
    """
    u = urlparse(addon_url)
    if u.netloc != "addons.mozilla.org":
        raise ValueError(f"Not an addons.mozilla.org URL: {addon_url}")

    m = re.search(r"/firefox/addon/([^/]+)/?", u.path)
    if not m:
        raise ValueError(f"Could not extract add-on slug from URL: {addon_url}")
    return m.group(1)


def fetch_guid_for_slug(slug: str) -> str:
    data = http_get_json(AMO_API_ADDON.format(slug=slug))
    guid = data.get("guid")
    if not guid:
        raise RuntimeError(f"No guid found in AMO API response for slug={slug}")
    return guid


def build_extension_settings(addon_urls: list[str]) -> dict:
    """
    Returns ExtensionSettings map keyed by extension ID (guid).
    """
    extension_settings = {}
    for addon_url in addon_urls:
        slug = parse_amo_slug(addon_url)
        guid = fetch_guid_for_slug(slug)
        install_url = AMO_LATEST_XPI.format(slug=slug)
        extension_settings[guid] = {
            "installation_mode": "force_installed",
            "install_url": install_url,
            "default_area": "navbar",
        }
    return extension_settings


# ---------- Linux Flatpak detection + policy path ----------

def _run(cmd: list[str]) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return p.returncode, (p.stdout or "").strip()
    except FileNotFoundError:
        return 127, ""


def linux_flatpak_firefox_installed() -> str | None:
    code, _ = _run(["flatpak", "--version"])
    if code != 0:
        return None
    for appid in FIREFOX_FLATPAK_APPIDS:
        code, _ = _run(["flatpak", "info", appid])
        if code == 0:
            return appid
    return None


def flatpak_arch() -> str:
    code, arch = _run(["flatpak", "--default-arch"])
    if code == 0 and arch:
        return arch

    m = platform.machine().lower()
    if m in ("x86_64", "amd64"):
        return "x86_64"
    if m in ("aarch64", "arm64"):
        return "aarch64"
    return m or "x86_64"


def linux_policy_path() -> Path:
    """
    Flatpak Firefox: use systemconfig extension policy location.
    Non-Flatpak Firefox: /etc/firefox/policies/policies.json
    """
    appid = linux_flatpak_firefox_installed()
    if appid:
        arch = flatpak_arch()
        branch = "stable"

        sys_path = (
            Path("/var/lib/flatpak/extension")
            / "org.mozilla.firefox.systemconfig"
            / arch
            / branch
            / "policies"
            / "policies.json"
        )

        xdg_data_home = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local" / "share")))
        user_path = (
            xdg_data_home
            / "flatpak"
            / "extension"
            / "org.mozilla.firefox.systemconfig"
            / arch
            / branch
            / "policies"
            / "policies.json"
        )

        # Root -> system-wide; non-root -> per-user
        if hasattr(os, "geteuid") and os.geteuid() == 0:
            return sys_path
        return user_path

    return Path("/etc/firefox/policies/policies.json")


def _dedupe_paths(paths):
    seen = set()
    for path in paths:
        if not path:
            continue
        p = Path(path)
        key = str(p).casefold() if platform.system().lower() == "windows" else str(p)
        if key in seen:
            continue
        seen.add(key)
        yield p


def windows_firefox_install_dirs():
    dirs = []

    try:
        import winreg
    except ImportError:
        winreg = None

    if winreg is not None:
        app_paths = r"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe"
        views = [0]
        for view in (getattr(winreg, "KEY_WOW64_64KEY", 0), getattr(winreg, "KEY_WOW64_32KEY", 0)):
            if view and view not in views:
                views.append(view)

        for root in (winreg.HKEY_CURRENT_USER, winreg.HKEY_LOCAL_MACHINE):
            for view in views:
                try:
                    with winreg.OpenKey(root, app_paths, 0, winreg.KEY_READ | view) as key:
                        exe, _ = winreg.QueryValueEx(key, "")
                        if exe:
                            dirs.append(Path(exe).parent)
                except OSError:
                    pass

    which = shutil.which("firefox")
    if which:
        dirs.append(Path(which).parent)

    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        dirs.append(Path(local_app_data) / "Mozilla Firefox")

    pf = os.environ.get("PROGRAMFILES", r"C:\Program Files")
    pf86 = os.environ.get("PROGRAMFILES(X86)", r"C:\Program Files (x86)")
    dirs.extend([Path(pf) / "Mozilla Firefox", Path(pf86) / "Mozilla Firefox"])

    yield from _dedupe_paths(dirs)


def candidate_policy_paths():
    system = platform.system().lower()

    if system == "linux":
        yield linux_policy_path()
        return

    if system == "darwin":
        yield Path("/Applications/Firefox.app/Contents/Resources/distribution/policies.json")
        return

    if system == "windows":
        for base in windows_firefox_install_dirs():
            yield base / "distribution" / "policies.json"
        return

    raise SystemExit(f"Unsupported OS: {platform.system()}")


def pick_policy_path() -> Path:
    override = os.environ.get("FIREFOX_POLICY_PATH")
    if override:
        return Path(override)

    candidates = list(candidate_policy_paths())
    for p in candidates:
        if p.exists():
            return p
    for p in candidates:
        if p.parent.exists():
            return p
    return candidates[0]


def windows_registry_root_name(root):
    import winreg

    if root == winreg.HKEY_CURRENT_USER:
        return "HKEY_CURRENT_USER"
    if root == winreg.HKEY_LOCAL_MACHINE:
        return "HKEY_LOCAL_MACHINE"
    return str(root)


def load_windows_registry_extension_settings(root):
    import winreg

    subkey = r"Software\Policies\Mozilla\Firefox"
    try:
        with winreg.OpenKey(root, subkey, 0, winreg.KEY_READ) as key:
            value, value_type = winreg.QueryValueEx(key, "ExtensionSettings")
    except FileNotFoundError:
        return {}

    if value_type != winreg.REG_MULTI_SZ:
        raise SystemExit(
            f"ERROR: Existing Firefox ExtensionSettings registry value is not REG_MULTI_SZ: "
            f"{windows_registry_root_name(root)}\\{subkey}"
        )

    text = "\n".join(value)
    if not text.strip():
        return {}
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        raise SystemExit(
            f"ERROR: Existing Firefox ExtensionSettings registry JSON is invalid: "
            f"{windows_registry_root_name(root)}\\{subkey}"
        )


def save_windows_registry_extension_settings(root, extension_settings):
    import winreg

    subkey = r"Software\Policies\Mozilla\Firefox"
    existing = load_windows_registry_extension_settings(root)
    merged = deep_merge(existing, extension_settings)
    value = json.dumps(merged, indent=2, ensure_ascii=False).splitlines()

    key = winreg.CreateKeyEx(root, subkey, 0, winreg.KEY_WRITE)
    try:
        winreg.SetValueEx(key, "ExtensionSettings", 0, winreg.REG_MULTI_SZ, value)
    finally:
        winreg.CloseKey(key)

    return f"{windows_registry_root_name(root)}\\{subkey}\\ExtensionSettings"


def write_windows_policy(extension_settings, target):
    import winreg

    if target == "registry":
        return save_windows_registry_extension_settings(winreg.HKEY_CURRENT_USER, extension_settings)

    policy_path = pick_policy_path()
    existing = load_json(policy_path)
    patch = {"policies": {"ExtensionSettings": extension_settings}}
    merged = deep_merge(existing, patch)

    if target == "file":
        save_json(policy_path, merged)
        return str(policy_path)

    try:
        save_json(policy_path, merged)
        return str(policy_path)
    except PermissionError:
        return save_windows_registry_extension_settings(winreg.HKEY_CURRENT_USER, extension_settings)


def firefox_install_add_ons():
    import argparse

    ap = argparse.ArgumentParser(
        description="Force-install Firefox add-ons from a TOML list via Enterprise Policies (stdlib only)."
    )
    ap.add_argument(
        "add_ons_tomls",
        nargs="*",
        default=["add-ons.toml"],
        help="Path(s) to TOML files (default: add-ons.toml)",
    )
    ap.add_argument(
        "--windows-policy-target",
        choices=["auto", "file", "registry"],
        default="auto",
        help=(
            "Windows only: write policies.json next to firefox.exe, write HKCU registry policy, "
            "or try policies.json first and fall back to HKCU registry on permission errors."
        ),
    )
    args = ap.parse_args()

    addon_urls = []
    seen_addon_urls = set()
    for toml_arg in args.add_ons_tomls:
        toml_path = Path(toml_arg)
        if not toml_path.exists():
            raise SystemExit(f"ERROR: TOML file not found: {toml_path}")

        try:
            cfg = tomllib.loads(toml_path.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError as e:
            raise SystemExit(f"ERROR: TOML is invalid: {toml_path}: {e}")

        file_addon_urls = cfg.get("addons")
        if not isinstance(file_addon_urls, list) or not all(isinstance(x, str) for x in file_addon_urls):
            raise SystemExit(f'ERROR: TOML must contain: addons = ["https://..."]: {toml_path}')
        for addon_url in file_addon_urls:
            if addon_url in seen_addon_urls:
                continue
            seen_addon_urls.add(addon_url)
            addon_urls.append(addon_url)

    extension_settings = build_extension_settings(addon_urls)
    system = platform.system().lower()

    if system == "windows":
        policy_location = write_windows_policy(extension_settings, args.windows_policy_target)
    else:
        policy_path = pick_policy_path()
        existing = load_json(policy_path)
        patch = {"policies": {"ExtensionSettings": extension_settings}}
        merged = deep_merge(existing, patch)
        save_json(policy_path, merged)
        policy_location = str(policy_path)

    print(f"Wrote/updated: {policy_location}")
    print("Restart Firefox, then verify in: about:policies")

if __name__ == "__main__":
    firefox_install_add_ons()
