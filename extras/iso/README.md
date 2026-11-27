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
| `config/hooks/normal/0900-glyph.hook.chroot` | Optional extras, checks labwc is labwc-glyph (and pins it), sets up greetd |
| `config/includes.chroot/usr/lib/live/config/2100-glyph-autologin` | Live only: the user `glyph` is signed in to Glyph at start |
| `boot-test.py` | Boots the ISO in QEMU and waits for the Glyph desktop (screenshots) |

How it fits together:

- **Glyph**: `build.sh` builds `glyph-desktop` from this checkout and downloads
  `labwc-glyph` from its release into `config/packages.chroot/`.
- **Sign-in**: greetd. In the live system the user `glyph` (password `live`)
  is signed in by itself; the first sign-in sets up Glyph (`glyph-setup-user`)
  and Welcome opens. An installed system asks for the name and password on a
  text prompt, then starts Glyph.
- **Installing**: "Install" in the boot menu starts Debian's own installer,
  which copies the live system to the disk. (A Glyph-styled Calamares comes later.)
- **Boot menu**: live-build's own menus, waiting 5 seconds instead of for ever.

Build it yourself (20–40 minutes, about 15 GB of disk):

```sh
sudo docker run --rm --privileged -v "$PWD:/src" -w /src debian:trixie extras/iso/build.sh out
python3 extras/iso/boot-test.py out/glyph-*-amd64.iso shots bios
```
