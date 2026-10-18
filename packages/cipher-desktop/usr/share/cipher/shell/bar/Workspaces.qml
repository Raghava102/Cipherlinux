import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.components

// Named workspace tabs: Home · Study · Create (names from shell.json),
// then numbers for the rest. The active one gets a tinted pill and a dot.
Row {
    id: root
    spacing: 2

    readonly property var occupied: {
        const ids = {};
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id > 0) ids[ws.id] = true;
        }
        return ids;
    }
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int count: {
        let max = Math.max(1, Settings.workspaceNames.length);
        for (const id in occupied) max = Math.max(max, parseInt(id));
        return Math.max(max, focusedId);
    }

    Repeater {
        model: root.count

        Rectangle {
            id: tab
            required property int index
            readonly property int wsId: index + 1
            readonly property bool focused: wsId === root.focusedId
            readonly property bool used: root.occupied[wsId] === true
            readonly property string title: Settings.workspaceNames[index] ?? String(wsId)

            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: Settings.barHeight - 10
            implicitWidth: row.implicitWidth + 28
            radius: height / 2
            color: focused ? Theme.tint : hover.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.ms(160) } }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 7
                Rectangle {
                    visible: tab.focused || tab.used
                    width: 6; height: 6; radius: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: tab.focused ? Theme.accent : Theme.muted
                }
                Label {
                    text: tab.title
                    color: tab.focused ? Theme.accent : tab.used ? Theme.text : Theme.muted
                    font.weight: tab.focused ? Font.DemiBold : Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${tab.wsId}`)
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Settings.barHeight - 10
        implicitHeight: Settings.barHeight - 10
        radius: height / 2
        color: addHover.containsMouse ? Theme.hover : "transparent"
        Label { anchors.centerIn: parent; text: "+"; color: Theme.muted; font.pixelSize: Theme.fontSize + 4 }
        MouseArea {
            id: addHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("workspace empty")
        }
    }

    WheelHandler {
        onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
    }
}
