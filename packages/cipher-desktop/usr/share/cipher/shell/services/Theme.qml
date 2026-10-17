pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active Cipher theme. `cipher-theme set <name>` writes
// ~/.config/cipher/current/theme.json and the whole shell re-flows live.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string configDir: home + "/.config/cipher"
    readonly property string themeFile: configDir + "/current/theme.json"

    // Fallback palette = the "cipher" theme, used until theme.json loads.
    property string name: "cipher"
    property string title: "Cipher"
    property color bg: "#0b0f14"
    property color surface: "#121821"
    property color overlay: "#1a2230"
    property color border: "#243041"
    property color text: "#d6e2ea"
    property color muted: "#6b7d8c"
    property color accent: "#2de2a6"
    property color accent2: "#3fb6ff"
    property color red: "#ff5c7a"
    property color yellow: "#ffcc66"
    property color green: "#2de2a6"
    property string wallpaper: ""
    property bool light: false

    // Shape + type, overridable per user in shell.json
    readonly property int radius: Settings.sharpCorners ? 0 : 12
    readonly property int radiusSmall: Settings.sharpCorners ? 0 : 8
    readonly property string font: Settings.font
    readonly property int fontSize: Settings.fontSize
    readonly property int gap: 8

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function apply(raw) {
        let t;
        try { t = JSON.parse(raw); } catch (e) { console.warn("cipher: bad theme.json", e); return; }
        const hex = /^#[0-9a-fA-F]{6}$/;
        const keys = ["bg", "surface", "overlay", "border", "text", "muted",
                      "accent", "accent2", "red", "yellow", "green"];
        for (const k of keys) {
            if (t.colors && hex.test(t.colors[k] ?? "")) root[k] = t.colors[k];
        }
        root.name = t.name ?? root.name;
        root.title = t.title ?? root.name;
        root.light = t.light === true;
        root.wallpaper = t.wallpaper ?? "";
    }

    function reload() { file.reload(); }

    FileView {
        id: file
        path: root.themeFile
        watchChanges: true
        printErrors: false
        onLoaded: root.apply(text())
        onFileChanged: reload()
    }

    IpcHandler {
        target: "theme"
        function reload(): void { root.reload(); }
        function current(): string { return root.name; }
    }
}
