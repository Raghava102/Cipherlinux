import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Desktop background (replaces swaybg). Crossfades when the theme or
// background changes; falls back to a theme-colored gradient.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.bg
    WlrLayershell.namespace: "cipher-background"
    WlrLayershell.layer: WlrLayer.Background

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.bg }
            GradientStop { position: 1.0; color: Theme.surface }
        }
    }

    // Two images, alternating, for a crossfade.
    property bool useA: true
    property string current: Theme.wallpaper

    onCurrentChanged: {
        const url = current ? "file://" + current : "";
        if (useA) b.source = url; else a.source = url;
        useA = !useA;
    }

    Image {
        id: a
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: win.width
        sourceSize.height: win.height
        asynchronous: true
        opacity: win.useA && status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(450); easing.type: Easing.InOutQuad } }
        Component.onCompleted: source = win.current ? "file://" + win.current : ""
    }
    Image {
        id: b
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: win.width
        sourceSize.height: win.height
        asynchronous: true
        opacity: !win.useA && status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.ms(450); easing.type: Easing.InOutQuad } }
    }
}
