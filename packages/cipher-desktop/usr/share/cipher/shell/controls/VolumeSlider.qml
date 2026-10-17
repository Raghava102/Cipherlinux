import QtQuick
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// Output volume as a pill slider (isolated: needs the PipeWire module).
PillSlider {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    icon: (sink?.audio?.muted ?? false) ? "volume-x" : "volume-2"
    value: sink?.audio?.volume ?? 0
    active: sink?.audio !== undefined && sink?.audio !== null
    onMoved: v => { if (sink?.audio) { sink.audio.muted = false; sink.audio.volume = v; } }
    PwObjectTracker { objects: [root.sink] }
}
