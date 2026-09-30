"""Create the 64x64 'parking-area.png' icon used by the vehicle-parking panel.

The original Owl client shipped this icon inside its own resource; it is not
part of the backup, so it is regenerated here: a rounded blue badge (the same
#2947CC the parking panel uses for its buttons) with a white 'P'.

Usage:  python3 mk_parking_png.py
"""
import struct
import zlib

W = H = 64
RADIUS = 12
BG = (41, 71, 204, 255)
FG = (255, 255, 255, 255)
OUT = "mods/deathmatch/resources/vehicle-parking/parking-area.png"


def inside_rounded_rect(x, y, x0, y0, x1, y1, r):
    if x < x0 or x > x1 or y < y0 or y > y1:
        return False
    corners = ((x0 + r, y0 + r), (x1 - r, y0 + r), (x0 + r, y1 - r), (x1 - r, y1 - r))
    for i, (cx, cy) in enumerate(corners):
        near_x = x < x0 + r if i in (0, 2) else x > x1 - r
        near_y = y < y0 + r if i in (0, 1) else y > y1 - r
        if near_x and near_y:
            return (x - cx) ** 2 + (y - cy) ** 2 <= r * r
    return True


def glyph_p(x, y):
    if 19 <= x < 28 and 13 <= y < 53:          # stem
        return True
    dx, dy = x - 37, y - 25                    # bowl: right half of a ring
    dist = (dx * dx + dy * dy) ** 0.5
    if x >= 28 and y <= 39 and 6.5 <= dist <= 13.5:
        return True
    return False


rows = []
for y in range(H):
    row = bytearray([0])  # PNG filter type 0
    for x in range(W):
        if not inside_rounded_rect(x, y, 0, 0, W - 1, H - 1, RADIUS):
            row += bytes((0, 0, 0, 0))
        elif glyph_p(x, y):
            row += bytes(FG)
        else:
            row += bytes(BG)
    rows.append(bytes(row))

raw = b"".join(rows)


def chunk(tag, data):
    return (struct.pack(">I", len(data)) + tag + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))


png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(raw, 9))
       + chunk(b"IEND", b""))

with open(OUT, "wb") as fh:
    fh.write(png)
print("wrote %s (%d bytes, %dx%d)" % (OUT, len(png), W, H))
