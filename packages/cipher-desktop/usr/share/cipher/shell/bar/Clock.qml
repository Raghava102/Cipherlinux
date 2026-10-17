import QtQuick
import Quickshell
import qs.services
import qs.components

// Center clock. Click to show the date and ISO week; right-click flips 12h/24h.
BarButton {
    id: root
    property bool showDate: false

    readonly property string timeFormat: Settings.clock24h ? "HH:mm" : "h:mm AP"
    label: showDate
        ? Qt.formatDateTime(clock.date, "dddd d MMMM") + "  ·  W" + isoWeek(clock.date)
        : Qt.formatDateTime(clock.date, "ddd d MMM   " + timeFormat)

    onClicked: m => {
        if (m.button === Qt.RightButton) Shell.run("cipher-shell-set clock24h toggle");
        else root.showDate = !root.showDate;
    }

    function isoWeek(d) {
        const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = date.getUTCDay() || 7;
        date.setUTCDate(date.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
        return Math.ceil(((date - yearStart) / 86400000 + 1) / 7);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
