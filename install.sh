#!/usr/bin/env bash
# Glyph - install as an extra session next to KDE (or GNOME, XFCE)
#
# Safe: nothing in KDE is changed. At the login screen you choose
# "Plasma" or "Glyph". Undo everything with ./uninstall.sh
#
# Usage:  ./install.sh          install or update
#         ./install.sh --check  only show what would happen
#         ./install.sh --plain-titlebars   keep Debian's own labwc (no stripes)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
GLYPH_CONF="$CONF/glyph"
CHECK=0
PLAIN=0
for a in "$@"; do
  case "$a" in
    --check) CHECK=1 ;;
    --plain-titlebars) PLAIN=1 ;;
  esac
done
LABWC_GLYPH_URL="https://github.com/DRetro83/glyph/releases/download/labwc-glyph/labwc_0.8.3-1%2Bglyph3_amd64.deb"

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
  gtklock swaylock swayidle     # lock screen (gtklock, swaylock as fallback), lock after 5 minutes
  grim slurp wl-clipboard       # screenshots
  wtype            # workspace buttons on the taskbar
  wireplumber network-manager   # volume and network on the taskbar
  xdg-user-dirs    # Pictures folder for screenshots
  python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1   # start menu, desktop, panels, Settings
  udisks2 gvfs bluez power-profiles-daemon   # drives, trash, Bluetooth, power profiles
  wlr-randr wlsunset lxpolkit          # screen scale, night light, password prompts
  pavucontrol blueman                  # volume per app, Bluetooth pairing
  qt6ct qt5ct                          # Qt apps in the Glyph colours
  xfce4-terminal                       # terminal with a right-click menu (foot stays as the light one)
  mpv ristretto atril mousepad xarchiver  # video, pictures, PDF, text, zip/rar/7z
  firefox-esr flatpak                     # a browser always; Flatpak for Steam, Heroic and more
  fonts-noto-core fonts-noto-color-emoji  # letters for every language, and emoji
  playerctl                               # music buttons on the taskbar
  pulseaudio-utils                        # pactl: choose speakers / headphones / HDMI and microphone
  gir1.2-gstreamer-1.0 gir1.2-gst-plugins-base-1.0 gstreamer1.0-plugins-good gstreamer1.0-plugins-base gstreamer1.0-libav   # Glyph music player
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
# the Glyph font (IBM Plex) is in Debian's "contrib" section, which a fresh
# Debian 13 does not always have switched on: switch it on if needed
if (( ! CHECK )) && ! apt-cache show fonts-ibm-plex >/dev/null 2>&1; then
  say "Switching on Debian's \"contrib\" section for the IBM Plex font"
  if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    sudo sed -i -E '/^Components:/{/contrib/!s/$/ contrib/}' /etc/apt/sources.list.d/debian.sources
  fi
  if [[ -f /etc/apt/sources.list ]]; then
    sudo sed -i -E '/^deb(-src)? .*debian/{/contrib/!s/ main( |$)/ main contrib\1/}' /etc/apt/sources.list
  fi
  sudo apt-get update
fi
if (( ! CHECK )) && ! apt-cache show fonts-ibm-plex >/dev/null 2>&1; then
  say "(IBM Plex not found; Glyph uses DejaVu Sans Mono instead)"
  PACKAGES=("${PACKAGES[@]/fonts-ibm-plex/fonts-dejavu-core}")
fi
run sudo apt-get install -y "${PACKAGES[@]}"
# optional helpers that not every Debian has: monitor brightness, batteries,
# clipboard history, music on the lock screen
for extra in ddcutil upower cliphist gtklock-playerctl-module; do
  run sudo apt-get install -y "$extra" >/dev/null 2>&1 || say "($extra not available, skipped)"
done
if command -v ddcutil >/dev/null 2>&1 && (( ! CHECK )); then
  # monitor brightness over the cable needs the i2c-dev module
  echo i2c-dev | sudo tee /etc/modules-load.d/glyph-i2c.conf >/dev/null
  sudo modprobe i2c-dev 2>/dev/null || true
fi
ok "packages"

# 1b. labwc-glyph: Debian's labwc with Glyph's small titlebar patch (stripes and
#     the boxed "■ TITLE"). Built on GitHub from Debian's own source. KDE does
#     not use labwc, so nothing else changes. Skip with --plain-titlebars.
if (( ! PLAIN )) && [[ "$(dpkg --print-architecture)" == "amd64" ]]; then
  have=$(dpkg-query -W -f='${Version}' labwc 2>/dev/null || true)
  if [[ "$have" == "0.8.3-1" || "$have" == "0.8.3-1+glyph1" || "$have" == "0.8.3-1+glyph2" ]]; then
    TMPD=$(mktemp -d)
    if run python3 -c 'import sys, urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])' \
         "$LABWC_GLYPH_URL" "$TMPD/labwc_0.8.3-1+glyph3_amd64.deb"; then
      run sudo apt-get install -y "$TMPD/labwc_0.8.3-1+glyph3_amd64.deb" && ok "labwc-glyph (striped title bars)"
    else
      say "Could not download labwc-glyph; keeping Debian's labwc (plain title bars)."
    fi
    rm -rf "$TMPD"
  elif [[ "$have" == *glyph* ]]; then
    ok "labwc-glyph already installed"
  else
    say "labwc $have is not the version the Glyph patch was made for; keeping it (plain title bars)."
  fi
fi

# 2. programs, the files every user gets, and the session entry for the login screen
run sudo install -m 755 "$HERE"/bin/glyph-* /usr/local/bin/
run sudo install -D -m 644 "$HERE/bin/glyph_lang.py" /usr/local/lib/glyph/glyph_lang.py
# apt for Software and Welcome, with its own short sentence in the password box
run sudo install -D -m 755 "$HERE/share/glyph-apt" /usr/local/lib/glyph/glyph-apt
run sudo install -D -m 644 "$HERE/share/polkit/org.glyph.apt.policy" /usr/share/polkit-1/actions/org.glyph.apt.policy
run sudo mkdir -p /usr/local/share/glyph/lang /usr/local/share/glyph/config/labwc /usr/local/share/glyph/config/waybar \
  /usr/local/share/glyph/share/applications /usr/local/share/glyph/share/xdg-desktop-portal
run sudo install -m 644 "$HERE"/share/lang/*.txt /usr/local/share/glyph/lang/
# a copy for everyone on this computer: a second user gets Glyph set up at their first Glyph sign-in
run sudo install -m 644 "$HERE"/config/labwc/{rc.xml,menu.xml,autostart,environment} /usr/local/share/glyph/config/labwc/
run sudo install -m 644 "$HERE/config/waybar/config.jsonc" /usr/local/share/glyph/config/waybar/
run sudo install -m 644 "$HERE"/share/applications/glyph-*.desktop /usr/local/share/glyph/share/applications/
run sudo install -m 644 "$HERE/share/xdg-desktop-portal/glyph-portals.conf" /usr/local/share/glyph/share/xdg-desktop-portal/
run sudo install -m 644 "$HERE/share/wayland-sessions/glyph.desktop" /usr/share/wayland-sessions/glyph.desktop
ok "Glyph added to the login screen"

# 3. your Glyph settings (your own choices are kept, old labwc settings get a backup)
run "$HERE/bin/glyph-setup-user" "$HERE"
[[ -r /etc/default/keyboard ]] && (( ! CHECK )) && ok "keyboard layout: $(. /etc/default/keyboard; echo "${XKBLAYOUT:-us}")"
ok "settings in $GLYPH_CONF"

# 4. remember where the source is, for glyph-update
(( CHECK )) || echo "$HERE" > "$GLYPH_CONF/source"

echo
say "Done. Log out, pick \"Glyph\" in the session list at the login screen"
say "(bottom left in SDDM), and sign in. KDE stays as it is."
echo "    Super or Ctrl+Space = start menu.  Ctrl+Alt+T = terminal.  Ctrl+Alt+L = lock."
echo "    Undo everything: ./uninstall.sh"
