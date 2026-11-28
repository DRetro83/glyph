#!/usr/bin/env python3
"""Install Glyph from the ISO onto a blank QEMU disk with Calamares, then start
the installed system and sign in, until the Glyph desktop shows.

  install-test.py ISO OUTDIR

Calamares is driven with the keyboard (QEMU monitor "sendkey"), the way a
person would: Next through the pages, erase the disk, a user "tester",
Install, Done. Then the disk is started without the ISO and the user signs in
on Glyph's sign-in screen (SDDM). Every step leaves a screenshot in OUTDIR
(install-NN-<step>.png); OUTDIR/installed.png is the installed desktop.
Exit 0 = the installed system reached the Glyph desktop."""
import os
import shutil
import socket
import subprocess
import sys
import time

from PIL import Image

USER, PASSWORD = "tester", "glyphtest123"
KEYS = {"-": "minus", " ": "spc", ".": "dot", "/": "slash"}
OUT = "."
STEP = [0]


def monitor(sock_path, cmd):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(10)
    s.connect(sock_path)
    s.recv(4096)
    s.sendall((cmd + "\n").encode())
    time.sleep(0.6)
    try:
        s.recv(65536)
    except socket.timeout:
        pass
    s.close()


def shot(sock, name):
    ppm = "/tmp/glyph-install.ppm"
    monitor(sock, f"screendump {ppm}")
    time.sleep(0.5)
    STEP[0] += 1
    png = f"{OUT}/install-{STEP[0]:02d}-{name}.png"
    Image.open(ppm).save(png)
    print(f"  shot {png}", flush=True)
    return png


def warm_dark(sock):
    ppm = "/tmp/glyph-install-w.ppm"
    monitor(sock, f"screendump {ppm}")
    time.sleep(0.5)
    im = Image.open(ppm).convert("RGB")
    im.thumbnail((320, 240))
    px = list(im.getdata())
    return sum(1 for r, g, b in px if max(r, g, b) < 120 and r - b >= 4) / len(px)


QMP = "/tmp/glyph-install-qmp.sock"
SCREEN = (1280, 800)


def click(x, y, wait=2.0):
    """A left click at screen pixel x, y (QMP, absolute: the usb-tablet)."""
    import json
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(10)
    s.connect(QMP)
    f = s.makefile("rw")
    f.readline()
    def send(obj):
        f.write(json.dumps(obj) + "\n"); f.flush()
        while True:
            r = json.loads(f.readline())
            if "return" in r or "error" in r:
                return r
    send({"execute": "qmp_capabilities"})
    ax = int(x * 32767 / (SCREEN[0] - 1)); ay = int(y * 32767 / (SCREEN[1] - 1))
    send({"execute": "input-send-event", "arguments": {"events": [
        {"type": "abs", "data": {"axis": "x", "value": ax}},
        {"type": "abs", "data": {"axis": "y", "value": ay}}]}})
    time.sleep(0.3)
    for down in (True, False):
        send({"execute": "input-send-event", "arguments": {"events": [
            {"type": "btn", "data": {"down": down, "button": "left"}}]}})
        time.sleep(0.15)
    s.close()
    time.sleep(wait)


def key(sock, k, wait=1.0):
    monitor(sock, "sendkey " + k)
    time.sleep(wait)


def type_text(sock, text):
    for ch in text:
        monitor(sock, "sendkey " + KEYS.get(ch, ch))
    time.sleep(0.5)


def start_qemu(args, sock):
    for p in (sock, QMP):
        if os.path.exists(p):
            os.unlink(p)
    cmd = ["qemu-system-x86_64", "-m", "4G", "-smp", "2",
           "-vga", "std", "-display", "none",
           "-monitor", f"unix:{sock},server,nowait",
           "-qmp", f"unix:{QMP},server,nowait",
           "-nic", "user,model=virtio-net-pci",
           "-usb", "-device", "usb-tablet"] + args
    if os.access("/dev/kvm", os.R_OK | os.W_OK):
        cmd[1:1] = ["-enable-kvm", "-cpu", "host"]
    print(" ".join(cmd), flush=True)
    q = subprocess.Popen(cmd)
    time.sleep(3)
    return q


def wait_desktop(sock, q, limit, label):
    start, hits = time.time(), 0
    while time.time() - start < limit:
        time.sleep(10)
        if q.poll() is not None:
            print(f"{label}: QEMU stopped")
            return False
        try:
            frac = warm_dark(sock)
        except Exception as e:
            print(f"{label}: no screen yet ({e})")
            continue
        print(f"{label}: {int(time.time() - start):4d}s warm dark {frac:.0%}", flush=True)
        hits = hits + 1 if frac > 0.6 else 0
        if hits >= 2:
            return True
    return False


def stop(sock, q):
    try:
        monitor(sock, "quit")
    except Exception:
        pass
    try:
        q.wait(20)
    except subprocess.TimeoutExpired:
        q.kill()


def main():
    global OUT
    iso, OUT = sys.argv[1], sys.argv[2]
    os.makedirs(OUT, exist_ok=True)
    disk = "/tmp/glyph-install-disk.qcow2"
    subprocess.run(["qemu-img", "create", "-f", "qcow2", disk, "24G"], check=True)
    sock = "/tmp/glyph-install.sock"

    # 1. the live system, then the installer
    q = start_qemu(["-cdrom", iso, "-boot", "d",
                    "-drive", f"file={disk},if=virtio,format=qcow2"], sock)
    if not wait_desktop(sock, q, 600, "live"):
        shot(sock, "no-live-desktop"); stop(sock, q); sys.exit(1)
    time.sleep(15)
    key(sock, "ctrl-alt-t", 6)
    type_text(sock, "install-glyph")
    key(sock, "ret", 40)
    shot(sock, "welcome")

    # 2. Welcome, Location, Keyboard: Next
    for page in ("location", "keyboard", "partitions"):
        key(sock, "alt-n", 6)
        shot(sock, page)
    # 3. Partitions: tick "Erase disk" (the installer window is centred: 960x620), Next
    click(333, 148, 3)
    shot(sock, "erase")
    key(sock, "alt-n", 5)
    shot(sock, "users")
    # 4. Users: name (login name and computer name follow), password twice
    type_text(sock, USER)
    time.sleep(1)
    shot(sock, "users-name")
    for _ in range(3):
        key(sock, "tab", 0.4)
    type_text(sock, PASSWORD)
    key(sock, "tab", 0.4)
    type_text(sock, PASSWORD)
    time.sleep(2)
    shot(sock, "users-filled")
    key(sock, "alt-n", 5)
    shot(sock, "summary")
    # 5. Summary: Install, then "Install now" in the question
    key(sock, "alt-i", 4)
    shot(sock, "confirm")
    key(sock, "alt-i", 10)
    shot(sock, "installing")

    # 6. wait for "All done" (the Done button), 8 minutes (a KVM install takes about 2)
    start = time.time()
    last = None
    while time.time() - start < 480:
        time.sleep(60)
        last = shot(sock, f"progress-{int(time.time() - start) // 60:02d}m")
    # the finish page has a "Restart now" box and the button Done
    key(sock, "alt-d", 5)
    shot(sock, "done")
    stop(sock, q)

    # 7. the installed system, from the disk only
    q = start_qemu(["-drive", f"file={disk},if=virtio,format=qcow2", "-boot", "c"], sock)
    time.sleep(90)
    shot(sock, "installed-boot")
    # Glyph's sign-in screen (SDDM): the only user is chosen, the password box has the focus
    type_text(sock, PASSWORD)
    key(sock, "ret", 5)
    shot(sock, "signed-in")
    ok = wait_desktop(sock, q, 300, "installed")
    time.sleep(20)
    png = shot(sock, "installed-desktop")
    shutil.copy(png, f"{OUT}/installed.png")
    stop(sock, q)
    print("installed system: Glyph desktop" if ok else "installed system: no Glyph desktop")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
