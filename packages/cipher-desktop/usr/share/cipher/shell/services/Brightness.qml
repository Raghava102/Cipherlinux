pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen backlight via brightnessctl. `available` is false on desktops/VMs.
Singleton {
    id: root
    property bool available: false
    property real value: 0      // 0..1

    function refresh() { proc.running = true; }
    function set(v) {
        const pct = Math.round(Math.max(0.02, Math.min(1, v)) * 100);
        root.value = pct / 100;
        Quickshell.execDetached(["brightnessctl", "-q", "set", pct + "%"]);
    }

    Process {
        id: proc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                // device,class,current,percent%,max
                const f = this.text.trim().split(",");
                root.available = f.length >= 5 && f[1] === "backlight";
                if (root.available) root.value = parseInt(f[3]) / 100;
            }
        }
    }

    Timer { interval: 20000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
