import QtQuick
import Quickshell
import qs.services
import qs.components

// Time in bold, date in muted. Click: date + ISO week. Right-click: 12h/24h.
Rectangle {
    id: root
    property bool showWeek: false
    property bool showDate: true
    readonly property string timeFormat: Settings.clock24h ? "HH:mm" : "h:mm AP"

    implicitHeight: Settings.barHeight - 10
    implicitWidth: row.implicitWidth + 24
    radius: height / 2
    color: mouse.containsMouse ? Theme.hover : "transparent"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Label { text: Qt.formatDateTime(clock.date, root.timeFormat); font.weight: Font.DemiBold }
        Label {
            visible: root.showDate || root.showWeek
            text: root.showWeek ? "Week " + root.isoWeek(clock.date) : Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Theme.muted
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            if (m.button === Qt.RightButton) Shell.run("cipher-shell-set clock24h toggle");
            else root.showWeek = !root.showWeek;
        }
    }

    function isoWeek(d) {
        const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = date.getUTCDay() || 7;
        date.setUTCDate(date.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
        return Math.ceil(((date - yearStart) / 86400000 + 1) / 7);
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
