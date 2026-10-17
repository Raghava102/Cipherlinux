pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Shared UI state and the IPC surface used by the cipher-* scripts and
// Hyprland keybindings (`qs -c cipher ipc call <target> <fn>`).
Singleton {
    id: root

    // Which overlay is open: "" | "menu" | "apps" | "themes" | "notifications" | "controls"
    property string overlay: ""
    // Optional menu path to open at, e.g. ["Style"]
    property var menuStart: []
    property bool dnd: false

    // The screen the user is working on, so overlays open where they look.
    readonly property var focusedScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === name) return screens[i];
        }
        return screens.length > 0 ? screens[0] : null;
    }

    function open(which, start) {
        root.menuStart = start ?? [];
        root.overlay = (root.overlay === which && (start ?? []).length === 0) ? "" : which;
    }
    function close() { root.overlay = ""; }

    // Run a shell command detached from the shell process.
    function run(cmd) {
        if (!cmd) return;
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // Open the terminal, optionally running a command and holding the window open.
    function terminal(cmd) {
        const term = Settings.terminal;
        if (!cmd) { Quickshell.execDetached([term]); return; }
        Quickshell.execDetached([term, "-e", "sh", "-c", cmd + "; printf '\\n[done] press Enter to close'; read _"]);
    }

    IpcHandler {
        target: "menu"
        function toggle(): void { root.open("menu", []); }
        function apps(): void { root.open("apps", []); }
        function open(path: string): void { root.open("menu", path.length ? path.split("/") : []); }
        function close(): void { root.close(); }
    }

    IpcHandler {
        target: "controls"
        function toggle(): void { root.open("controls", []); }
    }

    IpcHandler {
        target: "themes"
        function toggle(): void { root.open("themes", []); }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.open("notifications", []); }
        function dnd(): void { root.dnd = !root.dnd; }
        function isDnd(): bool { return root.dnd; }
    }
}
