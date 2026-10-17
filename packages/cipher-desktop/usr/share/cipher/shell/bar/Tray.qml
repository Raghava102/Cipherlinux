import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services

// StatusNotifier tray. Left click activates, right click opens the app's menu.
Row {
    id: root
    property var barWindow: null
    spacing: 2

    Repeater {
        model: SystemTray.items

        Rectangle {
            id: slot
            required property var modelData
            implicitWidth: 26
            implicitHeight: 24
            radius: Theme.radiusSmall
            color: mouse.containsMouse ? Theme.alpha(Theme.text, 0.08) : "transparent"

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: slot.modelData.icon
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: m => {
                    const item = slot.modelData;
                    if (m.button === Qt.MiddleButton) {
                        item.secondaryActivate();
                    } else if (m.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu && root.barWindow) {
                            const p = slot.mapToItem(null, 0, slot.height);
                            item.display(root.barWindow, p.x, p.y);
                        }
                    } else {
                        item.activate();
                    }
                }
                onWheel: w => slot.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }
}
