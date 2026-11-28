#!/bin/sh
# Glyph start-up look: GRUB menu, Plymouth start-up screen and SDDM sign-in screen.
# This changes system files (it asks for your password) and also changes how
# KDE's sign-in screen looks, because SDDM is shared. Everything can be undone:
#
#   ./install-boot.sh              all three
#   ./install-boot.sh sddm grub    only these (sddm, grub, plymouth)
#   ./install-boot.sh --remove     back to how it was
#   ./install-boot.sh --check      show what would happen, change nothing
#
# The Glyph ISO runs it as root while the image is built, with
# GLYPH_BOOT_SYSTEM=1 (no sudo, no apt, no update-grub: the installer runs that)
# and GLYPH_PALETTE=<palette.env> (the default Glyph colours).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
PAL="${GLYPH_PALETTE:-${XDG_CONFIG_HOME:-$HOME/.config}/glyph/palette.env}"
SYSTEM=${GLYPH_BOOT_SYSTEM:-0}
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
if [ "$SYSTEM" = 1 ]; then
  [ "$(id -u)" = 0 ] || { echo "GLYPH_BOOT_SYSTEM=1 is for building the ISO, as root."; exit 1; }
  sudo() { "$@"; }   # already root
else
  [ "$(id -u)" = 0 ] && { echo "Run this as yourself, not as root. It asks for your password when needed."; exit 1; }
fi
run() { if [ $DRY = 1 ]; then echo "  would run: $*"; else "$@"; fi; }
# system tools live in /usr/sbin, which is not in a normal user's PATH on Debian
PATH="$PATH:/usr/sbin:/sbin"
has() { command -v "$1" >/dev/null 2>&1; }
want() { case " $PARTS " in *" $1 "*) return 0 ;; esac; return 1; }

if [ $REMOVE = 1 ]; then
  echo "Glyph start-up look: removing$PARTS"
  if want sddm; then
    run sudo rm -f /etc/sddm.conf.d/glyph.conf /etc/sddm.conf.d/zz-glyph.conf
    if [ -f $STATE/sddm-current-before ] && [ -f /etc/sddm.conf ]; then
      before=$(sed 's/^[[:space:]]*//' $STATE/sddm-current-before)
      run sudo sed -i "s/^\([[:space:]]*\)Current=glyph\$/\1$before/" /etc/sddm.conf
      run sudo rm -f $STATE/sddm-current-before
    fi
    run sudo rm -rf /usr/share/sddm/themes/glyph
  fi
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
[ -n "$pkgs" ] && [ "$SYSTEM" = 0 ] && run sudo apt-get install -y $pkgs
[ $DRY = 1 ] || sudo mkdir -p $STATE

# GRUB in the screen's own resolution, with a font size that fits it
RES="${GLYPH_BOOT_RES:-}"
[ -n "$RES" ] || for c in /sys/class/drm/card*-*; do
  [ "$(cat "$c/status" 2>/dev/null)" = connected ] || continue
  m=$(head -n1 "$c/modes" 2>/dev/null)
  [ -n "$m" ] && { RES=$m; break; }
done
RES=${RES:-1920x1080}
SW=${RES%x*}; SH=${RES#*x}
FS=$((SH / 54)); [ $FS -lt 16 ] && FS=16; [ $FS -gt 40 ] && FS=40
# the boot-menu box, as in the design: 44 % wide, a fifth down
GW=$((SW * 44 / 100)); GX=$(((SW - GW) / 2)); GY=$((SH / 5))
BH=$((FS * 17 / 10)); IH=$((FS * 2)); PAD=$((FS * 3 / 4)); FH=$((FS * 2))
LBW=$((FS * 7)); MH=$((4 * (IH + 2)))
GH=$((BH + PAD + MH + PAD + FH))
LX=$((GX + 8 + FS / 2)); LY=$((GY + (BH - FS) / 2 - 1))
MX=$((GX + PAD / 2)); MY=$((GY + BH + PAD / 2)); MW=$((GW - PAD))
FX=$((GX + PAD)); FY=$((GY + GH - FH + (FH - FS) / 2 - 3)); GW2=$((GW / 2)); GW3=$((GW - 2 * PAD))
SEG=$((SH / 72)); [ $SEG -lt 14 ] && SEG=14
export GW GH BH IH LBW FH FS SEG
echo "  screen $RES, GRUB letters $FS px"
python3 "$HERE/make-images.py" "$PAL" "$TMP/grub" "$TMP/plymouth"
TEXTPICS=0
. "$TMP/grub/sizes.sh"
rm -f "$TMP/grub/sizes.sh"
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
  if [ $DRY = 0 ]; then printf '[Theme]\nCurrent=glyph\n' | sudo tee /etc/sddm.conf.d/zz-glyph.conf >/dev/null; sudo rm -f /etc/sddm.conf.d/glyph.conf
    # left over from the first try (when Glyph was called Retro 83)
    sudo rm -f /etc/sddm.conf.d/zz-retro83.conf
    for f in /etc/sddm.conf.d/*.conf; do
      case "$f" in */zz-glyph.conf) continue ;; esac
      [ "$(basename "$f")" \> "zz-glyph.conf" ] && grep -q '^[[:space:]]*Current=' "$f" &&
        echo "  note: $f also chooses a sign-in theme and is read after Glyph's; remove it to use Glyph's"
    done
    # /etc/sddm.conf is read last and wins: if it names a theme, point it to Glyph (and remember the old one)
    if [ -f /etc/sddm.conf ] && grep -q '^[[:space:]]*Current=' /etc/sddm.conf; then
      [ -f $STATE/sddm-current-before ] || grep -m1 '^[[:space:]]*Current=' /etc/sddm.conf | sudo tee $STATE/sddm-current-before >/dev/null
      sudo sed -i 's/^\([[:space:]]*\)Current=.*/\1Current=glyph/' /etc/sddm.conf
    fi
  fi
fi

if want plymouth; then
  sed "s/@VIEW_RGB@/$(rgbf $GLYPH_LO)/g; s/@TAN_RGB@/$(rgbf $GLYPH_TAN)/g; s/@AMBER_RGB@/$(rgbf $GLYPH_AMBER)/g; s/@FS@/$FS/g; s/@TEXTPICS@/$TEXTPICS/g; s/@DIM_RGB@/$(rgbf $GLYPH_DIM)/g; s/@TEXT_RGB@/$(rgbf $GLYPH_TEXT)/g" \
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
  # GRUB's own font, with a fixed name ("Glyph Regular 26"); Debian's unicode font if that fails
  F=/usr/share/fonts/truetype/ibm-plex
  FONTR="Glyph Regular $FS"; FONTB="Glyph Bold $FS"
  if ! grub-mkfont -n Glyph -s "$FS" -o "$TMP/grub/glyph-regular.pf2" "$F/IBMPlexMono-Regular.ttf" ||
     ! grub-mkfont -n Glyph -s "$FS" -o "$TMP/grub/glyph-bold.pf2" "$F/IBMPlexMono-Bold.ttf"; then
    echo "  grub-mkfont failed; using GRUB's own font"
    rm -f "$TMP"/grub/*.pf2
    cp /boot/grub/fonts/unicode.pf2 "$TMP/grub/" 2>/dev/null || cp /usr/share/grub/unicode.pf2 "$TMP/grub/" 2>/dev/null || true
    FONTR="Unifont Regular 16"; FONTB="Unifont Regular 16"
  fi
  LX=$((GX + 8 + (LBW - ${TT_W:-$((LBW - FS))}) / 2))
  LYI=$((GY + (BH - ${TT_H:-$FS}) / 2)); FYI=$((GY + GH - FH + (FH - ${TK_H:-$FS}) / 2))
  if [ "$TEXTPICS" = 1 ]; then sed -i 's/^#IMG //; /^#LBL /d' "$TMP/grub/theme.txt"; else sed -i 's/^#LBL //; /^#IMG /d' "$TMP/grub/theme.txt"; fi
  sed -i "s/@LO@/$GLYPH_LO/g; s/@DIM@/$GLYPH_DIM/g; s/@TEXT@/$GLYPH_TEXT/g; s/@TINK@/$GLYPH_TINK/g;
          s/@FONTR@/$FONTR/g; s/@FONTB@/$FONTB/g; s/@FS@/$FS/g;
          s/@GX@/$GX/g; s/@GY@/$GY/g; s/@GW@/$GW/g; s/@GH@/$GH/g; s/@LX@/$LX/g; s/@LY@/$LY/g; s/@LYI@/$LYI/g;
          s/@LBW@/$LBW/g; s/@MX@/$MX/g; s/@MY@/$MY/g; s/@MW@/$MW/g; s/@MH@/$MH/g; s/@IH@/$IH/g; s/@PAD@/$PAD/g;
          s/@FX@/$FX/g; s/@FY@/$FY/g; s/@FYI@/$FYI/g; s/@GW2@/$GW2/g; s/@GW3@/$GW3/g;
          s/@TT_W@/${TT_W:-0}/g; s/@TT_H@/${TT_H:-0}/g; s/@TK_W@/${TK_W:-0}/g; s/@TK_H@/${TK_H:-0}/g;
          s/@TP_W@/${TP_W:-0}/g; s/@TP_H@/${TP_H:-0}/g" "$TMP/grub/theme.txt"
  echo "- GRUB menu"
  run sudo rm -rf /boot/grub/themes/glyph
  run sudo mkdir -p /boot/grub/themes
  run sudo cp -r "$TMP/grub" /boot/grub/themes/glyph
  run sudo mkdir -p /etc/default/grub.d
  if [ $DRY = 0 ]; then
    { echo '# Glyph start-up look - remove with: extras/boot/install-boot.sh --remove'
      echo 'GRUB_THEME=/boot/grub/themes/glyph/theme.txt'
      echo "GRUB_GFXMODE=$RES,auto"
      echo 'GRUB_GFXPAYLOAD_LINUX=keep'
      echo 'GRUB_TERMINAL_OUTPUT=gfxterm'
      echo 'GRUB_BACKGROUND=/boot/grub/themes/glyph/bg.png'   # instead of Debian's blue picture
      [ -f "$TMP/grub/glyph-regular.pf2" ] && echo 'GRUB_FONT=/boot/grub/themes/glyph/glyph-regular.pf2'
      echo 'GRUB_TIMEOUT=5'
      echo 'GRUB_TIMEOUT_STYLE=menu'
      want plymouth && echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT splash"'
    } | sudo tee /etc/default/grub.d/glyph.cfg >/dev/null
  fi
elif want plymouth; then
  [ $DRY = 0 ] && printf '# Glyph: show the start-up screen\nGRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT splash"\n' | sudo tee /etc/default/grub.d/glyph.cfg >/dev/null
fi
if [ "$SYSTEM" = 0 ] && { want grub || want plymouth; }; then has update-grub && run sudo update-grub; fi
[ $DRY = 1 ] || { want sddm && sudo chmod -R a+rX /usr/share/sddm/themes/glyph; want plymouth && sudo chmod -R a+rX /usr/share/plymouth/themes/glyph; want grub && sudo chmod -R a+rX /boot/grub/themes/glyph; true; }

# for checking what was made: GLYPH_BOOT_KEEP=/some/dir install-boot.sh --check
[ -n "${GLYPH_BOOT_KEEP:-}" ] && cp -r "$TMP"/. "$GLYPH_BOOT_KEEP"/
echo
echo "Done. Restart to see it. To go back: extras/boot/install-boot.sh --remove"
