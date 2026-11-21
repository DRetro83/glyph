# Glyph roadmap

The design is the HTML prototype ("Glyph desktop"). The real desktop is built in six steps, each one tested before the next.

| Step | What | Parts | Status |
|---|---|---|---|
| 1 | **Windows**: title bars, buttons, snapping, workspaces, right-click menu, the Glyph colours | labwc, glyph-theme | ✅ done |
| 2 | **Taskbar** at the bottom: START, workspaces, open windows, tray, clock, power | waybar | next |
| 3 | **Start menu, notifications, lock screen** | fuzzel or wofi, mako, swaylock or gtklock | |
| 4 | **Quick settings and panels**: Wi-Fi, Bluetooth, volume, brightness, power profile, drives | eww, NetworkManager, BlueZ, PipeWire, udisks2 | |
| 5 | **Start-up and sign-in**: boot menu, splash, login screen | GRUB theme, Plymouth, greetd + tuigreet | |
| 6 | **Apps in the Glyph look**: GTK and Qt themes, cursors, Firefox, Vivaldi, GIMP, LibreOffice … | gtk.css, Kvantum, userChrome.css, glyph-theme modules | |

## Later

- **Settings → Accounts**: sign in to Google, Outlook or another mail account once, and Claws Mail plus the calendar (vdirsyncer + khal) are set up for you.
- **Glyph ISO**: a live USB image made with Debian's live-build, built automatically on GitHub.
- **Clean install**: a minimal Debian 13 with only Glyph, without KDE.

## Notes on labwc

- A title bar can be a solid colour or a top-to-bottom gradient (Vertical or SplitVertical). The fine stripes of the prototype cannot be drawn by labwc, so Glyph uses solid title bars.
- Debian 13 ships labwc 0.8. labwc 0.7 looks for themes in `themes/<name>/openbox-3/` and 0.8 in `themes/<name>/labwc/`. glyph-theme fills both.
