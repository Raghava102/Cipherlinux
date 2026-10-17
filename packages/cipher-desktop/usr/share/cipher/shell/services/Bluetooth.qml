pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bluetooth power and first connected device, via bluetoothctl.
Singleton {
    id: root
    property bool available: false
    property bool powered: false
    property string device: ""

    function refresh() { proc.running = true; }
    function toggle() {
        Quickshell.execDetached(["bluetoothctl", "power", root.powered ? "off" : "on"]);
        root.powered = !root.powered;
        delay.restart();
    }

    Process {
        id: proc
        command: ["sh", "-c", "command -v bluetoothctl >/dev/null || { echo none; exit; }; bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off; bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                root.available = lines[0] !== "none" && lines[0] !== "";
                root.powered = lines[0] === "on";
                root.device = (lines[1] || "").trim();
            }
        }
    }

    Timer { id: delay; interval: 1500; onTriggered: root.refresh() }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
