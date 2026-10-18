pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The active Cipher theme. `cipher-theme set <name>` writes
// ~/.config/cipher/current/theme.json and the whole shell re-flows live.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // Software rendering (virtual machines without a usable GPU): every
    // animation frame is drawn by the CPU, so motion makes it stutter.
    // In that mode transitions are instant, which feels much snappier.
    readonly property bool lite: Quickshell.env("QT_QUICK_BACKEND") === "software"
    function ms(d) { return lite ? 0 : d }
    readonly property string configDir: home + "/.config/cipher"
    readonly property string themeFile: configDir + "/current/theme.json"

    // Fallback palette = the "aurora" theme, used until theme.json loads.
    property string name: "aurora"
    property string title: "Aurora"
    property color bg: "#0b1518"
    property color surface: "#101c20"
    property color overlay: "#16262a"
    property color border: "#233a3e"
    property color text: "#e8f1ef"
    property color muted: "#9fb4b5"
    property color accent: "#6ee7c5"
    property color accent2: "#f6c58f"
    property color red: "#f07a6a"
    property color yellow: "#f6c58f"
    property color green: "#6ee7c5"
    property string wallpaper: ""
    property bool light: false

    // Shape + type, overridable per user in shell.json
    readonly property int radius: Settings.sharpCorners ? 0 : 22
    readonly property int radiusSmall: Settings.sharpCorners ? 0 : 14
    readonly property int radiusPill: Settings.sharpCorners ? 0 : 999
    readonly property string font: Settings.font
    readonly property string displayFont: "Fraunces"

    // Aurora glass: translucent panels with a hairline edge
    readonly property color glass: light ? Qt.rgba(1, 1, 1, 0.72) : alpha(bg, 0.72)
    readonly property color glassStrong: light ? Qt.rgba(0.99, 0.98, 0.97, 0.96) : alpha(bg, 0.94)
    readonly property color glassEdge: light ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.09)
    readonly property color hover: light ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.07)
    readonly property color tint: alpha(accent, light ? 0.14 : 0.16)
    readonly property color onAccent: light ? "#ffffff" : "#06231d"
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
