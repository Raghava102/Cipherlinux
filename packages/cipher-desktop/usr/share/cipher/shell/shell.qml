//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma IconTheme Papirus-Dark

// Cipher shell — the whole Cipher desktop in one Quickshell process:
// background, bar, menu/launcher, theme switcher, notifications, OSD, lock.
//
// Run:        qs -c cipher
// Talk to it: qs -c cipher ipc call <target> <function> [args]
//             (see `qs -c cipher ipc show` for every target)
// Customize:  copy /usr/share/cipher/shell to ~/.config/quickshell/cipher
//             and it takes precedence. Prefer ~/.config/cipher/shell.json
//             for simple tweaks so updates keep flowing.

import QtQuick
import Quickshell
import qs.services
import qs.bar
import qs.background
import qs.menu
import qs.themes
import qs.notifications
import qs.osd
import qs.dock
import qs.controls
import qs.desktop

ShellRoot {
    id: root

    FontLoader { source: Qt.resolvedUrl("fonts/lucide.ttf") }

    // Touch the singletons so they start with the shell.
    readonly property var _services: [Theme, Settings, Shell, Notifs, Net, MenuData, Shield, Bluetooth, Brightness]

    Variants {
        model: Quickshell.screens
        Background {}
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        Dock {}
    }

    Greeting {}
    QuickControls {}

    Menu {}
    ThemeSwitcher {}
    Popups {}
    Center {}
    Osd {}

    // The lock screen depends on the PAM service module; isolate it so a
    // missing module can't take the rest of the shell down. cipher-lock
    // falls back to hyprlock if this target isn't answering.
    LazyLoader {
        active: true
        source: Qt.resolvedUrl("lock/Lock.qml")
    }
}
