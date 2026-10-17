import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.components

Label {
    readonly property string title: Hyprland.activeToplevel?.title ?? ""
    text: title
    visible: title !== "" && Hyprland.activeToplevel?.workspace?.id === Hyprland.focusedWorkspace?.id
    color: Theme.muted
    leftPadding: 8
}
