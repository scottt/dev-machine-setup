"""Extract the desktop icon from Google's Electron archive at image build time."""

import json
from pathlib import Path
import struct
import sys


archive, output = map(Path, sys.argv[1:])
with archive.open("rb") as source:
    # ASAR stores a Chromium Pickle header followed by the packed file data.
    _, header_size, _, json_size = struct.unpack("<IIII", source.read(16))
    header = json.loads(source.read(json_size))
    icon = header["files"]["icon.png"]
    source.seek(8 + header_size + int(icon["offset"]))
    output.write_bytes(source.read(icon["size"]))
