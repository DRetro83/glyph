#!/usr/bin/env bash
# Glyph - install as an extra session next to KDE (or GNOME, XFCE)
#
# Safe: nothing in KDE is changed. At the login screen you choose
# "Plasma" or "Glyph". Undo everything with ./uninstall.sh
#
# Usage:  ./install.sh          install or update
#         ./install.sh --check  only show what would happen
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
GLYPH_CONF="$CONF/glyph"
CHECK=0
[[ "${1:-}" == "--check" ]] && CHECK=1

PACKAGES=(
  labwc            # window manager (Wayland)
  foot             # terminal
  swaybg           # background
  fonts-ibm-plex   # the Glyph font
  thunar           # files
  mousepad         # text editor
  xwayland         # older X11 apps
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk   # screenshots, file pickers
  librsvg2-common  # SVG title bar buttons
  brightnessctl    # brightness keys
  python3          # glyph-theme
  waybar           # taskbar
  fuzzel           # start menu and power menu
  mako-notifier libnotify-bin   # notifications
  swaylock swayidle             # lock screen, lock after 5 minutes
  grim slurp wl-clipboard       # screenshots
  wtype            # workspace buttons on the taskbar
  wireplumber network-manager   # volume and network on the taskbar
  xdg-user-dirs    # Pictures folder for screenshots
  python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1   # start menu, desktop, panels, Settings
  udisks2 bluez power-profiles-daemon   # drives, Bluetooth, power profiles
  wlr-randr wlsunset lxpolkit          # screen scale, night light, password prompts
  pavucontrol blueman                  # volume per app, Bluetooth pairing
  qt6ct qt5ct                          # Qt apps in the Glyph colours
)

say()  { printf '\033[1;33m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m !\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if (( CHECK )); then echo "    would run: $*"; else "$@"; fi; }

[[ $EUID -eq 0 ]] && die "Run this as your normal user, not as root. It asks for your password when needed."
command -v apt-get >/dev/null || die "This needs Debian (apt-get not found)."
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  [[ "${ID:-}" == "debian" && "${VERSION_ID:-}" == "13" ]] || say "Made for Debian 13. Found: ${PRETTY_NAME:-unknown}. Going on anyway."
fi

say "Glyph - installing next to your current desktop"
(( CHECK )) && say "CHECK MODE: nothing is changed"

# 1. packages
say "Installing packages (asks for your password)"
run sudo apt-get update
run sudo apt-get install -y "${PACKAGES[@]}"
ok "packages"

# 2. your Glyph settings (old ones are kept as a backup)
if [[ -d "$GLYPH_CONF/labwc" ]] && (( ! CHECK )); then
  BK="$GLYPH_CONF/labwc.bak-$(date +%Y%m%d-%H%M%S)"
  cp -a "$GLYPH_CONF/labwc" "$BK"
  ok "old settings saved in $BK"
fi
run mkdir -p "$GLYPH_CONF/labwc"
run cp "$HERE"/config/labwc/{rc.xml,menu.xml,autostart,environment} "$GLYPH_CONF/labwc/"
run mkdir -p "$GLYPH_CONF/waybar"
run cp "$HERE/config/waybar/config.jsonc" "$GLYPH_CONF/waybar/"

# keyboard layout: take the one Debian already uses
if [[ -r /etc/default/keyboard ]] && (( ! CHECK )); then
  . /etc/default/keyboard
  {
    [[ -n "${XKBLAYOUT:-}"  ]] && echo "XKB_DEFAULT_LAYOUT=$XKBLAYOUT"
    [[ -n "${XKBVARIANT:-}" ]] && echo "XKB_DEFAULT_VARIANT=$XKBVARIANT"
    [[ -n "${XKBOPTIONS:-}" ]] && echo "XKB_DEFAULT_OPTIONS=$XKBOPTIONS"
  } >> "$GLYPH_CONF/labwc/environment"
  ok "keyboard layout: ${XKBLAYOUT:-us}"
fi
ok "settings in $GLYPH_CONF/labwc"

# 3. programs and the session entry for the login screen
run sudo install -m 755 "$HERE"/bin/glyph-* /usr/local/bin/
run sudo install -m 644 "$HERE/share/wayland-sessions/glyph.desktop" /usr/share/wayland-sessions/glyph.desktop
run mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
run cp "$HERE/share/applications/glyph-settings.desktop" "${XDG_DATA_HOME:-$HOME/.local/share}/applications/"
run mkdir -p "$CONF/xdg-desktop-portal"
run cp "$HERE/share/xdg-desktop-portal/glyph-portals.conf" "$CONF/xdg-desktop-portal/"
ok "Glyph added to the login screen"

# 4. remember where the source is, for glyph-update
(( CHECK )) || echo "$HERE" > "$GLYPH_CONF/source"

# 5. build the look (dark, tan) unless you already chose one
run /usr/local/bin/glyph-theme
ok "theme"

echo
say "Done. Log out, pick \"Glyph\" in the session list at the login screen"
say "(bottom left in SDDM), and sign in. KDE stays as it is."
echo "    Super or Ctrl+Space = start menu.  Ctrl+Alt+T = terminal.  Ctrl+Alt+L = lock."
echo "    Undo everything: ./uninstall.sh"
