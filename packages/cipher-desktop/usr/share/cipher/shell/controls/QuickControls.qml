import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Quick controls (click the status pill, or SUPER + C):
// Wi-Fi / Bluetooth tiles, volume + brightness, Focus · Night · Shield · Airplane,
// battery and power buttons.
PanelWindow {
    id: win
    readonly property bool active: Shell.overlay === "controls"
    visible: active
    screen: Shell.focusedScreen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "cipher-controls"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool night: false
    property bool airplane: false

    onActiveChanged: if (active) { Bluetooth.refresh(); Brightness.refresh(); Shield.refresh(); panel.forceActiveFocus(); }

    MouseArea { anchors.fill: parent; onClicked: Shell.close() }

    Glass {
        id: panel
        strong: true
        focus: true
        anchors.right: parent.right
        anchors.rightMargin: 12
        y: 8
        width: Math.min(392, parent.width - 24)
        height: col.implicitHeight + 40
        radius: Theme.radius + 6
        Keys.onEscapePressed: Shell.close()

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Label { text: "Quick controls"; font.pixelSize: Theme.fontSize + 4; font.weight: Font.Bold; Layout.fillWidth: true }
                BarButton { icon: "settings"; tooltip: "Settings"; onClicked: { Shell.close(); Shell.open("menu", ["Setup"]); } }
            }

            // Wi-Fi + Bluetooth
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                BigTile {
                    Layout.fillWidth: true
                    on: Net.kind !== "none"
                    icon: Net.kind === "ethernet" ? "ethernet-port" : "wifi"
                    title: Net.kind === "ethernet" ? "Ethernet" : "Wi-Fi"
                    subtitle: Net.connection || "Not connected"
                    onToggled: Shell.run(Net.kind === "wifi" ? "nmcli radio wifi off" : "nmcli radio wifi on")
                    onOpened: { Shell.close(); Shell.terminal("nmtui"); }
                }
                BigTile {
                    Layout.fillWidth: true
                    on: Bluetooth.powered
                    enabledTile: Bluetooth.available
                    tone: "#a78bfa"
                    icon: "bluetooth"
                    title: "Bluetooth"
                    subtitle: !Bluetooth.available ? "Unavailable" : !Bluetooth.powered ? "Off" : (Bluetooth.device || "On")
                    onToggled: Bluetooth.toggle()
                    onOpened: { Shell.close(); Shell.run("blueman-manager"); }
                }
            }

            // sliders
            Loader { Layout.fillWidth: true; source: "VolumeSlider.qml" }
            PillSlider {
                Layout.fillWidth: true
                visible: Brightness.available
                icon: "sun"
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }

            // toggles
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                SmallToggle { Layout.fillWidth: true; icon: "moon"; title: "Focus"; on: Shell.dnd; onToggled: Shell.dnd = !Shell.dnd }
                SmallToggle {
                    Layout.fillWidth: true; icon: "sun"; title: "Night"; on: win.night
                    onToggled: { win.night = !win.night; Shell.run(win.night ? "pkill -x hyprsunset; hyprsunset -t 4300 &" : "pkill -x hyprsunset"); }
                }
                SmallToggle {
                    Layout.fillWidth: true; icon: "shield-check"; title: "Shield"; on: Shield.protectedNow
                    onToggled: { Shell.close(); Shell.terminal("sudo ufw status verbose"); }
                }
                SmallToggle {
                    Layout.fillWidth: true; icon: "zap"; title: "Airplane"; on: win.airplane
                    onToggled: { win.airplane = !win.airplane; Shell.run(win.airplane ? "nmcli radio all off; rfkill block bluetooth" : "nmcli radio all on; rfkill unblock bluetooth"); }
                }
            }

            // footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Loader { Layout.fillWidth: true; source: "BatteryLine.qml" }
                RoundButton { icon: "lock"; label: "Lock"; onClicked: { Shell.close(); Shell.run("cipher-lock"); } }
                RoundButton { icon: "rotate-ccw"; label: "Restart"; onClicked: Shell.run("systemctl reboot") }
                RoundButton { icon: "power"; label: "Shut down"; hot: true; onClicked: Shell.run("systemctl poweroff") }
            }
        }
    }

    // ---- local components --------------------------------------------------
    component BigTile: Rectangle {
        id: t
        property bool on: false
        property bool enabledTile: true
        property string icon: "wifi"
        property string title: ""
        property string subtitle: ""
        property color tone: Theme.accent
        signal toggled()
        signal opened()
        implicitHeight: 70
        radius: 22
        opacity: enabledTile ? 1 : 0.5
        color: on ? Theme.alpha(tone, 0.16) : Theme.hover
        border.width: 1
        border.color: on ? Theme.alpha(tone, 0.45) : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10
            Rectangle {
                implicitWidth: 38; implicitHeight: 38; radius: 19
                color: t.on ? t.tone : Theme.alpha(Theme.text, 0.1)
                Icon { anchors.centerIn: parent; name: t.icon; size: 18; color: t.on ? Theme.onAccent : Theme.text }
                MouseArea { anchors.fill: parent; enabled: t.enabledTile; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label { text: t.title; font.weight: Font.Bold; Layout.fillWidth: true }
                Label { text: t.subtitle; color: Theme.muted; font.pixelSize: Theme.fontSize - 1; Layout.fillWidth: true }
            }
            Icon {
                name: "chevron-right"; size: 15; color: Theme.muted
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: t.opened() }
            }
        }
    }

    component SmallToggle: Rectangle {
        id: s
        property bool on: false
        property string icon: ""
        property string title: ""
        signal toggled()
        implicitHeight: 74
        radius: 18
        color: on ? Theme.tint : Theme.hover
        border.width: 1
        border.color: on ? Theme.alpha(Theme.accent, 0.45) : "transparent"
        Column {
            anchors.centerIn: parent
            spacing: 6
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: s.icon; size: 19; color: s.on ? Theme.accent : Theme.text }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: s.title; font.pixelSize: Theme.fontSize - 2; font.weight: Font.DemiBold }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: s.toggled() }
    }

    component RoundButton: Rectangle {
        id: r
        property string icon: ""
        property string label: ""
        property bool hot: false
        signal clicked()
        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: hot ? Theme.accent2 : (m.containsMouse ? Theme.alpha(Theme.text, 0.14) : Theme.hover)
        Icon { anchors.centerIn: parent; name: r.icon; size: 16; color: r.hot ? "#3a2210" : Theme.text }
        Accessible.role: Accessible.Button
        Accessible.name: r.label
        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.clicked() }
    }
}
