#!/usr/bin/env python3
"""Make the small PNG pieces for the GRUB and Plymouth themes in your Glyph colours.
Usage: make-images.py palette.env grub_dir plymouth_dir   (no extra Python packages needed)"""
import struct
import sys
import zlib
from pathlib import Path


def png(path, w, h, px):
    raw = b"".join(b"\x00" + b"".join(bytes(px(x, y)) for x in range(w)) for y in range(h))
    chunk = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    Path(path).write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                           + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)] + [255]


def mix(a, b, t):
    return [round(a[i] * (1 - t) + b[i] * t) for i in range(3)] + [255]


pal = {}
for l in Path(sys.argv[1]).read_text().splitlines():
    if l.startswith("GLYPH_"):
        k, v = l.split("=", 1)
        pal[k[6:].lower()] = rgb(v)
g, p = Path(sys.argv[2]), Path(sys.argv[3])
title, tink, view, win, hi, lo, amber = (pal[k] for k in ("title", "tink", "view", "win", "hi", "lo", "amber"))
stripe = mix(title, tink, 0.3)

# GRUB: striped title bar, menu box (9 pieces), selected row (9 pieces), terminal box
png(g / "bar.png", 600, 30, lambda x, y: stripe if y % 3 == 1 else title)
for name, centre, edge in (("menu", win, title), ("sel", title, title), ("term", view, hi)):
    for part, (w, h) in {"nw": (1, 1), "n": (1, 1), "ne": (1, 1), "w": (1, 1), "e": (1, 1),
                         "sw": (1, 1), "s": (1, 1), "se": (1, 1), "c": (8, 8)}.items():
        png(g / f"{name}_{part}.png", w, h, (lambda x, y, c=(centre if part == "c" else edge): c))

# Plymouth: frame around the progress bar and the striped fill
png(p / "frame.png", 360, 16, lambda x, y: hi if x in (0, 359) or y in (0, 15) else lo)
png(p / "fill.png", 1, 10, lambda x, y: stripe if y % 3 == 1 else title)
