import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.components

// Laptop battery. Hidden on desktops. Right click toggles the percentage.
BarButton {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property real pct: (dev?.percentage ?? 0) * 100
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
                                  || dev?.state === UPowerDeviceState.FullyCharged
    property bool showPercent: true

    visible: dev?.isLaptopBattery ?? false
    icon: charging ? "battery-charging"
        : pct < 15 ? "battery-low"
        : pct < 50 ? "battery-medium"
        : pct < 90 ? "battery" : "battery-full"
    label: showPercent ? Math.round(pct) + "%" : ""
    tint: !charging && pct < 15 ? Theme.red : charging ? Theme.green : Theme.text

    onClicked: m => {
        if (m.button === Qt.RightButton) root.showPercent = !root.showPercent;
        else Shell.open("menu", ["System", "Power profile"]);
    }
}
