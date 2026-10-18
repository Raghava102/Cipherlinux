#!/bin/bash
# Open every app in the Cipher app grid the way the dock/menu does
# (cipher-open-app) and record whether a window appears.
# Runs inside debian:trixie (see .github/workflows/app-test.yml).
# Output: apptest/results.md, apptest/results.tsv, apptest/shots/*.png
set -u
cd "$(dirname "$0")/.." || exit 1
OUT=$PWD/apptest
rm -rf "$OUT"; mkdir -p "$OUT/shots"
export DEBIAN_FRONTEND=noninteractive

echo "deb http://deb.debian.org/debian trixie-backports main contrib non-free non-free-firmware" \
  > /etc/apt/sources.list.d/backports.list
sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
apt-get update -q >/dev/null
apt-get install -y -q --no-install-recommends dpkg python3 ca-certificates >/dev/null

# The ISO's desktop packages (not the kernel, firmware, live system, installer)
PKGS=$(grep -v -E '^\s*(#|$)' iso/config/package-lists/cipher.list.chroot \
  | grep -v -E '^(live-|calamares|plymouth|linux-image|firmware|.*microcode|open-vm-tools|spice-vdagent|zram-tools)')
echo "installing: $PKGS" > "$OUT/apt.log"
apt-get install -y -q $PKGS >> "$OUT/apt.log" 2>&1 || { tail -30 "$OUT/apt.log"; echo "::warning::some packages failed to install"; }
./scripts/build-deb.sh >> "$OUT/apt.log" 2>&1
apt-get install -y -q -t trixie-backports ./out/cipher-desktop_*_all.deb >> "$OUT/apt.log" 2>&1 || { tail -30 "$OUT/apt.log"; exit 1; }
apt-get install -y -q sway xwayland grim jq dbus dbus-user-session libgtk-3-bin >> "$OUT/apt.log" 2>&1
/usr/lib/cipher/tidy-apps
dpkg -l | awk '/^ii/{print $2" "$3}' > "$OUT/packages.txt"

# system bus (polkit, NetworkManager, accounts-daemon... activate on demand)
mkdir -p /run/dbus; dbus-daemon --system --fork 2>> "$OUT/apt.log"

useradd -m -s /bin/bash cipher 2>/dev/null
U=/home/cipher; RT=/run/user/$(id -u cipher)
mkdir -p "$RT"; chown cipher: "$RT"; chmod 700 "$RT"
chown -R cipher: "$OUT"

cat > /tmp/run-tests.sh <<'TEST'
#!/bin/bash
set -u
OUT=$1
cat > /tmp/sway.conf <<'SWAY'
output HEADLESS-1 resolution 1440x900 position 0 0
default_border none
xwayland enable
SWAY
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -c /tmp/sway.conf > "$OUT/sway.log" 2>&1 &
for _ in $(seq 1 50); do ls "$XDG_RUNTIME_DIR"/wayland-* >/dev/null 2>&1 && break; sleep 0.2; done
export WAYLAND_DISPLAY; WAYLAND_DISPLAY=$(basename "$(ls "$XDG_RUNTIME_DIR"/wayland-? | head -n1)")
export SWAYSOCK; SWAYSOCK=$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock | head -n1)
# the Cipher session's environment
export XDG_CURRENT_DESKTOP=Hyprland XDG_SESSION_DESKTOP=cipher XDG_SESSION_TYPE=wayland
export QT_QPA_PLATFORM="wayland;xcb" GDK_BACKEND="wayland,x11" MOZ_ENABLE_WAYLAND=1
export DISPLAY=:0
# like the session's autostart.conf: D-Bus-started apps get the display
dbus-update-activation-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP GDK_BACKEND QT_QPA_PLATFORM MOZ_ENABLE_WAYLAND
export QT_QUICK_BACKEND=software   # what the shell has in a VM; the launcher must drop it
cipher-theme init >/dev/null 2>&1

wins() { swaymsg -t get_tree 2>/dev/null | jq -r '[.. | objects | select((.pid? // 0) > 0) | .pid] | unique | .[]'; }

printf 'app\tname\tresult\tseconds\tnote\n' > "$OUT/results.tsv"
for f in /usr/share/applications/*.desktop; do
  grep -q '^Type=Application' "$f" || continue
  grep -q -E '^(NoDisplay|Hidden)=true' "$f" && continue
  grep -q '^Terminal=true' "$f" && term=1 || term=0
  id=$(basename "$f" .desktop)
  name=$(sed -n 's/^Name=//p' "$f" | head -n1)
  before=$(wins)
  : > "$XDG_RUNTIME_DIR/apps.log"
  t0=$(date +%s)
  XDG_STATE_HOME=/tmp/st-$id cipher-open-app "$id" > "/tmp/launch-$id.log" 2>&1
  rc=$?
  result=FAIL; note=""
  for i in $(seq 1 25); do
    sleep 1
    new=$(comm -13 <(echo "$before" | sort) <(wins | sort))
    if [ -n "$new" ]; then result=PASS; break; fi
  done
  dt=$(( $(date +%s) - t0 ))
  [ "$rc" -ne 0 ] && note="launcher exit $rc; "
  if [ "$result" = PASS ]; then
    sleep 2; grim -s 0.5 "$OUT/shots/$id.png" 2>/dev/null
    for p in $new; do swaymsg "[pid=$p] kill" >/dev/null 2>&1; kill "$p" 2>/dev/null; done
  else
    note="$note$(cat /tmp/st-$id/cipher/apps.log /tmp/launch-$id.log 2>/dev/null | grep -v ' open ' | tr '\n' ' ' | tail -c 300)"
  fi
  [ "$term" = 1 ] && note="terminal app; $note"
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$name" "$result" "$dt" "$note" >> "$OUT/results.tsv"
  echo "$result $id ($name) ${dt}s"
  # stop leftovers so memory doesn't pile up
  exe=$(sed -n 's/^Exec=//p' "$f" | head -n1 | awk '{print $1}' | xargs -r basename 2>/dev/null)
  [ -n "$exe" ] && [ "$exe" != env ] && pkill -f "$exe" 2>/dev/null
  sleep 1
done
TEST
chmod +x /tmp/run-tests.sh
runuser -u cipher -- env -i HOME=$U USER=cipher LOGNAME=cipher PATH=/usr/local/bin:/usr/bin:/bin \
  XDG_RUNTIME_DIR=$RT LANG=C.UTF-8 dbus-run-session -- /tmp/run-tests.sh "$OUT" 2>&1 | tee "$OUT/run.log"

{
  echo "# Cipher app test"
  echo
  echo "| App | Result | Time | Note |"
  echo "|---|---|---|---|"
  tail -n +2 "$OUT/results.tsv" | awk -F'\t' '{printf "| %s (`%s`) | %s | %ss | %s |\n", $2, $1, $3, $4, $5}'
} > "$OUT/results.md"
echo "PASS $(grep -c $'\tPASS\t' "$OUT/results.tsv")  FAIL $(grep -c $'\tFAIL\t' "$OUT/results.tsv")"
