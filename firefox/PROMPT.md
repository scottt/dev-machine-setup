Model: ChatGPT 5.2 Auto

# Improved Prompt

Write a Python script to read a TOML file listing Firefox add-ons to install.
Use only the Python standard library.
Support Firefox installed via Flatpak.

Create an firefox-add-ons.toml file that includes:
* https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/
* https://addons.mozilla.org/en-US/firefox/addon/tab-session-manager/

# Original Prompt Session

P0: Install the Firefox Multi-Account Containers add-on via Python

(Read https://support.mozilla.org/en-US/kb/customizing-firefox-using-policiesjson)
P1: For Linux, put policies.json in `/etc/firefox/policies`

P2: Keep Windows and MacOS support

P3: Modify the script to read a TOML file listing Firefox add-ons to install.
    Create an firefox-add-ons.toml file that includes:
    https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/
    https://addons.mozilla.org/en-US/firefox/addon/tab-session-manager/

Model: If you’re using Flatpak or Snap Firefox on Linux, say which one—those packaging formats often don’t read /etc/firefox/policies by default, and the policy path/override needs to be handled differently.
P4: I use Flatpak

(Found out script uses the `requests` Python module)
P5: Modify `install_firefox_addons_from_toml.py` to only use the standard library
