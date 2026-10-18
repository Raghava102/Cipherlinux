import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

// On-screen display for volume / brightness / mic (replaces swayosd).
// Volume is picked up automatically from PipeWire; brightness is pushed by
// `cipher-osd` (cipher-ipc osd show brightness 40).
PanelWindow {
    id: win

    property string kind: "volume"
    property real value: 0          // 0..1
    property bool muted: false
    property bool shown: false

    visible: shown
    screen: Shell.focusedScreen
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 300
    implicitHeight: 52
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "cipher-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    function show(kind, value, muted) {
        win.kind = kind;
        win.value = Math.max(0, Math.min(1, value));
        win.muted = muted === true;
        win.shown = true;
        hide.restart();
    }

    readonly property string icon: {
        if (kind === "brightness") return "sun";
        if (kind === "mic") return "mic";
        if (muted || value <= 0.001) return "volume-x";
        return value < 0.5 ? "volume-1" : "volume-2";
    }

    Timer { id: hide; interval: 1400; onTriggered: win.shown = false }

    IpcHandler {
        target: "osd"
        function show(kind: string, percent: int): void { win.show(kind, percent / 100, false); }
        function mute(kind: string, muted: bool): void { win.show(kind, win.value, muted); }
    }

    Loader {
        // isolated so the OSD still works for brightness without PipeWire
        source: "VolumeWatcher.qml"
        onLoaded: item.volumeEvent.connect((v, m) => win.show("volume", v, m))
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.glassStrong
        border.color: Theme.glassEdge
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Icon {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            name: win.icon
            size: 18
            color: win.muted ? Theme.muted : Theme.accent
        }

        Rectangle {
            id: track
            anchors.left: icon.right
            anchors.right: pct.left
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.overlay

            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * (win.muted ? 0 : win.value)
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }

        Label {
            id: pct
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignRight
            text: win.muted ? "off" : Math.round(win.value * 100)
            color: Theme.muted
        }
    }
}
