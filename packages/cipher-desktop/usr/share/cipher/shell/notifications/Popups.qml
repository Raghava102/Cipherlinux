import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Stack of live notification popups in the top-right of the focused screen.
PanelWindow {
    id: win
    screen: Shell.focusedScreen
    visible: Notifs.popups.values.length > 0

    anchors {
        top: Settings.barPosition !== "bottom"
        bottom: Settings.barPosition === "bottom"
        right: true
    }
    margins {
        top: 10
        bottom: 10
        right: 10
    }
    implicitWidth: 360
    implicitHeight: stack.implicitHeight
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "cipher-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        width: parent.width
        spacing: 8
        move: Transition { NumberAnimation { properties: "y"; duration: 160; easing.type: Easing.OutCubic } }

        Repeater {
            model: Notifs.popups
            Card {}
        }
    }
}
