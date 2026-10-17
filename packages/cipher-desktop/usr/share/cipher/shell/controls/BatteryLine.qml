import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.components

// "84% · about 5h 20m left" (isolated: needs the UPower module).
Label {
    readonly property var dev: UPower.displayDevice
    readonly property bool laptop: dev?.isLaptopBattery ?? false
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
    readonly property real secs: charging ? (dev?.timeToFull ?? 0) : (dev?.timeToEmpty ?? 0)
    function dur(s) {
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
    text: !laptop ? "Plugged in"
        : Math.round((dev?.percentage ?? 0) * 100) + "%" + (secs > 0 ? (charging ? " · full in " : " · about ") + dur(secs) + (charging ? "" : " left") : "")
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
}
