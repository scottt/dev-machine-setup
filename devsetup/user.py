import sys
import os

def default_uid():
    # On Linux, `setup-all`, `docker-nonroot` etc are run with `sudo`.
    # On Macs, they're not.
    if sys.platform.startswith('linux'):
        uid = 1000
    elif sys.platform.startswith('darwin'):
        uid = os.getuid()
    else:
        raise RuntimeError(f'Unsupported OS: "{sys.platform}"')
    return uid
