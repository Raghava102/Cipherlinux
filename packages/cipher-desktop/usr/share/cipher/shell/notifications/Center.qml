import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Notification center: replayable history (including what do-not-disturb
// silenced), a DND switch and clear-all.
PanelWindow {
    id: win
    readonly property bool active: Shell.overlay === "notifications"
    visible: active
    screen: Shell.focusedScreen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "cipher-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function ago(d) {
        const s = Math.floor((Date.now() - d.getTime()) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m";
        if (s < 86400) return Math.floor(s / 3600) + "h";
        return Math.floor(s / 86400) + "d";
    }

    MouseArea { anchors.fill: parent; onClicked: Shell.close() }

    Rectangle {
        id: panel
        focus: true
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: 380
        radius: Theme.radius
        color: Theme.glassStrong
        border.color: Theme.glassEdge
        Keys.onEscapePressed: Shell.close()

        MouseArea { anchors.fill: parent }

        Row {
            id: head
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 8

            Label {
                text: "Notifications"
                font.bold: true
                font.pixelSize: Theme.fontSize + 2
                width: parent.width - dnd.width - clear.width - 16
            }
            BarButton {
                id: dnd
                icon: Shell.dnd ? "bell-off" : "bell"
                label: Shell.dnd ? "Silenced" : "DND"
                tint: Shell.dnd ? Theme.yellow : Theme.text
                onClicked: Shell.dnd = !Shell.dnd
            }
            BarButton {
                id: clear
                icon: "trash-2"
                onClicked: Notifs.clearHistory()
            }
        }

        ListView {
            anchors.top: head.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            clip: true
            spacing: 8
            model: Notifs.history

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: col.implicitHeight + 20
                radius: Theme.radiusSmall
                color: Theme.surface

                Column {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    spacing: 2
                    Row {
                        width: parent.width
                        Label {
                            width: parent.width - when.width
                            text: modelData.appName
                            color: Theme.muted
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Label {
                            id: when
                            text: win.ago(modelData.time)
                            color: Theme.muted
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                    Label { width: parent.width; text: modelData.summary; font.bold: true; wrapMode: Text.Wrap }
                    Label {
                        width: parent.width
                        visible: text !== ""
                        text: modelData.body
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 5
                        color: Theme.alpha(Theme.text, 0.85)
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: Notifs.history.length === 0
                spacing: 8
                Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "bell"; size: 28; color: Theme.muted }
                Label { text: "All caught up"; color: Theme.muted }
            }
        }
    }

    onActiveChanged: if (active) panel.forceActiveFocus()
}
