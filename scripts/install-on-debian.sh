#!/bin/bash
# Turn an existing Debian 13 (trixie) install into Cipher — no ISO needed.
# Install a minimal Debian first (no desktop), log in as your user, then:
#
#   ./scripts/install-on-debian.sh             # install Cipher for this user
#   ./scripts/install-on-debian.sh --greetd    # also switch the login screen to tuigreet
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GREETD=0
for arg in "$@"; do
  case "$arg" in
    --greetd) GREETD=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -ne 0 ] || { echo "Run this as your normal user (it uses sudo when needed)." >&2; exit 1; }
. /etc/os-release
case "${VERSION_CODENAME:-}" in
  trixie) ;;
  forky|sid) echo "Note: $VERSION_CODENAME detected — Hyprland/Quickshell come from the main archive there." ;;
  *) echo "Cipher targets Debian 13 (trixie); found '${PRETTY_NAME:-unknown}'." >&2; exit 1 ;;
esac

step() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }

if [ "${VERSION_CODENAME}" = "trixie" ]; then
  step "Enabling trixie-backports (Hyprland 0.54 and Quickshell 0.3 live there)"
  echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" \
    | sudo tee /etc/apt/sources.list.d/trixie-backports.list >/dev/null
  BP=(-t trixie-backports)
else
  BP=()
fi
sudo apt-get update

step "Installing Hyprland and Quickshell"
sudo apt-get install -y "${BP[@]}" hyprland hyprland-guiutils hypridle hyprlock hyprpolkitagent \
  xdg-desktop-portal-hyprland quickshell
sudo apt-get install -y "${BP[@]}" hyprpicker || echo "(hyprpicker not available — color picker disabled)"

step "Building and installing cipher-desktop"
sudo apt-get install -y dpkg
DEB=$("$ROOT/scripts/build-deb.sh")
sudo apt-get install -y "$DEB"

step "Setting up your configs (existing files are kept)"
copy_if_missing() {
  local rel=$1
  if [ -e "$HOME/$rel" ]; then
    echo "  keep   ~/$rel (yours)"
  else
    mkdir -p "$(dirname "$HOME/$rel")"
    cp "/etc/skel/$rel" "$HOME/$rel"
    echo "  added  ~/$rel"
  fi
}
for f in .config/hypr/hyprland.conf .config/foot/foot.ini .config/btop/btop.conf \
         .config/cipher/shell.json .config/cipher/menu.json; do
  copy_if_missing "$f"
done
cipher-theme init

if [ "$GREETD" -eq 1 ]; then
  step "Switching the login screen to greetd + tuigreet"
  sudo apt-get install -y greetd tuigreet
  sudo tee /etc/greetd/config.toml >/dev/null <<'CONF'
[terminal]
vt = 7

[default_session]
command = "tuigreet --time --remember --remember-user-session --asterisks --greeting 'Cipher' --sessions /usr/share/wayland-sessions --cmd cipher-start"
user = "_greetd"
CONF
  for dm in gdm3 sddm lightdm; do
    systemctl is-enabled "$dm" >/dev/null 2>&1 && sudo systemctl disable "$dm" || true
  done
  sudo systemctl enable greetd
fi

if lspci 2>/dev/null | grep -qi 'nvidia' && ! dpkg -s nvidia-driver >/dev/null 2>&1; then
  echo
  echo "NVIDIA GPU found. For Hyprland, install the proprietary driver:"
  echo "  sudo apt install linux-headers-amd64 nvidia-kernel-dkms nvidia-driver firmware-nvidia-gsp"
  echo "  echo 'options nvidia-drm modeset=1 fbdev=1' | sudo tee /etc/modprobe.d/nvidia-drm.conf"
fi

step "Done"
echo "Log out and pick the 'Cipher' session (or run 'cipher-start' from a TTY)."
echo "SUPER + SPACE opens the menu, SUPER + K lists every shortcut."
