import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The Cipher bar. One per screen. Left: logo + workspaces + active window.
// Center: clock. Right: tray, status widgets and the power button.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property bool atTop: Settings.barPosition !== "bottom"

    anchors {
        top: bar.atTop
        bottom: !bar.atTop
        left: true
        right: true
    }
    implicitHeight: Settings.barHeight
    exclusiveZone: Settings.barHeight
    color: "transparent"

    WlrLayershell.namespace: "cipher-bar"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Settings.barTransparent ? Theme.alpha(Theme.bg, 0.55) : Theme.bg
        Behavior on color { ColorAnimation { duration: 200 } }

        // hairline separating bar from windows
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            y: bar.atTop ? parent.height - 1 : 0
            color: Theme.border
            visible: !Settings.barTransparent
        }

        MouseArea {
            // Double-click empty bar space toggles transparency (like Omarchy 4).
            anchors.fill: parent
            onDoubleClicked: Shell.run("cipher-shell-set barTransparent toggle")
        }

        RowLayout {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Rectangle {
                implicitWidth: Settings.barHeight - 8
                implicitHeight: Settings.barHeight - 8
                radius: Theme.radiusSmall
                color: logoMouse.containsMouse ? Theme.alpha(Theme.accent, 0.15) : "transparent"
                Logo {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                }
                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: m => Shell.open(m.button === Qt.RightButton ? "apps" : "menu", [])
                }
            }

            Workspaces {}

            ActiveWindow {
                Layout.maximumWidth: Math.max(0, bar.width / 2 - left.x - 260)
            }
        }

        Clock {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            // Each service-backed widget is loaded on its own, so a missing
            // Quickshell service module only hides that widget.
            Loader { source: "Tray.qml"; onLoaded: item.barWindow = bar }

            BarButton {
                visible: Shell.dnd
                icon: "bell-off"
                tint: Theme.yellow
                onClicked: Shell.dnd = false
            }

            BarButton {
                icon: Net.icon
                tint: Net.kind === "none" ? Theme.muted : Theme.text
                onClicked: Shell.terminal("nmtui")
            }

            Loader { source: "Volume.qml" }
            Loader { source: "Battery.qml" }

            BarButton {
                icon: Notifs.history.length > 0 ? "bell-dot" : "bell"
                onClicked: Shell.open("notifications", [])
            }

            BarButton {
                icon: "power"
                tint: Theme.red
                onClicked: Shell.open("menu", ["System"])
            }
        }
    }
}
