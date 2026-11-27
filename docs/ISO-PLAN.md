# Glyph ISO: the plan

A hand-off note for a new session. Read this first; everything else is in the repo.

## Who and how

- Owner: DRetro83 (Dutch, Debian 13 + KDE, AOC 2560×1440, US keyboard). **Reply in Dutch, short.** Glyph's own UI text is **English**; translations come from `share/lang/nl.txt` (glyph_lang.py).
- Working loop: Claude changes the repo, tests headless or on GitHub Actions, commits and pushes to `main`; the owner runs `glyph-update` and tests on his PC.
- Claude cannot push tags; the owner makes tagged releases. Workflows may create/update releases with `GITHUB_TOKEN` (see `labwc-glyph.yml`, `deb.yml`).
- Read GitHub without auth: `env -u GH_TOKEN curl -s https://api.github.com/repos/DRetro83/glyph/...`. Job logs need auth, so workflows that can fail push a log to a branch (see `install-test.yml` → branch `ci-logs`) or commit it.
- Commit messages end with the Co-Authored-By / Claude-Session lines the session gives.

## What exists (version 1.0.5)

- **Glyph** = labwc session on Debian 13 (trixie) with Glyph's own programs in Python/GTK3 (`bin/glyph-*`), configs in `config/`, data in `share/`.
- **labwc-glyph**: Debian's labwc 0.8.3 + Glyph patches (title bars, hard shadow, taskbar per workspace), built by `.github/workflows/labwc-glyph.yml`, published on release **labwc-glyph** (`labwc_0.8.3-1+glyph3_amd64.deb`).
- **glyph-desktop .deb**: all of Glyph in one package (`extras/deb/build.sh`), installs to `/usr/bin`, `/usr/lib/glyph`, `/usr/share/glyph`. Built + install-tested on a clean Debian 13 by `.github/workflows/deb.yml`, published on release **glyph-desktop**. `Depends` = the PACKAGES list of `install.sh` (needs Debian's **contrib** section for `fonts-ibm-plex`).
- Each person gets their settings at their **first Glyph sign-in**: `glyph-session` runs `glyph-setup-user` when `~/.config/glyph/labwc/rc.xml` is missing. No per-user step is needed in the ISO.
- `glyph-update` updates package installs from the release **glyph-desktop**.
- Boot look (optional, not in the package yet): `extras/boot/` (GRUB theme, Plymouth, SDDM theme). See `install.sh --boot` / README.
- Tests that already exist: `install-test.yml` (install.sh → glyph-update → second user → uninstall), `deb.yml`, `screenshots.yml` (real headless session, screenshots into `docs/img/real/`).

## The ISO, part 1: a live USB that boots into Glyph

Goal: `glyph-<version>-amd64.iso`, built on GitHub Actions, that boots (BIOS + UEFI) straight into a Glyph live session, and can be installed with **Debian's own installer** for now.

Plan:
1. `extras/iso/` with a **live-build** config (Debian 13 trixie, amd64, `main contrib non-free-firmware`), in a `debian:trixie` container (`apt-get install live-build`). Keep the config small and documented.
2. Package lists: `glyph-desktop` and its deps, `labwc-glyph`, firmware (`firmware-linux-free`, common non-free-firmware for Wi-Fi), `network-manager`, a display manager (**greetd + a Glyph-styled greeter** or **SDDM with Glyph's theme** from `extras/boot/`; pick the simplest that starts the Glyph session), `firefox-esr`, `debian-installer-launcher` or the live-build `--debian-installer live` option.
3. Local packages: put `labwc_*+glyph3_amd64.deb` and `glyph-desktop_*_all.deb` (download from the releases in the workflow) in `config/packages.chroot/`. apt must prefer labwc-glyph over Debian's labwc (pin, or install the local .deb).
4. Live user: autologin into the Glyph session (user `glyph`, no password or `live`). `glyph-setup-user` runs at first sign-in by itself. Skip the welcome steps in the live session? Better: keep Welcome, it is a nice first look.
5. Workflow `.github/workflows/iso.yml`: on `workflow_dispatch` and when `extras/iso/**` changes; build (takes 20–40 min; use caching for apt if easy), then **boot-test** the ISO headless in QEMU (`qemu-system-x86_64 -cdrom … -m 3G -vga std -display none`, screenshot with the QEMU monitor `screendump`, wait for the Glyph desktop) and publish the ISO + screenshot to a release **glyph-iso** (ISO files are big: GitHub allows assets up to 2 GB).
6. README: how to put it on a USB stick (Ventoy / `dd` / balenaEtcher) and try it.

Done when: the ISO boots in QEMU to the Glyph desktop (screenshot on the release), and Debian's installer can be started from the boot menu.

## The ISO, part 2: Calamares in the Glyph look (later)

- Calamares (`calamares`, `calamares-settings-debian` as a base) with a **Glyph branding** (`extras/iso/calamares/branding/glyph/`: colours from glyph-theme's palette, IBM Plex Mono, square buttons, short English texts; the slideshow shows Glyph screenshots from `docs/img/real/`).
- An **Install Glyph** launcher on the live desktop (and in Start), using pkexec.
- After install: the new user gets Glyph by itself at first sign-in (glyph-setup-user); the live user and autologin are removed by Calamares' modules.
- Boot look in the installed system: GRUB theme + Plymouth + login screen from `extras/boot/`.
- Test: in QEMU with a blank disk, run Calamares unattended if possible, or at least check it starts and looks right (screenshot).

## Things to watch

- Debian 13 = trixie. `fonts-ibm-plex` is in **contrib**.
- labwc must be the **+glyph3** version, or the title bars, shadow and per-workspace taskbar fall back to plain labwc.
- Don't break `install.sh`: the owner runs Glyph from a git checkout in `/usr/local` on his own PC.
- Every new UI text in English, with a Dutch line in `share/lang/nl.txt`.
