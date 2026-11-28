#!/usr/bin/env bash
# Builds the Glyph live ISO (glyph-<version>-amd64.iso) with Debian's live-build.
#   extras/iso/build.sh [OUTDIR]
# Run as root on Debian 13, or in a container:
#   docker run --rm --privileged -v "$PWD:/src" -w /src debian:trixie extras/iso/build.sh out
# glyph-desktop is built from this folder (extras/deb/build.sh); labwc-glyph
# comes from the release "labwc-glyph". Takes 20-40 minutes.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
OUT=$(realpath -m "${1:-$REPO/out}")
VER=$(cat "$REPO/VERSION")
WORK=${GLYPH_ISO_WORK:-/var/tmp/glyph-iso}
[[ $EUID -eq 0 ]] || { echo "Run this as root (live-build needs it)."; exit 1; }
mkdir -p "$OUT"

echo ":: tools"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends live-build debootstrap debian-archive-keyring \
  xorriso squashfs-tools isolinux syslinux-common syslinux-utils grub-pc-bin grub-efi-amd64-bin \
  mtools dosfstools cpio apt-utils zstd ca-certificates curl python3 git dpkg-dev
git config --global --add safe.directory "$REPO" || true

echo ":: config in $WORK"
rm -rf "$WORK"
mkdir -p "$WORK"
cp -a "$HERE/auto" "$HERE/config" "$WORK/"
cd "$WORK"

echo ":: glyph-desktop (from this checkout) and labwc-glyph (from its release)"
bash "$REPO/extras/deb/build.sh" "$WORK/config/packages.chroot"
python3 - "$WORK/config/packages.chroot" <<'EOF'
import json, os, sys, urllib.request
dest = sys.argv[1]
req = urllib.request.Request("https://api.github.com/repos/DRetro83/glyph/releases/tags/labwc-glyph")
if os.environ.get("GITHUB_TOKEN"):
    req.add_header("Authorization", "Bearer " + os.environ["GITHUB_TOKEN"])
assets = json.load(urllib.request.urlopen(req))["assets"]
deb = [a for a in assets if a["name"].startswith("labwc_") and a["name"].endswith("_amd64.deb") and "glyph" in a["name"]]
if not deb:
    sys.exit("no labwc-glyph .deb on the release labwc-glyph")
a = sorted(deb, key=lambda a: a["name"])[-1]
print("  " + a["name"])
urllib.request.urlretrieve(a["browser_download_url"], os.path.join(dest, a["name"]))
EOF
ls -la config/packages.chroot

echo ":: Calamares look: version and slides (the README screenshots)"
B=config/includes.chroot/etc/calamares/branding/glyph
sed -i "s/@VERSION@/$VER/g" "$B/branding.desc"
for s in windows start quick workspaces light; do
  cp "$REPO/docs/img/real/real-$s.png" "$B/slide-$s.png"
done

echo ":: start-up look (extras/boot) in the default Glyph colours"
BOOT=config/includes.chroot/usr/lib/glyph-live/boot
mkdir -p "$BOOT"
cp -a "$REPO/extras/boot/." "$BOOT/"
TH=$(mktemp -d)
HOME=$TH XDG_CONFIG_HOME=$TH/.config PATH="$REPO/bin:$PATH" python3 "$REPO/bin/glyph-theme" --quick
cp "$TH/.config/glyph/palette.env" "$BOOT/palette.env"
rm -rf "$TH"
grep -c '^GLYPH_' "$BOOT/palette.env"

echo ":: lb config"
lb config

# Boot menus wait 5 seconds, then start the live system (live-build waits for ever).
LB_BOOT=/usr/share/live/build/bootloaders
echo "  live-build's boot menus: $(ls "$LB_BOOT" 2>/dev/null | tr '\n' ' ')"
if [ -d "$LB_BOOT" ]; then
  cp -a "$LB_BOOT" config/
  { grep -rl '^timeout ' config/bootloaders || true; } | xargs -r sed -i 's/^timeout .*/timeout 50/'
  { grep -rl 'set timeout=' config/bootloaders || true; } | xargs -r sed -i 's/set timeout=.*/set timeout=5/'
  if [ -d config/bootloaders/grub-pc ] && ! grep -rq 'set timeout=' config/bootloaders/grub-pc; then
    echo 'set timeout=5' >> config/bootloaders/grub-pc/config.cfg
  fi
  echo "  boot menu waiting times:"
  { grep -rn 'timeout' config/bootloaders || true; } | grep -v -i 'timeoutrow' | sed 's/^/    /' || true
fi

echo ":: lb build"
lb build 2>&1 | tee "$OUT/build.log"
ISO=$(ls -1 "$WORK"/*.iso | head -1)
NAME="glyph-$VER-amd64"
mv "$ISO" "$OUT/$NAME.iso"
for f in "$WORK"/*.packages; do [ -e "$f" ] && cp "$f" "$OUT/$NAME.packages"; done
(cd "$OUT" && sha256sum "$NAME.iso" > "$NAME.iso.sha256")
ls -la "$OUT"
echo "$OUT/$NAME.iso"
