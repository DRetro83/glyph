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

if [[ "${1:-}" == "--packages" ]]; then
  echo ":: Removing the packages Glyph added"
  sudo apt-get remove -y labwc swaybg xdg-desktop-portal-wlr brightnessctl waybar fuzzel mako-notifier swaylock swayidle wtype
  echo "   (foot, thunar, mousepad and fonts-ibm-plex are kept: you may use them in KDE too)"
fi
echo " ✓ Glyph is removed. Next login: pick Plasma."
