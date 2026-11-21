#!/usr/bin/env python3
"""Make the PNG pieces for the GRUB and Plymouth themes in your Glyph colours.
Usage: make-images.py palette.env grub_dir plymouth_dir
Sizes come from environment variables set by install-boot.sh:
  GW GH (boot menu box), BH (title bar), IH (menu row), LBW (title box width), FH (footer), FS (font size)
No extra Python packages needed."""
import os
import struct
import sys
import zlib
from pathlib import Path


def png(path, w, h, px):
    raw = b"".join(b"\x00" + b"".join(bytes(px(x, y)) for x in range(w)) for y in range(h))
    chunk = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))


def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)] + [255]


def mix(a, b, t):
    return [round(a[i] * (1 - t) + b[i] * t) for i in range(3)] + [255]


pal = {}
for l in Path(sys.argv[1]).read_text().splitlines():
    if l.startswith("GLYPH_"):
        k, v = l.split("=", 1)
        pal[k[6:].lower()] = rgb(v.strip().strip('"'))
g, p = Path(sys.argv[2]), Path(sys.argv[3])
title, tink, view, win, hi, lo = (pal[k] for k in ("title", "tink", "view", "win", "hi", "lo"))
stripe = mix(title, tink, 0.22)
dark = mix(title, tink, 0.45)
E = lambda k, d: int(os.environ.get(k, d))
GW, GH, BH, IH, LBW, FH = E("GW", 640), E("GH", 220), E("BH", 30), E("IH", 40), E("LBW", 120), E("FH", 32)
FOOT = GH - FH

# GRUB: the whole boot-menu box as one picture: striped title bar with the
# title box, the window, a line above the footer, and a border
def box(x, y):
    if x == 0 or y == 0 or x == GW - 1 or y == GH - 1:
        return title
    if y < BH:
        lb = 8 <= x < 8 + LBW and 4 <= y < BH - 4
        if lb:
            edge = x in (8, 8 + LBW - 1) or y in (4, BH - 5)
            return dark if edge else title
        return stripe if y % 3 == 1 else title
    if y == BH:
        return lo
    if y == FOOT:
        return hi
    return win
png(g / "box.png", GW, GH, box)
# selected row: striped, like the title bar (exact row height, so nothing is stretched)
png(g / "sel_c.png", 8, IH, lambda x, y: stripe if y % 3 == 1 else title)
for part in ("nw", "n", "ne", "w", "e", "sw", "s", "se"):
    png(g / f"sel_{part}.png", 1, 1, lambda x, y: title)
for part in ("nw", "n", "ne", "w", "e", "sw", "s", "se", "c"):
    png(g / f"term_{part}.png", 1, 1, lambda x, y, c=(lo if part == "c" else hi): c)

# Plymouth: progress blocks (empty and filled, filled ones striped)
S = E("SEG", 20)
SH_ = max(10, S * 3 // 5)
png(p / "seg_off.png", S, SH_, lambda x, y: hi if (x in (0, S - 1) or y in (0, SH_ - 1)) else mix(lo, hi, 0.45))
png(p / "seg_on.png", S, SH_, lambda x, y: stripe if y % 3 == 1 else title)
