# Glyph roadmap

The design is the HTML prototype ("Glyph desktop"). The real desktop is built in six steps, each one tested before the next.

| Step | What | Parts | Status |
|---|---|---|---|
| 1 | **Windows**: title bars, buttons, snapping, workspaces, right-click menu, the Glyph colours | labwc, glyph-theme | ✅ done |
| 2 | **Taskbar** at the bottom: START, workspaces, open windows, volume, network, battery, clock, power | waybar | ✅ done |
| 3 | **Start menu, power menu, notifications, lock screen, screenshots** | fuzzel, mako, swaylock + swayidle, grim + slurp | ✅ done |
| 4 | **Quick settings, calendar, Settings window** | glyph-panel and glyph-settings (Python, GTK3, gtk-layer-shell), NetworkManager, BlueZ, PipeWire, udisks2 | ✅ done |
| 5 | **Start-up and sign-in** (optional): boot menu, start-up screen, sign-in screen | GRUB theme, Plymouth script theme, SDDM theme (`extras/boot`) | ✅ done |
| 6 | **Apps in the Glyph look**: GTK 3/4, Qt, terminal, editor, Firefox, Vivaldi | glyph-theme (gtk.css, qt6ct, foot, GtkSourceView, userChrome.css) | ✅ done |

**Now:** test on a real Debian 13 PC, fix what shows up, then version 1.0.

## Later

- **More apps in the Glyph look**: GIMP, Inkscape, LibreOffice, VLC and Heroic mostly follow the GTK/Qt theme already; their own extra touches come after the real-PC test.
- **Settings → Accounts**: sign in to Google, Outlook or another mail account once, and Claws Mail plus the calendar (vdirsyncer + khal) are set up for you.
- **Glyph ISO**: a live USB image made with Debian's live-build, built automatically on GitHub.
- **Clean install**: a minimal Debian 13 with only Glyph, without KDE.

## Notes on labwc

- A title bar can be a solid colour or a top-to-bottom gradient (Vertical or SplitVertical). The fine stripes of the prototype cannot be drawn by labwc, so Glyph uses solid title bars.
- Debian 13 ships labwc 0.8. labwc 0.7 looks for themes in `themes/<name>/openbox-3/` and 0.8 in `themes/<name>/labwc/`. glyph-theme fills both.

## Notes on steps 2 and 3

- **Workspaces on the taskbar:** labwc 0.8 cannot tell waybar which workspace is active, so the buttons 1–4 switch workspace but do not light up. Newer labwc versions add this, and Glyph will use it when Debian has them.
- **Start menu:** fuzzel lists every app by name, without icons. The categories and favourites of the prototype need a bigger menu; that comes with the panels in step 4.
- **Lock screen:** swaylock shows the Glyph colours and a ring. The clock and media controls of the prototype need gtklock, which can come later.
- **Tray:** waybar shows tray icons of apps that have one (for example Steam or Discord). Glyph's own Wi-Fi, Bluetooth and sound panels come in step 4.

## Notes on steps 4, 5 and 6

- eww is not in Debian, so the quick settings, calendar and Settings window are small Python GTK3 programs (python3-gi and gtk-layer-shell are in Debian).
- The apps theme is only switched on inside the Glyph session (`GTK_THEME=Glyph`, `QT_QPA_PLATFORMTHEME=qt6ct` in the session environment), so KDE keeps its own look.
- SDDM is shared with KDE, which is why the start-up look is a separate, optional step with `--remove`. greetd is planned for the clean install without KDE.
- The Plymouth theme needs the `splash` option on the kernel line; install-boot.sh adds it through `/etc/default/grub.d/glyph.cfg`.
