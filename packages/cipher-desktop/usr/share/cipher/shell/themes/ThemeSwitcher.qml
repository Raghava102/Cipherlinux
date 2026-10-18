import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components
import "../lib/fuzzy.js" as Fuzzy

// SUPER + SHIFT + CTRL + SPACE: a filterable carousel of live theme previews.
PanelWindow {
    id: win

    readonly property bool active: Shell.overlay === "themes"
    visible: active
    screen: Shell.focusedScreen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "cipher-themes"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var themes: []
    property string query: ""
    readonly property var shown: query
        ? themes.map(t => ({ t, s: Fuzzy.best(query, [t.title, t.name]) }))
                .filter(x => x.s >= 0).sort((a, b) => b.s - a.s).map(x => x.t)
        : themes

    onActiveChanged: {
        if (!active) return;
        query = "";
        filter.text = "";
        lister.running = true;
        filter.forceActiveFocus();
    }

    function apply(t) {
        if (!t) return;
        Shell.run("cipher-theme set " + "'" + t.name.replace(/'/g, "") + "'");
        Shell.close();
    }

    Process {
        id: lister
        command: ["cipher-theme", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { win.themes = JSON.parse(this.text); } catch (e) { win.themes = []; }
                const i = win.themes.findIndex(t => t.name === Theme.name);
                carousel.currentIndex = Math.max(0, i);
                carousel.positionViewAtIndex(carousel.currentIndex, ListView.Center);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        MouseArea { anchors.fill: parent; onClicked: Shell.close() }
    }

    Column {
        anchors.centerIn: parent
        spacing: 18
        width: parent.width

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Theme"
            font.pixelSize: Theme.fontSize + 6
            font.bold: true
        }

        ListView {
            id: carousel
            width: parent.width
            height: 210
            orientation: ListView.Horizontal
            spacing: 18
            model: win.shown
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 130
            preferredHighlightEnd: width / 2 + 130
            highlightMoveDuration: 180
            clip: false

            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool selected: ListView.isCurrentItem
                readonly property var c: modelData.colors ?? {}
                width: 260
                height: 200
                scale: selected ? 1.0 : 0.88
                opacity: selected ? 1.0 : 0.65
                Behavior on scale { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: card.c.bg ?? "#000000"
                    border.width: card.selected ? 2 : 1
                    border.color: card.selected ? (card.c.accent ?? Theme.accent) : Theme.border
                    clip: true

                    Image {
                        id: thumb
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        height: 128
                        source: card.modelData.wallpaper ? "file://" + card.modelData.wallpaper : ""
                        sourceSize.width: 520
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                    }

                    // mini bar preview
                    Rectangle {
                        anchors.left: thumb.left
                        anchors.right: thumb.right
                        anchors.top: thumb.top
                        height: 14
                        color: card.c.bg ?? "#000000"
                        opacity: 0.92
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Rectangle { width: 14; height: 6; radius: 3; color: card.c.accent ?? "white" }
                            Rectangle { width: 6; height: 6; radius: 3; color: card.c.muted ?? "gray" }
                            Rectangle { width: 6; height: 6; radius: 3; color: card.c.muted ?? "gray" }
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        spacing: 10

                        Text {
                            text: card.modelData.title ?? card.modelData.name
                            color: card.c.text ?? "white"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 1
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 17
                        spacing: 4
                        Repeater {
                            model: ["accent", "accent2", "green", "yellow", "red"]
                            Rectangle {
                                required property string modelData
                                width: 12; height: 12; radius: 6
                                color: card.c[modelData] ?? "transparent"
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.selected ? win.apply(card.modelData) : carousel.currentIndex = card.index
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: win.shown.length ? "← →  choose     Enter  apply     type to filter" : "No theme matches “" + win.query + "”"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 1
        }

        TextInput {
            id: filter
            width: 1; height: 1
            opacity: 0
            onTextEdited: { win.query = text; carousel.currentIndex = 0; }
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { carousel.incrementCurrentIndex(); e.accepted = true; }
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) { carousel.decrementCurrentIndex(); e.accepted = true; }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { win.apply(win.shown[carousel.currentIndex]); e.accepted = true; }
                else if (e.key === Qt.Key_Escape) {
                    if (filter.text) { filter.text = ""; win.query = ""; } else Shell.close();
                    e.accepted = true;
                }
            }
        }
    }
}
