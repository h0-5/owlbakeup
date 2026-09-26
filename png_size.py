"""Print width/height of a PNG by reading its IHDR chunk (no PIL needed)."""
import struct
import sys

for p in sys.argv[1:]:
    with open(p, "rb") as fh:
        head = fh.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        print(f"{p}: not a png")
        continue
    w, h = struct.unpack(">II", head[16:24])
    print(f"{p}: {w} x {h}   ratio h/w = {h / w:.4f}")
