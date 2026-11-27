#!/usr/bin/env python3
"""Boot the Glyph ISO in QEMU without a screen and wait for the Glyph desktop.

  boot-test.py ISO OUTDIR NAME [--uefi | --direct]

--direct starts the live kernel without the boot menu, with the system log on
the serial port (OUTDIR/NAME-serial.log): to see why a boot went wrong.

Takes a screenshot (QEMU monitor "screendump") every 10 seconds. The Glyph
desktop is dark and warm (brown-black, red above blue), while the boot menu
and the text console are black, grey or blue: when most of the screen is warm
dark for two shots in a row, the desktop is there. Saves OUTDIR/NAME.png
(the desktop) and a few shots on the way (NAME-<seconds>s.png).
Exit 0 = desktop reached, 1 = not within the time limit.
Needs qemu-system-x86_64, python3-pil, and OVMF for --uefi."""
import os
import shutil
import socket
import subprocess
import sys
import time

from PIL import Image

LIMIT = int(os.environ.get("GLYPH_BOOT_LIMIT", "720"))   # seconds


def ovmf():
    for code, vars_ in [("/usr/share/OVMF/OVMF_CODE_4M.fd", "/usr/share/OVMF/OVMF_VARS_4M.fd"),
                        ("/usr/share/OVMF/OVMF_CODE.fd", "/usr/share/OVMF/OVMF_VARS.fd"),
                        ("/usr/share/ovmf/OVMF.fd", None)]:
        if os.path.exists(code):
            return code, vars_
    sys.exit("OVMF not found (apt install ovmf)")


def monitor(sock_path, cmd):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(10)
    s.connect(sock_path)
    s.recv(4096)   # the greeting
    s.sendall((cmd + "\n").encode())
    time.sleep(1.5)
    try:
        s.recv(65536)
    except socket.timeout:
        pass
    s.close()


def warm_dark(path):
    im = Image.open(path).convert("RGB")
    im.thumbnail((320, 240))
    px = list(im.convert("RGB").getdata()) if not hasattr(im, "get_flattened_data") else list(im.get_flattened_data())
    warm = sum(1 for r, g, b in px if max(r, g, b) < 120 and r - b >= 4)
    return warm / len(px), im.size


def main():
    iso, out, name = sys.argv[1], sys.argv[2], sys.argv[3]
    uefi = "--uefi" in sys.argv
    direct = "--direct" in sys.argv
    os.makedirs(out, exist_ok=True)
    sock = f"/tmp/glyph-qemu-{name}.sock"
    if os.path.exists(sock):
        os.unlink(sock)
    cmd = ["qemu-system-x86_64", "-m", "3G", "-smp", "2",
           "-cdrom", iso, "-boot", "d",
           "-vga", "std", "-display", "none",
           "-monitor", f"unix:{sock},server,nowait",
           "-serial", f"file:{out}/{name}-serial.log",
           "-nic", "user,model=virtio-net-pci",
           "-usb", "-device", "usb-tablet"]
    if os.path.exists("/dev/kvm") and os.access("/dev/kvm", os.R_OK | os.W_OK):
        cmd[1:1] = ["-enable-kvm", "-cpu", "host"]
    else:
        print("no KVM: this will be slow")
    if uefi:
        code, vars_ = ovmf()
        if vars_:
            shutil.copy(vars_, f"/tmp/glyph-{name}-vars.fd")
            cmd += ["-drive", f"if=pflash,format=raw,readonly=on,file={code}",
                    "-drive", f"if=pflash,format=raw,file=/tmp/glyph-{name}-vars.fd"]
        else:
            cmd += ["-bios", code]
    if direct:
        d = f"/tmp/glyph-{name}-live"
        os.makedirs(d, exist_ok=True)
        subprocess.run(["xorriso", "-osirrox", "on", "-indev", iso, "-extract", "/live", d],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        kernel = sorted(f for f in os.listdir(d) if f.startswith("vmlinuz"))[0]
        initrd = sorted(f for f in os.listdir(d) if f.startswith("initrd"))[0]
        cmd += ["-kernel", f"{d}/{kernel}", "-initrd", f"{d}/{initrd}", "-append",
                "boot=live components live-config.username=glyph live-config.user-fullname=Glyph "
                "live-config.hostname=glyph console=tty0 console=ttyS0,115200 "
                "systemd.journald.forward_to_console=1"]
    print(" ".join(cmd), flush=True)
    qemu = subprocess.Popen(cmd)
    time.sleep(3)

    start = time.time()
    hits = 0
    ok = False
    last = None
    while time.time() - start < LIMIT:
        time.sleep(10)
        if qemu.poll() is not None:
            print(f"QEMU stopped (exit {qemu.returncode})")
            break
        t = int(time.time() - start)
        ppm = f"/tmp/glyph-{name}.ppm"
        try:
            monitor(sock, f"screendump {ppm}")
            frac, size = warm_dark(ppm)
        except Exception as e:   # the screen may not be there yet
            print(f"{t:4d}s  no screenshot yet ({e})", flush=True)
            continue
        last = f"{out}/{name}-last.png"
        Image.open(ppm).save(last)
        print(f"{t:4d}s  screen {size}  warm dark {frac:.0%}", flush=True)
        if not os.path.exists(f"{out}/{name}-menu.png"):   # the first screen: the boot menu
            Image.open(ppm).save(f"{out}/{name}-menu.png")
        elif t // 60 != (t - 10) // 60:   # about one shot a minute, to see what happened
            Image.open(ppm).save(f"{out}/{name}-{t:03d}s.png")
        hits = hits + 1 if frac > 0.6 else 0
        if hits >= 2:
            time.sleep(20)   # let Welcome and the taskbar finish drawing
            monitor(sock, f"screendump {ppm}")
            Image.open(ppm).save(f"{out}/{name}.png")
            print(f"{name}: Glyph desktop after {int(time.time() - start)} s")
            ok = True
            break
    if not ok and last:
        shutil.copy(last, f"{out}/{name}.png")
        print(f"{name}: no Glyph desktop within {LIMIT} s (last screen in {name}.png)")
    try:
        monitor(sock, "quit")
    except Exception:
        pass
    try:
        qemu.wait(15)
    except subprocess.TimeoutExpired:
        qemu.kill()
    if os.path.exists(f"{out}/{name}-last.png"):
        os.unlink(f"{out}/{name}-last.png")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
