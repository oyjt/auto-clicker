"""Package standard PNG icon representations without external dependencies."""
from pathlib import Path
import struct
import sys

source, destination = map(Path, sys.argv[1:])
entries = [("icp4", "icon_16x16.png"), ("icp5", "icon_32x32.png"),
           ("icp6", "icon_32x32@2x.png"), ("ic07", "icon_128x128.png"),
           ("ic08", "icon_256x256.png"), ("ic09", "icon_512x512.png"),
           ("ic10", "icon_512x512@2x.png")]
chunks = []
for kind, name in entries:
    png = (source / name).read_bytes()
    assert png.startswith(b"\x89PNG\r\n\x1a\n"), name
    chunks.append(kind.encode("ascii") + struct.pack(">I", len(png) + 8) + png)
body = b"".join(chunks)
result = b"icns" + struct.pack(">I", len(body) + 8) + body
assert struct.unpack(">I", result[4:8])[0] == len(result)
destination.write_bytes(result)
