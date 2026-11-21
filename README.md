# Glyph

A light, text-first desktop for **Debian 13**, built from existing open-source parts.

- **Text first:** letter tiles and words, no logos or icon packs.
- **One look everywhere:** IBM Plex Mono, square windows and the Glyph colours (Dark, OLED black or Light, with ten system colours). One settings file themes all of it.
- **Light:** labwc (Wayland) with a few small programs, instead of a full desktop environment.

![Glyph step 1: labwc with the Glyph theme](docs/step1-labwc.png)

> **Status: step 1 of 6.** You get the window manager with the Glyph look as an extra session next to your current desktop. The taskbar, start menu and the rest come next. See [docs/ROADMAP.md](docs/ROADMAP.md).

## Try it (next to KDE, GNOME or XFCE)

This is safe. Your current desktop is not changed, and at the login screen you choose which one to start.

```sh
sudo apt install git
git clone https://github.com/DRetro83/glyph
cd glyph
./install.sh --check   # optional: only shows what it would do
./install.sh
```

Then log out. At the login screen, pick **Glyph** in the session list (in SDDM it is bottom left) and sign in.

| Do this | How |
|---|---|
| Open the desktop menu | right-click the desktop, or Ctrl+Alt+M |
| Open the terminal | Ctrl+Alt+T |
| Open Files | Super+E |
| Switch windows | Alt+Tab (or Alt+Q) |
| Put a window on the left / right half | Super+← / → (or Ctrl+Alt+← / →), or drag it to the edge |
| Maximize a window | Super+↑, or drag it to the top |
| Close a window | Ctrl+Alt+W or Alt+F4 |
| Go to workspace 1–4 | Ctrl+Alt+1 … 4 |
| Move a window to workspace 1–4 | Shift+Ctrl+Alt+1 … 4 |
| Change the look | right-click the desktop → Look |
| Leave Glyph | right-click the desktop → Log out |

## Change the look

```sh
glyph-theme --mode dark      # dark | oled | light
glyph-theme --colour amber   # tan, light-tan, cream, amber, olive, green, rose, blue, dark-blue, dark-tan, or #rrggbb
glyph-theme --print          # show the palette
```

Your choice is kept in `~/.config/glyph/theme.conf`.

## Update

```sh
glyph-update
```

This gets the newest Glyph from GitHub and installs it. Your own look is kept, and old settings get a backup.

## Remove

```sh
./uninstall.sh             # removes Glyph, keeps the packages
./uninstall.sh --packages  # also removes labwc, swaybg ...
```

## What goes where

| Path | What |
|---|---|
| `~/.config/glyph/labwc/` | the Glyph window manager settings (only used in the Glyph session) |
| `~/.config/glyph/theme.conf` | your mode and colour |
| `~/.local/share/themes/Glyph/` | the theme that glyph-theme makes |
| `/usr/local/bin/glyph-*` | glyph-session, glyph-theme, glyph-update |
| `/usr/share/wayland-sessions/glyph.desktop` | the entry on the login screen |

## Licence

GPL-3.0. IBM Plex is under the SIL Open Font License, labwc under GPL-2.0.
