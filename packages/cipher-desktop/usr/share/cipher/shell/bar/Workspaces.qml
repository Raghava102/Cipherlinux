import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.components

// Workspace pills: always shows 1-5, more as they get used.
// The focused workspace stretches into an accent-colored pill.
Row {
    id: root
    spacing: 4

    readonly property var occupied: {
        const ids = {};
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0) ids[ws.id] = true;
        }
        return ids;
    }
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int count: {
        let max = 5;
        for (const id in occupied) max = Math.max(max, parseInt(id));
        return Math.max(max, focusedId);
    }

    Repeater {
        model: root.count

        Rectangle {
            id: pill
            required property int index
            readonly property int wsId: index + 1
            readonly property bool focused: wsId === root.focusedId
            readonly property bool used: root.occupied[wsId] === true

            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 20
            implicitWidth: focused ? 34 : 20
            radius: Theme.radiusSmall
            color: focused ? Theme.accent
                 : hover.containsMouse ? Theme.alpha(Theme.text, 0.12)
                 : "transparent"
            Behavior on implicitWidth { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }

            Label {
                anchors.centerIn: parent
                text: pill.wsId
                font.pixelSize: Theme.fontSize - 2
                font.bold: pill.focused
                color: pill.focused ? Theme.bg : pill.used ? Theme.text : Theme.muted
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${pill.wsId}`)
            }
        }
    }

    WheelHandler {
        onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
    }
}
