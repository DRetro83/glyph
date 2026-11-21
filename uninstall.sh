#!/usr/bin/env bash
# Glyph - remove the Glyph session. KDE and your files are not touched.
#
# Usage:  ./uninstall.sh            remove Glyph, keep the packages
#         ./uninstall.sh --packages also remove labwc, foot, swaybg ...
set -euo pipefail
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

[[ $EUID -eq 0 ]] && { echo "Run this as your normal user." >&2; exit 1; }

echo ":: Removing the Glyph session (asks for your password)"
sudo rm -f /usr/share/wayland-sessions/glyph.desktop /usr/local/bin/glyph-*
rm -rf "$CONF/glyph" "$DATA/themes/Glyph"
rm -f "$CONF/xdg-desktop-portal/glyph-portals.conf" "$DATA/applications/glyph-settings.desktop"
# app colours that glyph-theme made (only files that are ours)
rm -f "$DATA"/gtksourceview-*/styles/glyph.xml "$CONF/qt5ct/colors/Glyph.conf" "$CONF/qt6ct/colors/Glyph.conf"
for f in "$CONF/qt5ct/qt5ct.conf" "$CONF/qt6ct/qt6ct.conf"; do grep -qs "Glyph.conf" "$f" && rm -f "$f"; done
grep -qs "Glyph colours come from" "$CONF/foot/foot.ini" && rm -f "$CONF/foot/foot.ini"
for css in "$HOME"/.mozilla/firefox/*/chrome/userChrome.css; do head -c 8 "$css" 2>/dev/null | grep -q "glyph" && rm -f "$css"; done

# labwc-glyph back to Debian's own labwc
if dpkg-query -W -f='${Version}' labwc 2>/dev/null | grep -q glyph; then
  echo ":: Putting back Debian's own labwc"
  sudo apt-get install -y --allow-downgrades "labwc=0.8.3-1" || true
fi

if [[ "${1:-}" == "--packages" ]]; then
  echo ":: Removing the packages Glyph added"
  sudo apt-get remove -y labwc swaybg xdg-desktop-portal-wlr brightnessctl waybar fuzzel mako-notifier swaylock swayidle wtype
  echo "   (foot, thunar, mousepad and fonts-ibm-plex are kept: you may use them in KDE too)"
fi
echo " ✓ Glyph is removed. Next login: pick Plasma."
[ -d /usr/share/sddm/themes/glyph ] || [ -d /boot/grub/themes/glyph ] || [ -d /usr/share/plymouth/themes/glyph ] &&
  echo "   The Glyph start-up look is still on. Remove it with: extras/boot/install-boot.sh --remove"
exit 0
