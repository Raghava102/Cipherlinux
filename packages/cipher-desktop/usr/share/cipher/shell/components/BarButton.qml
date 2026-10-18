import QtQuick
import qs.services

// A hoverable chip in the bar: optional icon + optional label.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property color tint: Theme.text
    property string tooltip: ""
    signal clicked(var mouse)

    implicitHeight: Settings.barHeight - 10
    implicitWidth: row.implicitWidth + 16
    radius: height / 2
    color: mouse.containsMouse ? Theme.hover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.ms(120) } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            name: root.icon
            color: root.tint
            size: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            visible: root.label !== ""
            text: root.label
            color: root.tint
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => root.clicked(m)
    }
}
