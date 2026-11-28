# Glyph live ISO

A Debian 13 live system that starts straight into Glyph, made with Debian's
[live-build](https://live-team.pages.debian.net/live-manual/). GitHub builds it
(`.github/workflows/iso.yml`), boots it in QEMU (BIOS and UEFI) until the Glyph
desktop shows, and puts it on the release **glyph-iso**.

| File | What it does |
|---|---|
| `build.sh` | Builds `glyph-<version>-amd64.iso` (root, Debian 13 or a `debian:trixie` container with `--privileged`) |
| `auto/config` | live-build settings: trixie, amd64, `main contrib non-free-firmware`, Debian's installer |
| `config/package-lists/glyph.list.chroot` | What is in the image (recommends are off, so everything is named) |
| `config/hooks/normal/0900-glyph.hook.chroot` | Optional extras, checks labwc is labwc-glyph (and pins it), SDDM and the start-up look, Calamares settings |
| `config/includes.chroot/usr/lib/glyph-live/live-setup` | Live only (run before SDDM, see `etc/systemd/system/sddm.service.d/`): the user `glyph` is signed in to Glyph at start |
| `config/includes.chroot/etc/calamares/branding/glyph/` | Calamares in the Glyph look (colours, IBM Plex Mono, square buttons; the slides are the README screenshots, copied in by `build.sh`) |
| `config/includes.chroot/usr/lib/glyph-live/` | Live only: automatic sign-in, "Install Glyph" in Start (`install-glyph`), no password for the installer |
| `install-test.py` | Installs the ISO onto a blank QEMU disk with Calamares (by keyboard and mouse), starts the installed system and signs in (workflow `iso-install-test`, after every ISO) |
| `boot-test.py` | Boots the ISO in QEMU and waits for the Glyph desktop (screenshots) |

How it fits together:

- **Glyph**: `build.sh` builds `glyph-desktop` from this checkout and downloads
  `labwc-glyph` from its release into `config/packages.chroot/`.
- **Sign-in**: SDDM with Glyph's sign-in screen. In the live system the user
  `glyph` (password `live`) is signed in by itself; the first sign-in sets up
  Glyph (`glyph-setup-user`) and Welcome opens. An installed system shows
  Glyph's sign-in screen.
- **Start-up look**: Glyph's GRUB menu, Plymouth start-up screen and sign-in
  screen from `extras/boot`, in the default Glyph colours (made while the
  image is built; `extras/boot/install-boot.sh` later puts in your own colours).
- **Installing**: **Install Glyph** in Start (or `install-glyph` in a terminal)
  starts Calamares with Debian's settings and Glyph's look. It copies the live
  system to the disk, removes the live user, and sets up SDDM so the new
  user signs in to Glyph (Glyph's own settings come at that first sign-in).
  "Install" in the boot menu still starts Debian's own installer.
- **Boot menu of the stick**: live-build's own menus, waiting 5 seconds instead of for ever.

Build it yourself (20–40 minutes, about 15 GB of disk):

```sh
sudo docker run --rm --privileged -v "$PWD:/src" -w /src debian:trixie extras/iso/build.sh out
python3 extras/iso/boot-test.py out/glyph-*-amd64.iso shots bios
```
