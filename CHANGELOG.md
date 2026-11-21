# Changelog

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
