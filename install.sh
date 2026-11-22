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
(( CHECK )) || flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
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

# 2. your Glyph settings (old ones are kept as a backup)
if [[ -d "$GLYPH_CONF/labwc" ]] && (( ! CHECK )); then
  BK="$GLYPH_CONF/labwc.bak-$(date +%Y%m%d-%H%M%S)"
  cp -a "$GLYPH_CONF/labwc" "$BK"
  ok "old settings saved in $BK"
fi
run mkdir -p "$GLYPH_CONF/labwc"
run cp "$HERE"/config/labwc/{rc.xml,menu.xml,autostart,environment} "$GLYPH_CONF/labwc/"
# keep your mouse and touchpad choices (Settings -> Mouse & touchpad) from the backup
if [[ -n "${BK:-}" && -f "$BK/rc.xml" ]] && (( ! CHECK )); then
  python3 - "$BK/rc.xml" "$GLYPH_CONF/labwc/rc.xml" <<'PY' || true
import re, sys
old, new = open(sys.argv[1]).read(), open(sys.argv[2]).read()
m = re.search(r"<libinput>.*?</libinput>", old, re.S)
if m:
    new = re.sub(r"<libinput>.*?</libinput>", lambda _: m.group(0), new, count=1, flags=re.S)
    open(sys.argv[2], "w").write(new)
PY
fi
run mkdir -p "$GLYPH_CONF/waybar"
run cp "$HERE/config/waybar/config.jsonc" "$GLYPH_CONF/waybar/"
(( CHECK )) || "$HERE/bin/glyph-bar" >/dev/null 2>&1 || true   # keep your taskbar choice (Settings -> Taskbar)

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
# the Glyph mouse pointer, in your colour and size (Settings -> Mouse & touchpad)
if (( ! CHECK )); then
  CC=$(sed -n 's/^cursor_colour=//p' "$GLYPH_CONF/glyph.conf" 2>/dev/null); CC=${CC:-#e6dac4}
  CS=$(sed -n 's/^cursor_size=//p' "$GLYPH_CONF/glyph.conf" 2>/dev/null); CS=${CS:-24}
  sed -i "s/^XCURSOR_SIZE=.*/XCURSOR_SIZE=$CS/" "$GLYPH_CONF/labwc/environment"
  "$HERE/bin/glyph-cursors" "$CC" "$CS" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-theme Glyph 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-size "$CS" 2>/dev/null || true
fi
ok "settings in $GLYPH_CONF/labwc"

# 3. programs and the session entry for the login screen
run sudo install -m 755 "$HERE"/bin/glyph-* /usr/local/bin/
run sudo install -m 644 "$HERE/share/wayland-sessions/glyph.desktop" /usr/share/wayland-sessions/glyph.desktop
run mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
run cp "$HERE"/share/applications/glyph-*.desktop "${XDG_DATA_HOME:-$HOME/.local/share}/applications/"
# Glyph's own Files and Music open folders and songs, only in the Glyph session
# (KDE keeps Dolphin and its own player: this file is read only when the desktop is Glyph)
if (( ! CHECK )) && [[ ! -f "$CONF/glyph-mimeapps.list" ]]; then   # keep your choices (Settings -> Default apps)
  cat > "$CONF/glyph-mimeapps.list" <<'MIME'
[Default Applications]
inode/directory=glyph-files.desktop
audio/mpeg=glyph-music.desktop
audio/flac=glyph-music.desktop
audio/x-flac=glyph-music.desktop
audio/ogg=glyph-music.desktop
audio/x-vorbis+ogg=glyph-music.desktop
audio/opus=glyph-music.desktop
audio/mp4=glyph-music.desktop
audio/x-m4a=glyph-music.desktop
audio/aac=glyph-music.desktop
audio/x-wav=glyph-music.desktop
audio/wav=glyph-music.desktop
MIME
fi
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
