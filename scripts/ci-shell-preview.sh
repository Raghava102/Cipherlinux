#!/bin/bash
# Render the Cipher shell headlessly and capture screenshots + logs.
# Runs inside a debian:trixie container (see .github/workflows/shell-preview.yml).
# Output: preview/*.png and preview/*.log
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=preview
rm -rf "$OUT"; mkdir -p "$OUT"
export DEBIAN_FRONTEND=noninteractive

echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" \
  > /etc/apt/sources.list.d/backports.list
apt-get update -q
apt-get install -y -q --no-install-recommends dpkg python3 ca-certificates >/dev/null

./scripts/build-deb.sh > "$OUT/build-deb.log" 2>&1 || { cat "$OUT/build-deb.log"; exit 1; }
DEB=$(ls out/cipher-desktop_*_all.deb)

# The real dependency set (Hyprland + Quickshell from backports), then a
# headless compositor (sway) and grim for screenshots.
apt-get install -y -q -t trixie-backports "./$DEB" > "$OUT/apt.log" 2>&1 || { tail -40 "$OUT/apt.log"; exit 1; }
apt-get install -y -q sway grim mesa-utils libgl1-mesa-dri papirus-icon-theme >> "$OUT/apt.log" 2>&1

dpkg-query -W -f '${Package} ${Version}\n' cipher-desktop hyprland quickshell sway > "$OUT/versions.log"

# A user-like environment
export HOME=/root USER=root
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
cp -r /etc/skel/.config "$HOME/" 2>/dev/null || true
mkdir -p "$HOME/.local/share"
cat > "$HOME/.local/share/recently-used.xbel" <<'XBEL'
<?xml version="1.0" encoding="UTF-8"?>
<xbel version="1.0">
  <bookmark href="file:///root/Documents/Capstone%20report.docx" added="2026-10-18T08:00:00Z" modified="2026-10-18T08:10:00Z" visited="2026-10-18T08:10:00Z"/>
  <bookmark href="file:///root/Study/ssh-brute-force.yml" added="2026-10-18T06:00:00Z" modified="2026-10-18T06:30:00Z" visited="2026-10-18T06:30:00Z"/>
  <bookmark href="file:///root/Pictures/Evening%20coast.png" added="2026-10-17T18:00:00Z" modified="2026-10-17T18:00:00Z" visited="2026-10-17T18:00:00Z"/>
</xbel>
XBEL
cipher-theme init > "$OUT/theme.log" 2>&1 || true
: > "$HOME/.config/cipher/current/hardware.conf"

# Headless sway at 1440x900
cat > /tmp/sway.conf <<'SWAY'
output HEADLESS-1 resolution 1440x900 position 0 0
default_border none
SWAY
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 \
  sway -c /tmp/sway.conf > "$OUT/sway.log" 2>&1 &
for _ in $(seq 1 50); do ls "$XDG_RUNTIME_DIR"/wayland-* >/dev/null 2>&1 && break; sleep 0.2; done
export WAYLAND_DISPLAY; WAYLAND_DISPLAY=$(basename "$(ls "$XDG_RUNTIME_DIR"/wayland-? | head -n1)")

export QT_QUICK_BACKEND=software QT_QPA_PLATFORM=wayland
qs -c cipher > "$OUT/shell.log" 2>&1 &
sleep 10

shot() { grim "$OUT/$1.png" 2>> "$OUT/grim.log"; }
ipc() { qs -c cipher ipc call "$@" >> "$OUT/ipc.log" 2>&1; sleep 2.5; }

shot 1-desktop
ipc controls toggle;      shot 2-quick-controls; ipc menu close
ipc menu apps;            shot 3-apps;           ipc menu close
ipc menu toggle;          shot 4-menu;           ipc menu close
ipc themes toggle;        shot 5-themes;         ipc menu close
cipher-theme set porcelain >> "$OUT/theme.log" 2>&1; sleep 3; shot 6-porcelain
cipher-theme set ember >> "$OUT/theme.log" 2>&1; sleep 3; shot 7-ember

qs -c cipher ipc show > "$OUT/ipc-targets.log" 2>&1 || true
kill %1 %2 2>/dev/null || true
ls -la "$OUT"
