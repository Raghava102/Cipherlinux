import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

// "Good evening, VR" on the desktop, with a Continue card of recent files.
// Sits on the Bottom layer: above the wallpaper, under every window.
PanelWindow {
    id: win
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    // step aside while a full-screen overlay is open
    visible: Settings.greeting && Shell.overlay !== "apps" && Shell.overlay !== "menu" && Shell.overlay !== "themes"

    anchors { top: true; left: true }
    margins { top: (win.screen?.width ?? 1920) < 1300 ? 70 : 90; left: (win.screen?.width ?? 1920) < 1300 ? 48 : 96 }
    implicitWidth: 960
    implicitHeight: col.implicitHeight + 10
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "cipher-greeting"
    WlrLayershell.layer: WlrLayer.Bottom

    property string person: Quickshell.env("USER") ?? ""
    property var recent: []

    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 5 ? "Good night" : h < 12 ? "Good morning" : h < 17 ? "Good afternoon" : "Good evening";
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // Real name from the account (first word of GECOS), else the login name.
    Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const full = this.text.trim();
                // live-config names the live user "Debian Live user": not a person's name
                const n = /live user/i.test(full) ? "" : full.split(" ")[0];
                if (n) win.person = n;
                else if (win.person) win.person = win.person.charAt(0).toUpperCase() + win.person.slice(1);
            }
        }
    }

    // Recently used files (GTK/GNOME apps record them here).
    FileView {
        path: Quickshell.env("HOME") + "/.local/share/recently-used.xbel"
        watchChanges: true
        printErrors: false
        onLoaded: win.parse(text())
        onFileChanged: reload()
    }

    function parse(xml) {
        const out = [];
        const re = /<bookmark\s+href="([^"]+)"[^>]*?modified="([^"]+)"/g;
        let m;
        while ((m = re.exec(xml)) !== null) {
            if (!m[1].startsWith("file://")) continue;
            let path;
            try { path = decodeURIComponent(m[1].slice(7)); } catch (e) { continue; }
            out.push({ path, name: path.split("/").pop(), modified: new Date(m[2]) });
        }
        out.sort((a, b) => b.modified - a.modified);
        const seen = new Set();
        win.recent = out.filter(f => !seen.has(f.path) && seen.add(f.path)).slice(0, 3);
    }

    function ago(d) {
        const s = (Date.now() - d.getTime()) / 1000;
        if (s < 3600) return Math.max(1, Math.round(s / 60)) + " min ago";
        if (s < 86400) return Math.round(s / 3600) + "h ago";
        return Math.round(s / 86400) + "d ago";
    }

    function glyph(name) {
        const ext = (name.split(".").pop() || "").toLowerCase();
        if (["png", "jpg", "jpeg", "webp", "gif", "svg"].includes(ext)) return "image";
        if (["mp3", "flac", "ogg", "wav"].includes(ext)) return "volume-2";
        if (["mp4", "mkv", "webm", "mov"].includes(ext)) return "video";
        if (["py", "js", "ts", "c", "rs", "go", "sh", "yml", "yaml", "json", "qml"].includes(ext)) return "code";
        return "book-open";
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        Text {
            text: win.greeting + (win.person ? ", " + win.person : "")
            font.family: Theme.displayFont
            font.pixelSize: (win.screen?.width ?? 1920) < 1300 ? 46 : 64
            font.weight: Font.Normal
            color: Theme.text
            style: Text.Raised
            styleColor: Theme.alpha("#000000", Theme.light ? 0 : 0.25)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        Label {
            text: "Make room for what matters."
            font.pixelSize: 19
            color: Theme.muted
            Layout.bottomMargin: 18
        }

        Glass {
            Layout.preferredWidth: 520
            implicitHeight: cards.implicitHeight + 32
            radius: Theme.radius + 2

            ColumnLayout {
                id: cards
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 6
                    Label { text: "CONTINUE"; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.6; color: Theme.muted; Layout.fillWidth: true }
                    Label { text: "SUPER + SPACE to search"; font.pixelSize: 11; color: Theme.muted }
                }

                Repeater {
                    model: win.recent
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 56
                        radius: 16
                        color: hover.containsMouse || index === 0 ? Theme.tint : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 12
                            Rectangle {
                                implicitWidth: 38; implicitHeight: 38; radius: 12
                                color: Theme.alpha(Theme.accent, 0.18)
                                Icon { anchors.centerIn: parent; name: win.glyph(modelData.name); size: 18; color: Theme.accent }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Label { text: modelData.name; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                Label { text: win.ago(modelData.modified) + " · " + modelData.path.replace(Quickshell.env("HOME"), "~").split("/").slice(0, -1).join("/"); color: Theme.muted; font.pixelSize: Theme.fontSize - 2; Layout.fillWidth: true }
                            }
                            Icon { name: "chevron-right"; size: 15; color: Theme.muted }
                        }
                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["xdg-open", modelData.path])
                        }
                    }
                }

                Label {
                    visible: win.recent.length === 0
                    text: "Files you open will appear here."
                    color: Theme.muted
                    Layout.margins: 10
                }
            }
        }
    }
}
