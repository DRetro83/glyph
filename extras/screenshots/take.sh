#!/bin/bash
# Takes the screenshots for the README from the real Glyph session, headless.
# (the first runs found a real install bug: IBM Plex needs Debian's contrib section)
# Runs on GitHub (see .github/workflows/screenshots.yml) as a normal user after ./install.sh.
#   extras/screenshots/take.sh OUTDIR
OUT=$(realpath "${1:-shots}")
mkdir -p "$OUT"
set -x
export XDG_RUNTIME_DIR=/tmp/xdg-$(id -u)
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 WLR_HEADLESS_OUTPUTS=1
export LANG=C.UTF-8 LC_ALL=C.UTF-8 NO_AT_BRIDGE=1
G=$HOME/.config/glyph
T=$G/theme.conf

# no welcome steps, some files to show, a song that plays
touch "$G/welcome-done"
mkdir -p ~/Documents ~/Downloads ~/Music ~/Pictures ~/Videos ~/Games ~/Projects
for f in Documents/letter.odt Documents/budget-2026.ods Documents/notes.txt Pictures/holiday.jpg \
         Music/midnight-city.mp3 Downloads/debian-13.iso Projects/glyph.html; do
  head -c $((RANDOM * 40)) /dev/urandom > ~/"$f"
done
mkdir -p /tmp/fake
cat > /tmp/fake/playerctl <<'EOF'
#!/bin/sh
case "$*" in
  "-l") echo vivaldi.instance1 ;;
  *status*) echo Playing ;;
  *metadata*) printf 'Midnight City\tM83\n' ;;
  *) : ;;
esac
EOF
chmod +x /tmp/fake/playerctl
export PATH=/tmp/fake:$PATH

# no password helper: without a real login session it only shows an error
sed -i '/lxpolkit/d' "$G/labwc/autostart"

# put the windows where they look good
python3 - "$G/labwc/rc.xml" <<'EOF'
import sys
p = sys.argv[1]; s = open(p).read()
rules = """
    <windowRule identifier="*Files*"><action name="ResizeTo" width="1060" height="640" /><action name="MoveTo" x="70" y="60" /></windowRule>
    <windowRule identifier="glyph-files"><action name="ResizeTo" width="1060" height="640" /><action name="MoveTo" x="70" y="60" /></windowRule>
    <windowRule identifier="glyph-settings"><action name="ResizeTo" width="1000" height="660" /><action name="MoveTo" x="840" y="300" /></windowRule>
    <windowRule identifier="glyph-music"><action name="MoveTo" x="160" y="120" /></windowRule>
    <windowRule identifier="glyph-monitor"><action name="MoveTo" x="160" y="120" /></windowRule>
    <windowRule identifier="glyph-software"><action name="MoveTo" x="160" y="120" /></windowRule>"""
s = s.replace("<windowRules>", "<windowRules>" + rules, 1)
open(p, "w").write(s)
EOF

ws_own() { sed -i '/^ws_colours=/d' "$T"; echo "ws_colours=$1" >> "$T"; }
glyph-theme --shadows yes --mode dark --colour tan
ws_own own

eval "$(dbus-launch --sh-syntax)"
glyph-session > "$OUT/session.log" 2>&1 &
sleep 12
export WAYLAND_DISPLAY=$(ls "$XDG_RUNTIME_DIR" | grep -m1 -x 'wayland-[0-9]')
export LABWC_PID=$(pgrep -x labwc)
wlr-randr --output HEADLESS-1 --custom-mode 1920x1080 || true
sleep 3

shot() { sleep "${2:-4}"; grim "$OUT/$1.png"; }
closepanels() { pkill -f "bin/glyph-panel"; pkill -f "bin/glyph-start"; sleep 1; }

# 1. the desktop: Files and Settings, then the start menu on top
glyph-files ~ & sleep 4
glyph-settings Appearance & sleep 5
shot real-windows 2
glyph-start & shot real-start 4
closepanels

# 2. quick settings and the calendar
glyph-panel quick & shot real-quick 5
closepanels
glyph-panel cal & shot real-calendar 4
closepanels

# 3. a workspace each, each in its own colour: an app on every workspace
glyph-ws 2; sleep 3; glyph-music & sleep 4
glyph-ws 3; sleep 3; glyph-monitor & sleep 4
glyph-ws 4; sleep 3; glyph-software & sleep 5
for n in 1 2 3 4; do glyph-ws $n; shot ws$n 5; done

# 4. light mode, one colour, rounded corners
glyph-ws 1; sleep 3
ws_own same
glyph-theme --mode light --colour blue --set corners=round --set radius=10
sleep 6
glyph-ws 1; shot real-light 4
glyph-panel quick & shot real-light-quick 5
closepanels

# back to how it was
glyph-theme --mode dark --colour tan --set corners=square --set radius=0
ls -la "$OUT"

# the four workspaces in one picture: 2 x 2, and the four taskbars stacked
python3 - "$OUT" <<'EOF'
import sys
from PIL import Image
out = sys.argv[1]
ims = [Image.open(f"{out}/ws{n}.png").convert("RGB") for n in (1, 2, 3, 4)]
w, h = ims[0].size
grid = Image.new("RGB", (w, h), "black")
for i, im in enumerate(ims):
    grid.paste(im.resize((w // 2, h // 2), Image.LANCZOS), ((i % 2) * w // 2, (i // 2) * h // 2))
grid.save(f"{out}/real-workspaces.png")
bar = 56
strip = Image.new("RGB", (w // 2, bar * 4), "black")
for i, im in enumerate(ims):
    strip.paste(im.crop((0, h - bar, w // 2, h)), (0, i * bar))
strip.save(f"{out}/real-workspace-bars.png")
EOF
