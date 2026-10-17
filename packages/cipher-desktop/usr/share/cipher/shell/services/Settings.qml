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
    property string font: "JetBrains Mono"
    property int fontSize: 13
    property string terminal: "foot"
    property int barHeight: 34

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
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onLoaded: root.apply(text())
        onFileChanged: reload()
    }
}
