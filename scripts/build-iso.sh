#!/bin/bash
# Build the Cipher live ISO with live-build.
#
# Run on Debian 13 (trixie) or newer, as root, with ~15 GB free and a network
# connection. Takes 20–60 minutes the first time.
#
#   sudo apt install live-build
#   sudo ./scripts/build-iso.sh            # -> out/cipher-<version>-amd64.iso
#   sudo ./scripts/build-iso.sh --nvidia   # include the proprietary NVIDIA driver
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ISO="$ROOT/iso"
VERSION=$(cat "$ROOT/VERSION")
NVIDIA=0
for arg in "$@"; do
  case "$arg" in
    --nvidia) NVIDIA=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "build-iso: run as root (sudo)" >&2; exit 1; }
command -v lb >/dev/null || { echo "build-iso: live-build missing — apt install live-build" >&2; exit 1; }

# 1. Package the desktop and drop it where the chroot hook expects it
DEB=$("$ROOT/scripts/build-deb.sh")
rm -rf "$ISO/config/includes.chroot/root/cipher-packages"
mkdir -p "$ISO/config/includes.chroot/root/cipher-packages"
cp "$DEB" "$ISO/config/includes.chroot/root/cipher-packages/"

# 2. Optional NVIDIA driver list
if [ "$NVIDIA" -eq 1 ]; then
  cp "$ISO/config/package-lists/nvidia.list.chroot.disabled" "$ISO/config/package-lists/nvidia.list.chroot"
else
  rm -f "$ISO/config/package-lists/nvidia.list.chroot"
fi

# 3. Brand the boot menus (GRUB for UEFI, isolinux for BIOS)
BRAND="$ROOT/packages/cipher-desktop/usr/share/cipher/branding/boot-background.png"
for bl in grub-pc isolinux; do
  src="/usr/share/live/build/bootloaders/$bl"
  dst="$ISO/config/bootloaders/$bl"
  [ -d "$src" ] || continue
  rm -rf "$dst"; mkdir -p "$dst"
  cp -a "$src/." "$dst/"
  rm -f "$dst/splash.svg"
  cp "$BRAND" "$dst/splash.png"
done

# 4. Build
cd "$ISO"
lb clean
lb config
lb build

mkdir -p "$ROOT/out"
OUT="$ROOT/out/cipher-${VERSION}-amd64.iso"
mv -f "$ISO"/cipher*.iso "$OUT"
(cd "$ROOT/out" && sha256sum "$(basename "$OUT")" > "$(basename "$OUT").sha256")
echo
echo "Done: $OUT"
echo "Test it:  qemu-system-x86_64 -enable-kvm -m 4G -smp 4 -vga virtio -display gtk,gl=on -cdrom $OUT"
