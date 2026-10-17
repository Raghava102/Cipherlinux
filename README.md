# Cipher

A Debian-based Hyprland desktop in the spirit of **Omarchy 4 "Quattro"**: one
Quickshell process draws the whole desktop (bar, unified app + command menu,
theme switcher, notifications, on-screen displays, background and lock screen),
and a single command re-themes everything live.

- **Base:** Debian 13 "trixie" (stable) + `trixie-backports`
- **Compositor:** Hyprland 0.54 (from trixie-backports)
- **Shell:** Quickshell 0.3 (from trixie-backports) running the `cipher` shell config
- **Login:** greetd + tuigreet · **Installer:** Calamares · **Boot:** Plymouth splash
- **Themes:** Cipher (default), Tokyo Night, Catppuccin, Gruvbox, Nord, Rosé Pine, Paper (light)

## What's in the box

| Piece | Where | Replaces (Omarchy 3 era) |
|---|---|---|
| Bar: logo, workspaces, window title, clock, tray, network, volume, battery, DND, notifications, power | `shell/bar/` | Waybar |
| Menu: apps + nested commands, fuzzy/acronym search across every level | `shell/menu/`, `menu.json` | Walker + Omarchy menu |
| Theme switcher carousel with live previews | `shell/themes/` | — |
| Notification daemon + center with history, do-not-disturb | `shell/notifications/` | Mako |
| Volume / brightness / mic OSD | `shell/osd/` | SwayOSD |
| Lock screen (ext-session-lock + PAM) | `shell/lock/` | hyprlock (kept only as fallback) |
| Background with crossfade | `shell/background/` | swaybg |
| Theme engine: shell, Hyprland borders, foot, btop, GTK dark/light | `cipher-theme` | — |

The shell lives in `/usr/share/cipher/shell` and is linked to
`/etc/xdg/quickshell/cipher`, so `qs -c cipher` finds it.

## Two ways to get it

### 1. Install on an existing Debian 13 (quickest)

Install a minimal Debian 13 (uncheck every desktop in the installer, keep
"standard system utilities"), log in as your user, then:

```bash
sudo apt install git
git clone <your-repo-url> cipher && cd cipher
./scripts/install-on-debian.sh --greetd
```

Reboot and pick the **Cipher** session.

### 2. Build the live ISO

On a Debian 13 machine (or VM) with ~15 GB free:

```bash
sudo apt install live-build
sudo ./scripts/build-iso.sh            # add --nvidia to bake in the NVIDIA driver
```

You get `out/cipher-<version>-amd64.iso` and its `.sha256`. Test it before
touching real hardware:

```bash
qemu-system-x86_64 -enable-kvm -m 4G -smp 4 -vga virtio -display gtk,gl=on \
  -cdrom out/cipher-0.1.0-amd64.iso
```

The live session logs straight into Cipher (user `cipher`, password `live`).
Search **Install** in the menu to run Calamares.

## Keys

| Keys | Action |
|---|---|
| `SUPER + SPACE` | Cipher menu (apps + every command) |
| `SUPER + ALT + SPACE` | Apps only |
| `SUPER + SHIFT + CTRL + SPACE` | Theme switcher |
| `SUPER + CTRL + SPACE` | Next background |
| `SUPER + ESC` | System menu (lock, suspend, restart, power profile…) |
| `SUPER + CTRL + L` | Lock |
| `SUPER + K` | Every keybinding, searchable |
| `SUPER + RETURN` / `B` / `E` | Terminal / browser / files |
| `SUPER + W` / `F` / `T` | Close / fullscreen / float |
| `SUPER + 1…0`, `SUPER + SHIFT + 1…0` | Go to / move to workspace |
| `SUPER + N`, `SUPER + CTRL + N` | Notifications, do-not-disturb |
| `SUPER + CTRL + V` / `E` | Clipboard history / emoji |
| `PRINT`, `SHIFT + PRINT`, `SUPER + SHIFT + R` | Screenshot region / screen, record |

Descriptions come from `bindd` lines, so your own bindings with descriptions
show up in `SUPER + K` automatically.

## Make it yours

Everything personal lives in your home folder; package updates never touch it.

| File | What it does |
|---|---|
| `~/.config/hypr/hyprland.conf` | Monitors, keyboard layout, your binds and looks. Sourced after Cipher's defaults. |
| `~/.config/cipher/shell.json` | Bar position, transparency, clock format, corners, font, terminal. Live-reloaded. |
| `~/.config/cipher/menu.json` | Your own menu entries (merged into the system menu). Live-reloaded. |
| `~/.config/cipher/themes/<name>/` | Your own themes: a `theme.json` + `backgrounds/`. |
| `~/.config/cipher/backgrounds/<theme>/` | Extra backgrounds for a built-in theme. |
| `~/.config/quickshell/cipher/` | A full copy of the shell, if you want to hack on the QML itself. |

Command line:

```bash
cipher-theme list | set nord | current
cipher-bg next | prev | set ~/Pictures/wall.jpg
cipher-shell-set barPosition bottom      # barTransparent, clock24h, sharpCorners, font, fontSize, terminal
cipher-shell restart | logs
cipher-ipc menu open System              # talk to the shell; `qs -c cipher ipc show` lists everything
```

### A new theme

```bash
mkdir -p ~/.config/cipher/themes/mytheme/backgrounds
cp /usr/share/cipher/themes/cipher/theme.json ~/.config/cipher/themes/mytheme/
# edit name/title/colors (each must be #rrggbb), drop images into backgrounds/
cipher-theme set mytheme
```

To generate matching backgrounds for a theme you add to the repo:
`python3 scripts/gen-art.py mytheme`.

## Repository layout

```
packages/cipher-desktop/      the .deb (built by scripts/build-deb.sh)
  usr/share/cipher/shell/     Quickshell config (QML)
  usr/share/cipher/default/   Hyprland + hypridle defaults
  usr/share/cipher/themes/    theme.json + generated backgrounds
  usr/share/cipher/templates/ files rendered per theme (Hyprland, foot, btop)
  usr/bin/cipher-*            helper commands
  etc/skel/                   per-user starting configs
iso/                          live-build config (auto/, package lists, hooks)
scripts/                      build-deb.sh, build-iso.sh, install-on-debian.sh, gen-art.py
```

## Notes and limits (v0.1)

- **NVIDIA (e.g. RTX 3050):** use `--nvidia` for the ISO, or follow the hint the
  installer script prints. `cipher-start` adds the NVIDIA environment for
  Hyprland automatically when the driver is loaded.
- **Hyprland config syntax:** written for Hyprland 0.54 (hyprlang). Omarchy 4's
  configs are Lua for Hyprland 0.56, which Debian doesn't ship yet.
- **Not yet built:** Omarchy 4's audio/network/Bluetooth control panels (the bar
  opens pavucontrol, nmtui and blueman instead), the drag-to-any-edge bar
  (top/bottom only), fingerprint unlock, and Calamares branding.
- **os-release** still says Debian: Cipher is a Debian blend, not a fork.

## Credits

Inspired by [Omarchy](https://github.com/basecamp/omarchy) (MIT) — no Omarchy
code or artwork is included. Icons: [Lucide](https://lucide.dev) (ISC), shipped as
a subset font in `shell/fonts/`. See `CREDITS.md`.
