import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.components

// Cipher bar: one floating status pill on the right — Shield, network,
// sound, battery, clock and date. Clicking it opens Quick Controls.
// Workspaces have no bar space: SUPER + 1..9 (SUPER + TAB to cycle).
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property bool atTop: Settings.barPosition !== "bottom"
    readonly property int pill: Settings.barHeight
    readonly property int edge: 10
    // narrow screens (small VM windows, 1366px laptops) get a compact bar
    readonly property bool compact: width < 1300
    readonly property bool tiny: width < 1050

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

        // ---- right pill: status ------------------------------------------
        Glass {
            id: rightPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: bar.pill
            width: rightRow.implicitWidth + 16
            radius: height / 2
            color: Settings.barTransparent ? Theme.alpha(Theme.bg, 0.4) : Theme.glass

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: Shell.open("controls", [])
                onDoubleClicked: Shell.run("cipher-shell-set barTransparent toggle")
            }

            RowLayout {
                id: rightRow
                anchors.centerIn: parent
                spacing: 2

                // Shield chip
                Rectangle {
                    implicitHeight: bar.pill - 12
                    implicitWidth: shieldRow.implicitWidth + (bar.compact ? 14 : 20)
                    radius: height / 2
                    color: Shield.protectedNow ? Theme.tint : Theme.alpha(Theme.yellow, 0.16)
                    Row {
                        id: shieldRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon { name: "shield-check"; size: 13; color: Shield.protectedNow ? Theme.accent : Theme.yellow; anchors.verticalCenter: parent.verticalCenter }
                        Label {
                            visible: !bar.tiny
                            text: Shield.protectedNow ? "Protected" : "No firewall"
                            color: Shield.protectedNow ? Theme.accent : Theme.yellow
                            font.pixelSize: Theme.fontSize - 1
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Shell.open("controls", []) }
                }

                Loader { source: "Tray.qml"; visible: !!item && item.implicitWidth > 0; onLoaded: item.barWindow = bar }

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
                Loader { source: "Volume.qml"; visible: !!item }
                Loader { source: "Battery.qml"; visible: !!item && item.present }
                BarButton {
                    visible: Notifs.history.length > 0
                    icon: "bell-dot"
                    onClicked: Shell.open("notifications", [])
                }
                Clock { showDate: !bar.tiny }
            }
        }
    }
}
