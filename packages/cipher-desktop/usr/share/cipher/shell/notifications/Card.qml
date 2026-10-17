import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.services
import qs.components

// A single live notification popup. Click to dismiss (or run the default
// action), right-click to dismiss, hover pauses the timeout.
Rectangle {
    id: card
    required property var modelData
    readonly property var n: modelData
    readonly property bool critical: n.urgency === NotificationUrgency.Critical

    width: 360
    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: critical ? Theme.red : Theme.border

    // accent stripe
    Rectangle {
        width: 3
        radius: 2
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 10
        color: card.critical ? Theme.red : Theme.accent
    }

    Timer {
        // Critical notifications stay until dismissed.
        running: !card.critical && !hover.containsMouse
        interval: card.n.expireTimeout > 0 ? card.n.expireTimeout * 1000 : 5000
        onTriggered: card.n.expire()
    }

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 22
        anchors.rightMargin: 12
        anchors.topMargin: 12
        spacing: 12

        IconImage {
            id: appIcon
            visible: source.toString() !== ""
            implicitSize: 36
            source: card.n.image || (card.n.appIcon ? Quickshell.iconPath(card.n.appIcon, true) : "")
        }

        Column {
            width: parent.width - (appIcon.visible ? 48 : 0)
            spacing: 3

            Label {
                width: parent.width
                text: card.n.appName || "System"
                color: Theme.muted
                font.pixelSize: Theme.fontSize - 2
            }
            Label {
                width: parent.width
                text: card.n.summary
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: card.n.body
                textFormat: Text.StyledText
                color: Theme.alpha(Theme.text, 0.85)
                wrapMode: Text.Wrap
                maximumLineCount: 4
            }

            Row {
                spacing: 6
                topPadding: 4
                visible: card.n.actions.length > 0
                Repeater {
                    model: card.n.actions
                    BarButton {
                        required property var modelData
                        label: modelData.text
                        color: Theme.surface
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: -1
        onClicked: m => {
            const def = Array.from(card.n.actions).find(a => a.identifier === "default");
            if (m.button === Qt.LeftButton && def) def.invoke();
            else card.n.dismiss();
        }
    }
}
