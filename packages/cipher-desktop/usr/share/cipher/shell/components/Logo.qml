import QtQuick
import qs.services

// The Cipher mark: a hexagon with an open "C" keyway, drawn so it follows the theme.
Canvas {
    id: root
    property color color: Theme.accent
    property real stroke: Math.max(1.6, width / 11)

    implicitWidth: 18
    implicitHeight: 18
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height, cx = w / 2, cy = h / 2;
        const r = Math.min(w, h) / 2 - stroke / 2;
        ctx.reset();
        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.stroke;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";

        // hexagon
        ctx.beginPath();
        for (let i = 0; i < 6; i++) {
            const a = Math.PI / 3 * i - Math.PI / 2;
            const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a);
            if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.stroke();

        // inner "C" with a keyhole dot
        ctx.beginPath();
        ctx.arc(cx, cy, r * 0.45, Math.PI * 0.25, Math.PI * 1.75, false);
        ctx.stroke();
        ctx.beginPath();
        ctx.fillStyle = root.color;
        ctx.arc(cx + r * 0.05, cy, root.stroke * 0.7, 0, Math.PI * 2);
        ctx.fill();
    }
}
