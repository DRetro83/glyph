# Changelog

## 0.9.7 · round Start, a bar without a gap · 2026-11-22

- Rounded corners: the start menu and the panels are round at the bottom too, with room for their shadow
- The taskbar takes a height that fits a fractional screen scale (125 %, 150 %), so no 1 px gap under it

## 0.9.6 · the taskbar follows the corners · 2026-11-22

- Rounded corners everywhere: the taskbar floats a little above the edge with round corners, every taskbar button follows the shape, and so do pop-up notifications and the lock screen

## 0.9.5 · corner shapes · 2026-11-22

- Window corners: Square, Rounded or Round ends (pill-shaped buttons and fields), plus the slider for how round

## 0.9.4 · corners on a slider · 2026-11-22

- Settings → Appearance → Window corners is a slider now: 0 (square) to 16 px, for windows, panels, buttons, tiles and cards

## 0.9.3 · layered panels, no icons · 2026-11-22

- Panels in layers like Start and Files: a lighter back, darker framed tiles and lists on it; the 0.9.2 colours are gone again
- Quick settings without icons: tiles are text only, the sliders have VOL / MUTE / LIGHT buttons, the footer is Settings · Lock · Power

## 0.9.2 · more colour · 2026-11-22

- Quick settings in more colours, like the prototype: every tile its own colour (Wi-Fi and Bluetooth blue, Do not disturb rose, Night light amber, power profile green / amber / rose), volume amber, brightness yellow, Lock blue, Power amber, the battery green / amber / rose, the sound device in use green
- Icons that an icon theme does not have (the Lock and Power squares) fall back to a look-alike

## 0.9.1 · Glyph in your language · 2026-11-22

- **Languages**: Settings → Language & region → GLYPH LANGUAGE. English stays the default; Dutch (Nederlands) comes with Glyph
- A language is one text file: `English text = translation`, one per line. Glyph's own files are in /usr/local/share/glyph/lang; your own lines go in ~/.config/glyph/lang/<code>.txt and win. Anything missing stays English
- Every Glyph app, the panels, the start menu and the desktop clock follow the chosen language

## 0.9.0 · the whole design, and more · 2026-11-22

**New apps**
- **System monitor** (Ctrl+Shift+Esc): processes with letter tiles (filled for apps with a window), sort, filter, My apps, End task / Kill; resources with CPU per core, memory, network and disk graphs; an htop-like CORES strip
- **Software**: apps by category (Browsers, Mail, Editing, Music & video, Backup, Games, Glyph) from Debian, Flathub, vivaldi.com and GitHub (Emu Vault, DBash); every app in Start with Open / Hide / Remove; updates with Update all; CORE apps marked
- **Disks**, **Calculator**, **Screenshot** window (screen or area, with a wait), **Welcome** at the first start (look, Wi-Fi, apps), **About**

**Taskbar and panels**
- Every open app of every workspace on the taskbar, its letter tile in the colour of its workspace; click goes there (labwc-glyph 3 + glyph-tasks)
- Workspace colours: each workspace its own colour, for the whole desktop
- ▦ N open windows panel, ♪ music button with Now playing, update count (● N) on SETTINGS
- Quick settings redesigned: tiles with icons, one list of details (one open at a time), sound output and microphone choice, Now playing card, sliders at the bottom
- Start menu and panels close when you click next to them; Start search also finds Settings pages and recent files
- Super+V clipboard history, Super+/ all shortcuts

**Settings**
- New pages: Taskbar, Notifications, Disks, Printers, Mobile network, Users (standard user or administrator), Language & region, Privacy, Default apps, Accessibility
- Appearance: shadows, window corners, text size, start menu size, scanlines; Mouse: pointer colour and size, left-handed; Display: night light

**Under the hood**
- Lock screen like the design (gtklock); notifications start reliably (glyph-notifyd)
- Log out, restart and shut down close apps politely first, so unsaved work can be saved
- USB sounds with Open, low battery warnings and sleep at 5 %
- Hard window shadows and a taskbar per workspace in labwc-glyph; Glyph's own Glyph pointer theme
- "Show in folder" from browsers opens Glyph Files; colour changes no longer close apps
- Glyph no longer changes LibreOffice

## 0.5.0 · own Files and Music · 2026-11-21

- **Files** (glyph-files): the file manager from the design: SIDE, back/forward/up, path, search, LIST/GRID, places, devices with eject, network, trash, copy/cut/paste, rename, new folder, terminal here. Opens folders in the Glyph session; Thunar stays for advanced work
- **Music** (glyph-music): the player from the design with a real 10-band equalizer, preamp, curve and presets, playlist, shuffle and repeat
- **Quick settings**: every section folds open and shut; volume at the bottom
- START as an amber frame and the bottom-left corner mark, as in the design

## 0.4.0 · closer to the design · 2026-11-21

- Own **start menu** (glyph-start): categories, letter tiles, favourites, search, power; KDE helper apps hidden
- Own **desktop** (glyph-desk): scan lines, corner marks, big clock with date, uptime, battery, power and network
- **Taskbar** as in the design: filled START, lit workspace, windows with letter tile and short name
- **Title bars** with fine stripes and the boxed "■ TITLE", via labwc-glyph (Debian's labwc with a small patch)

## 0.3.0 · steps 4, 5 and 6 · 2026-11-21

- **Quick settings** (SETTINGS ▴ on the taskbar): Wi-Fi with a network list and password, Bluetooth, mobile data, airplane mode, do not disturb, night light, volume, brightness, power profile, battery and USB drives (open, mount, eject)
- **Calendar** (click the clock): month view, today, and your recent notifications
- **Settings window**: Appearance, Background, Display (scale), Sound, Keyboard, Mouse & touchpad, Power & lock, Network, Bluetooth, Date & time, Updates, About
- **Apps in the Glyph look**: a GTK 3 and 4 theme (Files, text editor, most apps), Qt colours via qt6ct, terminal colours, an editor colour scheme, and Firefox and Vivaldi in your colours. All of it only in the Glyph session, so KDE keeps its own look
- **Start-up look** (optional, `extras/boot/install-boot.sh`): GRUB menu, Plymouth start-up screen and an SDDM sign-in screen, in your colours, with `--remove` to undo
- Background picture or colour, lock time and screen scale are kept between sessions
- Password prompts for system changes (lxpolkit)

## 0.2.0 · steps 2 and 3 · 2026-11-21

- **Taskbar** (waybar) at the bottom: ▸ START, workspaces 1–4, open windows as text, volume, network, battery, clock and POWER
- **Start menu** (fuzzel): tap Super or press Ctrl+Space, type to search, no icons
- **Power menu**: Lock, Log out, Restart, Shut down, Suspend, with a check before log out, restart and shut down
- **Notifications** (mako) at the top right, urgent ones with a rose border
- **Lock screen** (swaylock): Ctrl+Alt+L, and on its own after 5 minutes and before sleep
- **Screenshots**: Print for the whole screen, Shift+Print or Ctrl+Alt+P for an area, saved in Pictures
- glyph-theme now also colours the taskbar, menus, notifications and lock screen

## 0.1.0 · step 1 · 2026-11-21

- Glyph as an extra session next to KDE, GNOME or XFCE (`install.sh`, `uninstall.sh`)
- labwc with the Glyph look: coloured title bars, square **_ □ ×** buttons, IBM Plex Mono, no window icons
- Snapping to the left, right and top, with an amber preview
- Four workspaces, keyboard shortcuts with Super and with Ctrl+Alt
- Right-click menu on the desktop, with Look (Dark, OLED, Light and the system colours)
- `glyph-theme`: one settings file for the whole look, applied at once
- `glyph-update`: update from GitHub
