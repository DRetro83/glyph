#!/usr/bin/env python3
"""Make the PNG pieces for the GRUB and Plymouth themes in your Glyph colours.
Usage: make-images.py palette.env grub_dir plymouth_dir
Sizes come from environment variables set by install-boot.sh:
  GW GH (boot menu box), BH (title bar), IH (menu row), LBW (title box width), FH (footer), FS (font size)
No extra Python packages needed."""
import os
import shlex
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

# Text as pictures (Pango + Cairo), so GRUB and Plymouth show it even when
# their own fonts are missing. Sizes go to sizes.sh for install-boot.sh.
sizes = {}
try:
    import gi
    gi.require_version("Pango", "1.0")
    gi.require_version("PangoCairo", "1.0")
    from gi.repository import Pango, PangoCairo
    import cairo

    def text_png(path, text, font, colour, spacing=0, key=None):
        probe = cairo.Context(cairo.ImageSurface(cairo.FORMAT_ARGB32, 1, 1))
        lay = PangoCairo.create_layout(probe)
        lay.set_font_description(Pango.FontDescription.from_string(font))
        if spacing:
            al = Pango.AttrList()
            al.insert(Pango.attr_letter_spacing_new(int(spacing * Pango.SCALE)))
            lay.set_attributes(al)
        lay.set_text(text, -1)
        w, h = lay.get_pixel_size()
        w, h = max(w, 1), max(h, 1)
        surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
        cr = cairo.Context(surf)
        c = colour
        cr.set_source_rgba(c[0] / 255, c[1] / 255, c[2] / 255, 1)
        lay2 = PangoCairo.create_layout(cr)
        lay2.set_font_description(lay.get_font_description())
        lay2.set_attributes(lay.get_attributes())
        lay2.set_text(text, -1)
        PangoCairo.show_layout(cr, lay2)
        surf.write_to_png(str(path))
        if key:
            sizes[key + "_W"], sizes[key + "_H"] = w, h

    FSZ = E("FS", 20)
    dim, text_c, tan = pal["dim"], pal["text"], pal.get("tan", title)
    text_png(g / "t_title.png", "■ BOOT MENU", f"IBM Plex Mono Bold {FSZ}px", tink, 1, "TT")
    text_png(g / "t_keys.png", "↑ ↓ choose  ·  Enter start", f"IBM Plex Mono {FSZ}px", dim, 0, "TK")
    text_png(g / "t_top.png", "DEBIAN · GLYPH", f"IBM Plex Mono {FSZ}px", dim, 1, "TP")
    text_png(p / "logo.png", "GLYPH", f"IBM Plex Mono Bold {FSZ * 3}px", text_c, 2, "PL")
    text_png(p / "sub.png", "DEBIAN 13 · LABWC", f"IBM Plex Mono {int(FSZ * 0.7)}px", dim, int(FSZ * 0.35), "PS")
    text_png(p / "hint.png", "Esc · show details", f"IBM Plex Mono {int(FSZ * 0.7)}px", dim, 0, "PH")
    text_png(p / "starting.png", "Starting …", f"IBM Plex Mono {int(FSZ * 0.8)}px", tan, 0, "PT")
    sizes["TEXTPICS"] = 1
except Exception as e:  # no Pango: GRUB and Plymouth fall back to their own fonts
    sizes["TEXTPICS"] = 0
    print("  (text pictures skipped:", e, ")")

# the title box fits its text
if sizes.get("TT_W"):
    LBW = max(LBW, sizes["TT_W"] + E("FS", 20))
sizes["LBW"] = LBW

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
# plain dark picture, used instead of Debian's blue GRUB background
png(g / "bg.png", 16, 16, lambda x, y: lo)
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

(g / "sizes.sh").write_text("".join(f"{k}={shlex.quote(str(v))}\n" for k, v in sizes.items()))
