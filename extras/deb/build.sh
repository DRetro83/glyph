#!/usr/bin/env bash
# Builds glyph-desktop_<version>_all.deb: Glyph as one Debian package.
#   extras/deb/build.sh [OUTDIR]
# Everything goes where Debian packages belong (/usr/bin, /usr/lib/glyph,
# /usr/share/glyph). Each person gets their own settings at their first
# Glyph sign-in (glyph-setup-user), so the package needs no user.
# ./install.sh stays the way to run Glyph from a git folder (in /usr/local).
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=$(realpath -m "${1:-dist}")
VER=$(cat VERSION)
PKG=$(mktemp -d)
trap 'rm -rf "$PKG"' EXIT

# the packages Glyph needs: the same list as install.sh (one place to keep it)
DEPS=$(sed -n '/^PACKAGES=(/,/^)/p' install.sh | sed '1d;$d' | sed 's/#.*//' | tr -s ' \n' '\n' | grep -v -e '^$' -e '^labwc$' | sort -u | paste -sd, | sed 's/,/, /g')

# programs
install -d "$PKG/usr/bin" "$PKG/usr/lib/glyph" "$PKG/usr/share/glyph/lang" \
  "$PKG/usr/share/glyph/config/labwc" "$PKG/usr/share/glyph/config/waybar" \
  "$PKG/usr/share/glyph/share/applications" "$PKG/usr/share/glyph/share/xdg-desktop-portal" \
  "$PKG/usr/share/wayland-sessions" "$PKG/usr/share/polkit-1/actions" "$PKG/usr/share/doc/glyph-desktop"
for f in bin/glyph-*; do install -m 755 "$f" "$PKG/usr/bin/"; done
install -m 644 bin/glyph_lang.py "$PKG/usr/lib/glyph/"
install -m 755 share/glyph-apt "$PKG/usr/lib/glyph/"
# the polkit rule points at the helper's real place
sed 's|/usr/local/lib/glyph/glyph-apt|/usr/lib/glyph/glyph-apt|' share/polkit/org.glyph.apt.policy \
  > "$PKG/usr/share/polkit-1/actions/org.glyph.apt.policy"
sed 's|/usr/local/bin/glyph-session|/usr/bin/glyph-session|' share/wayland-sessions/glyph.desktop \
  > "$PKG/usr/share/wayland-sessions/glyph.desktop"

# what every person gets at their first Glyph sign-in
install -m 644 share/lang/*.txt "$PKG/usr/share/glyph/lang/"
install -m 644 config/labwc/{rc.xml,menu.xml,autostart,environment} "$PKG/usr/share/glyph/config/labwc/"
install -m 644 config/waybar/config.jsonc "$PKG/usr/share/glyph/config/waybar/"
install -m 644 share/applications/glyph-*.desktop "$PKG/usr/share/glyph/share/applications/"
install -m 644 share/xdg-desktop-portal/glyph-portals.conf "$PKG/usr/share/glyph/share/xdg-desktop-portal/"

# documentation (Debian wants the licence and changelog here)
install -m 644 README.md "$PKG/usr/share/doc/glyph-desktop/"
[[ -f LICENSE ]] && install -m 644 LICENSE "$PKG/usr/share/doc/glyph-desktop/copyright"
gzip -9n < CHANGELOG.md > "$PKG/usr/share/doc/glyph-desktop/changelog.gz"

# no compiled Python in the package
find "$PKG" -name __pycache__ -prune -exec rm -rf {} +

install -d "$PKG/DEBIAN"
SIZE=$(du -sk --exclude=DEBIAN "$PKG" | cut -f1)
cat > "$PKG/DEBIAN/control" <<EOF
Package: glyph-desktop
Version: $VER
Architecture: all
Maintainer: DRetro83 <DRetro83@users.noreply.github.com>
Installed-Size: $SIZE
Section: x11
Priority: optional
Homepage: https://github.com/DRetro83/glyph
Depends: labwc (>= 0.8.3-1+glyph3) | labwc (>= 0.8.3), $DEPS
Recommends: ddcutil, upower, cliphist, gtklock-playerctl-module
Description: Glyph, a calm text-first desktop for Debian
 A complete desktop built from small parts: labwc windows, a taskbar,
 start menu, quick settings, Settings, Files, Music, Software and more,
 all in one look (IBM Plex Mono, ten system colours, dark, OLED or light).
 .
 Pick "Glyph" on the login screen. Each person gets their own Glyph
 settings the first time they sign in.
EOF

cat > "$PKG/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ] && [ -x /usr/local/bin/glyph-theme ]; then
  echo "glyph-desktop: an older Glyph from ./install.sh is still in /usr/local." >&2
  echo "glyph-desktop: remove it with ./uninstall.sh (your settings stay) so only this one is used." >&2
fi
exit 0
EOF
chmod 755 "$PKG/DEBIAN/postinst"

mkdir -p "$OUT"
DEB="$OUT/glyph-desktop_${VER}_all.deb"
dpkg-deb --root-owner-group --build "$PKG" "$DEB" >/dev/null
echo "$DEB"
