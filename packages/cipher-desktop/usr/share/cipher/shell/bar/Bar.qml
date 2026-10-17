import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// Cipher Aurora bar: three floating glass pills over the wallpaper.
//   left   — Cipher mark, the app you're in
//   center — named workspaces (Home · Study · Create · +)
//   right  — Shield, tray, network, sound, battery, clock → quick controls
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property bool atTop: Settings.barPosition !== "bottom"
    readonly property int pill: Settings.barHeight
    readonly property int edge: 10

    anchors {
        top: bar.atTop
        bottom: !bar.atTop
        left: true
        right: true
    }
    implicitHeight: pill + edge + 4
    exclusiveZone: pill + edge
    color: "transparent"

    WlrLayershell.namespace: "cipher-bar"
    WlrLayershell.layer: WlrLayer.Top

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: bar.atTop ? bar.edge : 4
        anchors.bottomMargin: bar.atTop ? 4 : bar.edge

        // ---- left pill ------------------------------------------------------
        Glass {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: bar.pill
            width: leftRow.implicitWidth + 28
            radius: height / 2
            color: Settings.barTransparent ? Theme.alpha(Theme.bg, 0.4) : Theme.glass

            RowLayout {
                id: leftRow
                anchors.centerIn: parent
                spacing: 10

                Item {
                    implicitWidth: 22
                    implicitHeight: 22
                    Logo { anchors.fill: parent }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => Shell.open(m.button === Qt.RightButton ? "apps" : "menu", [])
                    }
                }
                Label { text: "Cipher"; font.weight: Font.Bold; font.pixelSize: Theme.fontSize + 1 }
                Rectangle { implicitWidth: 1; implicitHeight: 16; color: Theme.alpha(Theme.text, 0.15) }
                ActiveWindow { Layout.maximumWidth: Math.max(80, bar.width / 2 - 420) }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onDoubleClicked: Shell.run("cipher-shell-set barTransparent toggle")
            }
        }

        // ---- center pill: workspaces --------------------------------------
        Glass {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            height: bar.pill
            width: spaces.implicitWidth + 10
            radius: height / 2
            color: Settings.barTransparent ? Theme.alpha(Theme.bg, 0.4) : Theme.glass
            Workspaces { id: spaces; anchors.centerIn: parent }
        }

        // ---- right pill: status ------------------------------------------
        Glass {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: bar.pill
            width: rightRow.implicitWidth + 16
            radius: height / 2
            color: Settings.barTransparent ? Theme.alpha(Theme.bg, 0.4) : Theme.glass

            RowLayout {
                id: rightRow
                anchors.centerIn: parent
                spacing: 2

                // Shield chip
                Rectangle {
                    implicitHeight: bar.pill - 12
                    implicitWidth: shieldRow.implicitWidth + 20
                    radius: height / 2
                    color: Shield.protectedNow ? Theme.tint : Theme.alpha(Theme.yellow, 0.16)
                    Row {
                        id: shieldRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { name: "shield-check"; size: 13; color: Shield.protectedNow ? Theme.accent : Theme.yellow; anchors.verticalCenter: parent.verticalCenter }
                        Label {
                            text: Shield.protectedNow ? "Protected" : "No firewall"
                            color: Shield.protectedNow ? Theme.accent : Theme.yellow
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Shell.open("controls", []) }
                }

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
                    onClicked: Shell.open("controls", [])
                }
                Loader { source: "Volume.qml" }
                Loader { source: "Battery.qml" }
                BarButton {
                    icon: Notifs.history.length > 0 ? "bell-dot" : "bell"
                    onClicked: Shell.open("notifications", [])
                }
                Clock {}
            }
        }
    }
}
