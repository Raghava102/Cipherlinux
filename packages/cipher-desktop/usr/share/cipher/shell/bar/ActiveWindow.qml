import QtQuick
import Quickshell.Hyprland
import qs.services
import qs.components

Label {
    readonly property string title: Hyprland.activeToplevel?.title ?? ""
    readonly property bool here: title !== "" && Hyprland.activeToplevel?.workspace?.id === Hyprland.focusedWorkspace?.id
    text: here ? title : "Desktop"
    color: Theme.muted
}
