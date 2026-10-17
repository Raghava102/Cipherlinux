pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Cipher Shield status: is a firewall active? (ufw, firewalld or nftables)
Singleton {
    id: root
    property string firewall: "unknown"
    readonly property bool protectedNow: firewall !== "none" && firewall !== "unknown"

    function refresh() { proc.running = true; }

    Process {
        id: proc
        command: ["sh", "-c", "for s in ufw firewalld nftables; do systemctl is-active --quiet \"$s\" && { echo \"$s\"; exit 0; }; done; echo none"]
        stdout: StdioCollector { onStreamFinished: root.firewall = this.text.trim() || "none" }
    }

    Timer { interval: 30000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
