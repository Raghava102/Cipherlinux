import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// Output volume. Scroll to change, click for the mixer, right click to mute.
BarButton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    icon: muted || volume <= 0.001 ? "volume-x" : volume < 0.5 ? "volume-1" : "volume-2"
    label: muted || (QsWindow.window?.width ?? 2000) < 1300 ? "" : Math.round(volume * 100) + "%"
    tint: muted ? Theme.muted : Theme.text

    onClicked: m => {
        if (m.button === Qt.RightButton) Shell.run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle");
        else Shell.run("pavucontrol");
    }

    WheelHandler {
        onWheel: e => Shell.run(e.angleDelta.y > 0
            ? "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
            : "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    }

    PwObjectTracker { objects: [root.sink] }
}
