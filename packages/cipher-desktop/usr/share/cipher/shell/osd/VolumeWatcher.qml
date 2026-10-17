import QtQuick
import Quickshell.Services.Pipewire

// Emits `volumeEvent` whenever the default output's volume or mute state changes.
Item {
    id: root
    signal volumeEvent(real volume, bool muted)

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? -1
    readonly property bool muted: sink?.audio?.muted ?? false
    property bool armed: false

    // Don't pop the OSD for the initial values when the shell starts or the
    // default device changes.
    onSinkChanged: { armed = false; arm.restart(); }
    Timer { id: arm; interval: 600; running: true; onTriggered: root.armed = true }

    onVolumeChanged: if (armed && volume >= 0) volumeEvent(volume, muted)
    onMutedChanged: if (armed) volumeEvent(volume, muted)

    PwObjectTracker { objects: [root.sink] }
}
