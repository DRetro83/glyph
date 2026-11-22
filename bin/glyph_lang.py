"""glyph_lang - Glyph in another language, from a plain text file.

Glyph is written in English. A language is one text file, for example nl.txt:

    # name: Nederlands
    Settings = Instellingen
    Shut down = Afsluiten

Each line: the English text, " = ", the translation. Lines starting with #
are notes. Anything not in the file simply stays English.

Where Glyph looks (the later one wins, so you can fix or add lines yourself):
    /usr/local/share/glyph/lang/<code>.txt     (comes with Glyph)
    ~/.config/glyph/lang/<code>.txt            (your own)
The language is chosen in Settings -> Language & region (lang=<code> in
~/.config/glyph/glyph.conf). To make a new language, copy nl.txt, give it
a new name (de.txt, fr.txt…) and translate the right-hand side.

Apps call hook_gtk() once after importing Gtk: every label, button,
placeholder and window title is then looked up as it is shown.
"""
import os
import re
from pathlib import Path

CONF = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "glyph"
HERE = Path(__file__).resolve().parent
DIRS = [Path("/usr/local/share/glyph/lang"), HERE.parent / "share" / "lang", CONF / "lang"]

_T, _TL = {}, {}


def current():
    try:
        for line in (CONF / "glyph.conf").read_text().splitlines():
            if line.startswith("lang="):
                return line.split("=", 1)[1].strip() or "en"
    except Exception:
        pass
    return "en"


def languages():
    """[(code, name)] of every language file found, English first."""
    out = {"en": "English"}
    for d in DIRS:
        for f in sorted(d.glob("*.txt")) if d.is_dir() else []:
            name = f.stem
            try:
                first = f.read_text(errors="ignore").splitlines()[0]
                if first.lower().startswith("# name:"):
                    name = first.split(":", 1)[1].strip()
            except Exception:
                pass
            out[f.stem] = name
    return list(out.items())


def load(code=None):
    code = code or current()
    _T.clear()
    _TL.clear()
    if code == "en":
        return
    for d in DIRS:
        f = d / f"{code}.txt"
        if not f.exists():
            continue
        for line in f.read_text(errors="ignore").splitlines():
            if not line.strip() or line.lstrip().startswith("#") or " = " not in line:
                continue
            k, v = line.split(" = ", 1)
            k, v = k.strip(), v.strip()
            if k and v:
                _T[k] = v
    for k, v in _T.items():
        _TL[k.lower()] = v


_EDGE = re.compile(r"^([^\w(]*)(.*?)([\s▴▾▸›…:.]*)$", re.S)


def tr(s):
    """The text in the chosen language, or the text itself."""
    if not _T or not isinstance(s, str) or not s.strip():
        return s
    if s in _T:
        return _T[s]
    if "<" in s and ">" in s and "</" in s:
        # Pango markup: translate the words between the tags
        return re.sub(r">([^<>]+)<", lambda m: ">" + tr(m.group(1)) + "<", ">" + s + "<")[1:-1]
    if s in _T:
        return _T[s]
    m = _EDGE.match(s)
    pre, core, post = m.group(1), m.group(2), m.group(3)
    if core in _T:
        return pre + _T[core] + post
    if core.lower() in _TL:
        v = _TL[core.lower()]
        return pre + (v.upper() if core.isupper() else v) + post
    if " · " in s:
        return " · ".join(tr(x) for x in s.split(" · "))
    return s


def hook_gtk():
    """Translate GTK texts as they are set: labels, buttons, menu items, placeholders, titles, columns."""
    load()
    if not _T:
        return
    from gi.repository import Gtk

    def wrap_init(cls, keys, first_arg=True):
        orig = cls.__init__

        def init(self, *a, **k):
            for key in keys:
                if isinstance(k.get(key), str):
                    k[key] = tr(k[key])
            if first_arg and a and isinstance(a[0], str):
                a = (tr(a[0]),) + a[1:]
            orig(self, *a, **k)
        cls.__init__ = init

    def wrap(cls, name):
        orig = getattr(cls, name)

        def f(self, text, *a):
            return orig(self, tr(text) if isinstance(text, str) else text, *a)
        setattr(cls, name, f)

    wrap_init(Gtk.Label, ["label"])
    wrap_init(Gtk.Button, ["label"], first_arg=False)
    wrap_init(Gtk.MenuItem, ["label"], first_arg=False)
    wrap_init(Gtk.TreeViewColumn, ["title"])
    wrap_init(Gtk.Window, ["title"], first_arg=False)
    for cls, names in ((Gtk.Label, ("set_text", "set_label")), (Gtk.Button, ("set_label",)),
                       (Gtk.MenuItem, ("set_label",)), (Gtk.Entry, ("set_placeholder_text",)),
                       (Gtk.Window, ("set_title",)), (Gtk.TreeViewColumn, ("set_title",)),
                       (Gtk.Widget, ("set_tooltip_text",))):
        for n in names:
            wrap(cls, n)
    wrap(Gtk.Label, "set_markup")


if __name__ == "__main__":
    # for shell scripts:  python3 /usr/local/lib/glyph/glyph_lang.py "Text"  ->  the text in your language
    import sys
    load()
    print(tr(" ".join(sys.argv[1:])))
