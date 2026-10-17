import QtQuick
import Quickshell.Widgets
import qs.services
import qs.components

// One dock icon: app icon (or a Lucide glyph), hover magnify + label,
// running dot / focused pill.
Item {
    id: tile
    property int size: 48
    property string label: ""
    property string iconSource: ""
    property string glyph: ""
    property bool running: false
    property bool focused: false
    property bool vertical: false
    property string side: "bottom"
    property bool separator: false
    signal activated()
    signal launchNew()

    readonly property real zoom: mouse.containsMouse && Settings.dockMagnify ? 1.22 : 1.0
    implicitWidth: vertical ? size : size + (separator ? 14 : 0)
    implicitHeight: vertical ? size + (separator ? 14 : 0) : size

    Rectangle {
        visible: tile.separator
        color: Theme.alpha(Theme.text, 0.14)
        width: tile.vertical ? tile.size * 0.6 : 1
        height: tile.vertical ? 1 : tile.size * 0.6
        x: tile.vertical ? (tile.size - width) / 2 : 3
        y: tile.vertical ? 3 : (tile.size - height) / 2
    }

    Item {
        id: body
        width: tile.size
        height: tile.size
        x: tile.vertical ? 0 : (tile.separator ? 14 : 0)
        y: tile.vertical ? (tile.separator ? 14 : 0) : 0
        scale: tile.zoom
        transformOrigin: tile.side === "left" ? Item.Left : tile.side === "right" ? Item.Right : Item.Bottom
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Rectangle {
            visible: tile.glyph !== ""
            anchors.fill: parent
            radius: Theme.radiusSmall
            color: Theme.tint
            Icon { anchors.centerIn: parent; name: tile.glyph; size: tile.size * 0.46; color: Theme.accent }
        }
        IconImage {
            visible: tile.glyph === ""
            anchors.fill: parent
            anchors.margins: 2
            source: tile.iconSource
            asynchronous: true
        }
    }

    // running indicator
    Rectangle {
        visible: tile.running
        color: tile.focused ? Theme.accent : Theme.muted
        radius: 2
        width: tile.vertical ? 4 : (tile.focused ? 14 : 5)
        height: tile.vertical ? (tile.focused ? 14 : 5) : 4
        x: tile.vertical ? (tile.side === "left" ? -9 : tile.size + 5) : body.x + (tile.size - width) / 2
        y: tile.vertical ? body.y + (tile.size - height) / 2 : tile.size + 5
        Behavior on width { NumberAnimation { duration: 140 } }
    }

    // hover label
    Glass {
        visible: mouse.containsMouse && tile.label !== ""
        strong: true
        radius: height / 2
        height: 28
        width: tip.implicitWidth + 22
        x: tile.vertical ? (tile.side === "left" ? tile.size + 22 : -width - 22) : body.x + (tile.size - width) / 2
        y: tile.vertical ? body.y + (tile.size - height) / 2 : -height - 16
        Label { id: tip; anchors.centerIn: parent; text: tile.label; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize - 1 }
    }

    MouseArea {
        id: mouse
        anchors.fill: body
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => m.button === Qt.MiddleButton ? tile.launchNew() : tile.activated()
    }
}
