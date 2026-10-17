import QtQuick
import qs.services

// A Lucide icon drawn from the bundled icon font, so it takes theme colors.
Text {
    property string name: "circle"
    property real size: 16

    text: Icons.glyph(name)
    font.family: Icons.family
    font.pixelSize: size
    color: Theme.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
