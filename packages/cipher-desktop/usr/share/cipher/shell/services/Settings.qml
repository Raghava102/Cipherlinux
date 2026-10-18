pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Per-machine shell preferences: ~/.config/cipher/shell.json
// Survives theme switching; edits re-flow the shell live.
Singleton {
    id: root

    property string barPosition: "top"     // "top" | "bottom"
    property bool barTransparent: false
    property bool clock24h: true
    property bool sharpCorners: false
    property string font: "Plus Jakarta Sans"
    property int fontSize: 13
    property string terminal: "foot"
    property int barHeight: 40
    // Aurora
    property string dockPosition: "bottom"   // "bottom" | "left" | "right" | "hidden"
    property int dockIconSize: 48
    property bool dockMagnify: true
    // "a|b" = first one that's installed
    property var dockPinned: ["firefox-esr|firefox|chromium", "org.gnome.Nautilus|thunar", "foot", "org.gnome.TextEditor|org.gnome.gedit", "btop", "org.gnome.Settings", "org.gnome.Software"]
    // launcher entries nobody wants to see
    property var hiddenApps: ["footclient", "foot-server", "thunar-settings", "thunar-volman-settings", "thunar-bulk-rename", "blueman-adapters", "system-config-printer", "kdesystemsettings", "systemsettings", "org.gnome.Extensions", "nm-connection-editor", "display-im6.q16", "debian-uxterm", "debian-xterm", "htop", "vim", "nvim", "calamares-install-debian", "hyprland-share-picker", "qt5ct", "qt6ct", "yelp"]
    property var workspaceNames: ["Home", "Study", "Create"]
    property bool greeting: true

    readonly property string path: Quickshell.env("HOME") + "/.config/cipher/shell.json"

    function apply(raw) {
        let s;
        try { s = JSON.parse(raw); } catch (e) { console.warn("cipher: bad shell.json", e); return; }
        if (s.barPosition === "top" || s.barPosition === "bottom") root.barPosition = s.barPosition;
        if (typeof s.barTransparent === "boolean") root.barTransparent = s.barTransparent;
        if (typeof s.clock24h === "boolean") root.clock24h = s.clock24h;
        if (typeof s.sharpCorners === "boolean") root.sharpCorners = s.sharpCorners;
        if (typeof s.font === "string" && s.font.length > 0) root.font = s.font;
        if (Number.isInteger(s.fontSize) && s.fontSize >= 9 && s.fontSize <= 20) root.fontSize = s.fontSize;
        if (typeof s.terminal === "string" && s.terminal.length > 0) root.terminal = s.terminal;
        if (["bottom", "left", "right", "hidden"].includes(s.dockPosition)) root.dockPosition = s.dockPosition;
        if (Number.isInteger(s.dockIconSize) && s.dockIconSize >= 32 && s.dockIconSize <= 72) root.dockIconSize = s.dockIconSize;
        if (typeof s.dockMagnify === "boolean") root.dockMagnify = s.dockMagnify;
        if (Array.isArray(s.dockPinned)) root.dockPinned = s.dockPinned.filter(x => typeof x === "string");
        if (Array.isArray(s.hiddenApps)) root.hiddenApps = root.hiddenApps.concat(s.hiddenApps.filter(x => typeof x === "string"));
        if (Array.isArray(s.workspaceNames)) root.workspaceNames = s.workspaceNames.filter(x => typeof x === "string");
        if (typeof s.greeting === "boolean") root.greeting = s.greeting;
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onLoaded: root.apply(text())
        onFileChanged: reload()
    }
}
