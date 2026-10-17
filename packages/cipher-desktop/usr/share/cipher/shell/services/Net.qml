pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lightweight NetworkManager status, polled through nmcli.
Singleton {
    id: root

    property string kind: "none"      // "wifi" | "ethernet" | "none"
    property string connection: ""
    property int signal: 0

    readonly property string icon: kind === "ethernet" ? "ethernet-port"
                                 : kind === "wifi" ? "wifi" : "wifi-off"

    function parse(text) {
        let kind = "none", conn = "";
        for (const line of text.trim().split("\n")) {
            // TYPE:STATE:CONNECTION. TYPE and STATE never contain ':', the
            // connection name may (nmcli -t escapes it as '\:').
            const a = line.indexOf(":");
            const b = line.indexOf(":", a + 1);
            if (a < 0 || b < 0) continue;
            const type = line.slice(0, a), state = line.slice(a + 1, b), name = line.slice(b + 1);
            if (state !== "connected") continue;
            if (type === "ethernet") { kind = "ethernet"; conn = name; break; }
            if (type === "wifi" && kind === "none") { kind = "wifi"; conn = name; }
        }
        root.kind = kind;
        root.connection = conn.replace(/\\:/g, ":");
        if (kind === "wifi") signalProc.running = true;
    }

    Process {
        id: statusProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }

    Process {
        id: signalProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.split("\n").find(l => l.startsWith("*"));
                root.signal = line ? parseInt(line.split(":")[1]) || 0 : 0;
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }
}
