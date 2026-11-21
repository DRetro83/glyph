#!/bin/sh
# Glyph start-up look: GRUB menu, Plymouth start-up screen and SDDM sign-in screen.
# This changes system files (it asks for your password) and also changes how
# KDE's sign-in screen looks, because SDDM is shared. Everything can be undone:
#
#   ./install-boot.sh              all three
#   ./install-boot.sh sddm grub    only these (sddm, grub, plymouth)
#   ./install-boot.sh --remove     back to how it was
#   ./install-boot.sh --check      show what would happen, change nothing
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
PAL="${XDG_CONFIG_HOME:-$HOME/.config}/glyph/palette.env"
STATE=/var/lib/glyph-boot
DRY=0; REMOVE=0; PARTS=""
for a in "$@"; do
  case "$a" in
    --check) DRY=1 ;; --remove) REMOVE=1 ;;
    sddm|grub|plymouth) PARTS="$PARTS $a" ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done
[ -n "$PARTS" ] || PARTS="sddm grub plymouth"
[ "$(id -u)" = 0 ] && { echo "Run this as yourself, not as root. It asks for your password when needed."; exit 1; }
run() { if [ $DRY = 1 ]; then echo "  would run: $*"; else "$@"; fi; }
# system tools live in /usr/sbin, which is not in a normal user's PATH on Debian
PATH="$PATH:/usr/sbin:/sbin"
has() { command -v "$1" >/dev/null 2>&1; }
want() { case " $PARTS " in *" $1 "*) return 0 ;; esac; return 1; }

if [ $REMOVE = 1 ]; then
  echo "Glyph start-up look: removing$PARTS"
  if want sddm; then run sudo rm -f /etc/sddm.conf.d/glyph.conf; run sudo rm -rf /usr/share/sddm/themes/glyph; fi
  if want plymouth && has plymouth-set-default-theme; then
    prev=$(cat $STATE/plymouth-before 2>/dev/null || echo bgrt)
    run sudo plymouth-set-default-theme -R "$prev" || true
    run sudo rm -rf /usr/share/plymouth/themes/glyph
  fi
  if want grub; then run sudo rm -f /etc/default/grub.d/glyph.cfg; run sudo rm -rf /boot/grub/themes/glyph; fi
  if want grub || want plymouth; then has update-grub && run sudo update-grub; fi
  echo "Done. The old look is back after a restart."
  exit 0
fi

[ -f "$PAL" ] || { echo "No Glyph colours yet: run ./install.sh first (it makes $PAL)."; exit 1; }
. "$PAL"
rgbf() { printf '%s' "$1" | sed 's/#//' | awk '{printf "%.3f, %.3f, %.3f", ("0x" substr($0,1,2))/255, ("0x" substr($0,3,2))/255, ("0x" substr($0,5,2))/255}'; }
hexdec() { printf '%d' "0x$1"; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/grub" "$TMP/plymouth" "$TMP/sddm"

echo "Glyph start-up look:$PARTS (colours from your Glyph look)"
pkgs=""
want sddm && ! has sddm && pkgs="$pkgs sddm"
want grub && ! has grub-mkfont && pkgs="$pkgs grub-common"
want plymouth && pkgs="$pkgs plymouth plymouth-label"   # label draws the text; apt skips what you have
[ -n "$pkgs" ] && run sudo apt-get install -y $pkgs
[ $DRY = 1 ] || sudo mkdir -p $STATE

python3 "$HERE/make-images.py" "$PAL" "$TMP/grub" "$TMP/plymouth"
chmod 755 "$TMP"/*   # SDDM and GRUB must be able to read the copies

if want sddm; then
  cp "$HERE"/sddm/glyph/* "$TMP/sddm/"
  sed -i "s/^lo=.*/lo=$GLYPH_LO/; s/^panel=.*/panel=$GLYPH_PANEL/; s/^view=.*/view=$GLYPH_VIEW/; s/^win=.*/win=$GLYPH_WIN/;
          s/^hov=.*/hov=$GLYPH_HOV/; s/^hi=.*/hi=$GLYPH_HI/; s/^dim=.*/dim=$GLYPH_DIM/; s/^title=.*/title=$GLYPH_TITLE/;
          s/^text=.*/text=$GLYPH_TEXT/; s/^amber=.*/amber=$GLYPH_AMBER/; s/^rose=.*/rose=$GLYPH_ROSE/; s/^tink=.*/tink=$GLYPH_TINK/" "$TMP/sddm/theme.conf"
  # newer SDDM runs Qt6 greeters only for themes that say so
  has sddm-greeter-qt6 && echo "QtVersion=6" >> "$TMP/sddm/metadata.desktop"
  echo "- SDDM sign-in screen (KDE's sign-in screen changes too)"
  run sudo rm -rf /usr/share/sddm/themes/glyph
  run sudo cp -r "$TMP/sddm" /usr/share/sddm/themes/glyph
  run sudo mkdir -p /etc/sddm.conf.d
  if [ $DRY = 0 ]; then printf '[Theme]\nCurrent=glyph\n' | sudo tee /etc/sddm.conf.d/glyph.conf >/dev/null; fi
fi

if want plymouth; then
  sed "s/@VIEW_RGB@/$(rgbf $GLYPH_VIEW)/g; s/@TAN_RGB@/$(rgbf $GLYPH_TAN)/g; s/@DIM_RGB@/$(rgbf $GLYPH_DIM)/g; s/@TEXT_RGB@/$(rgbf $GLYPH_TEXT)/g" \
    "$HERE/plymouth/glyph/glyph.script.in" > "$TMP/plymouth/glyph.script"
  cp "$HERE/plymouth/glyph/glyph.plymouth" "$TMP/plymouth/"
  echo "- Plymouth start-up screen"
  if [ $DRY = 0 ] && [ ! -f $STATE/plymouth-before ]; then sudo plymouth-set-default-theme 2>/dev/null | sudo tee $STATE/plymouth-before >/dev/null || true; fi
  run sudo rm -rf /usr/share/plymouth/themes/glyph
  run sudo cp -r "$TMP/plymouth" /usr/share/plymouth/themes/glyph
  run sudo plymouth-set-default-theme -R glyph
fi

if want grub; then
  cp "$HERE/grub/glyph/theme.txt" "$TMP/grub/"
  sed -i "s/@VIEW@/$GLYPH_VIEW/g; s/@DIM@/$GLYPH_DIM/g; s/@TEXT@/$GLYPH_TEXT/g; s/@TINK@/$GLYPH_TINK/g" "$TMP/grub/theme.txt"
  F=/usr/share/fonts/truetype/ibm-plex
  grub-mkfont -s 16 -o "$TMP/grub/plex16.pf2" "$F/IBMPlexMono-Regular.ttf" 2>/dev/null
  grub-mkfont -s 16 -o "$TMP/grub/plex16b.pf2" "$F/IBMPlexMono-Bold.ttf" 2>/dev/null
  echo "- GRUB menu"
  run sudo rm -rf /boot/grub/themes/glyph
  run sudo mkdir -p /boot/grub/themes
  run sudo cp -r "$TMP/grub" /boot/grub/themes/glyph
  run sudo mkdir -p /etc/default/grub.d
  if [ $DRY = 0 ]; then
    { echo '# Glyph start-up look - remove with: extras/boot/install-boot.sh --remove'
      echo 'GRUB_THEME=/boot/grub/themes/glyph/theme.txt'
      echo 'GRUB_GFXMODE=auto'
      want plymouth && echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT splash"'
    } | sudo tee /etc/default/grub.d/glyph.cfg >/dev/null
  fi
elif want plymouth; then
  [ $DRY = 0 ] && printf '# Glyph: show the start-up screen\nGRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT splash"\n' | sudo tee /etc/default/grub.d/glyph.cfg >/dev/null
fi
if want grub || want plymouth; then has update-grub && run sudo update-grub; fi
[ $DRY = 1 ] || { want sddm && sudo chmod -R a+rX /usr/share/sddm/themes/glyph; want plymouth && sudo chmod -R a+rX /usr/share/plymouth/themes/glyph; want grub && sudo chmod -R a+rX /boot/grub/themes/glyph; true; }

echo
echo "Done. Restart to see it. To go back: extras/boot/install-boot.sh --remove"
