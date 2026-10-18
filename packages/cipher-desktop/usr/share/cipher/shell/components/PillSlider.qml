import QtQuick
import qs.services

// Big rounded slider (volume, brightness). Emits moved(value 0..1) while dragging.
Item {
    id: root
    property real value: 0
    property string icon: "sun"
    property bool active: true
    signal moved(real value)

    implicitHeight: 34
    opacity: active ? 1 : 0.4

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.hover

        Rectangle {
            width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: height / 2
            color: Theme.light ? Theme.accent : Theme.text
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.ms(120) } }
        }
        Icon {
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: 15
            color: Theme.light ? Theme.onAccent : Theme.bg
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: root.active
        cursorShape: Qt.PointingHandCursor
        function update(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: m => update(m.x)
        onPositionChanged: m => { if (pressed) update(m.x); }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
