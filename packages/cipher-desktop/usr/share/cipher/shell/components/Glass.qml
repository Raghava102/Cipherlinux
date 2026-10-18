import QtQuick
import qs.services

// Aurora glass surface: translucent fill, hairline edge, soft depth.
// The compositor adds the blur behind it (layerrule blur on cipher-* layers).
Rectangle {
    property bool strong: false
    radius: Theme.radius
    color: strong ? Theme.glassStrong : Theme.glass
    border.width: 1
    border.color: Theme.glassEdge
    Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
}
