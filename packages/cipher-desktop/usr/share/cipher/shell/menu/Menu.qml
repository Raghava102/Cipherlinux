import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.components
import "../lib/fuzzy.js" as Fuzzy

// The Cipher menu: one palette for apps and every system command.
//   SUPER + SPACE        full menu (apps + nested commands, searchable)
//   SUPER + ALT + SPACE  apps only
// Type to search across every nested entry, Enter to run or open,
// Esc / Backspace to go back.
PanelWindow {
    id: win

    readonly property bool active: Shell.overlay === "menu" || Shell.overlay === "apps"
    visible: active
    screen: Shell.focusedScreen

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "cipher-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ---- navigation state ------------------------------------------------
    property var stack: []          // nodes we descended into
    property string query: ""
    property int current: 0
    property var commandItems: []   // results of a provider=command node
    property bool loading: false

    readonly property var appsNode: ({ name: "Apps", icon: "layout-grid", provider: "apps" })
    readonly property var rootNode: Shell.overlay === "apps"
        ? appsNode
        : ({ name: "Cipher", children: [appsNode].concat(MenuData.tree) })
    readonly property var node: stack.length ? stack[stack.length - 1] : rootNode
    readonly property bool atRoot: stack.length === 0 && Shell.overlay !== "apps"
    // Apps view with no search: show a big icon grid instead of a list
    readonly property bool gridMode: Shell.overlay === "apps" && query === "" && stack.length === 0
    readonly property int gridColumns: Math.max(3, Math.min(6, Math.floor((width - 96) / 150)))
    readonly property var items: buildItems(node, query, commandItems, atRoot)

    // keep the search field in sync when navigation clears the query
    onQueryChanged: if (search.text !== query) search.text = query

    onActiveChanged: if (active) reset()

    // Re-open at a new path when asked while already open (e.g. SUPER+ESC while the menu is up)
    Connections {
        target: Shell
        function onMenuStartChanged() { if (win.active) win.reset(); }
    }

    function reset() {
        query = "";
        current = 0;
        commandItems = [];
        stack = [];
        // open at a path, e.g. ["System"] from the power button
        let n = rootNode;
        const path = [];
        for (const name of Shell.menuStart) {
            const next = (n.children ?? []).find(c => c.name === name);
            if (!next) break;
            path.push(next);
            n = next;
        }
        if (path.length) enter(path);
        search.forceActiveFocus();
    }

    // ---- data ------------------------------------------------------------
    function apps() {
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !Settings.hiddenApps.includes(e.id))
            .map(e => ({ name: e.name, hint: e.genericName || e.comment || "", appIcon: e.icon, entry: e,
                         keywords: (e.keywords ?? []).join(" ") }))
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function childrenOf(n, cmdItems) {
        if (n.provider === "apps") return apps();
        if (n.provider === "command") return cmdItems;
        return (n.children ?? []).filter(c => !c.hidden);
    }

    // Every static node below `n`, with its breadcrumb, for nested search.
    function flatten(n, trail, out) {
        for (const c of (n.children ?? [])) {
            if (c.hidden) continue;
            const t = trail.concat([c.name]);
            out.push(Object.assign({}, c, { hint: trail.length ? trail.join(" › ") : (c.hint ?? "") }));
            if (c.children) flatten(c, t, out);
        }
        return out;
    }

    function buildItems(n, q, cmdItems, isRoot) {
        if (!q) return childrenOf(n, cmdItems);
        let pool;
        if (n.provider) pool = childrenOf(n, cmdItems);
        else {
            pool = flatten(n, [], []);
            if (isRoot) pool = apps().concat(pool);
        }
        return pool
            .map(it => ({ it, s: Fuzzy.best(q, [it.name, it.keywords, it.hint]) }))
            .filter(x => x.s >= 0)
            .sort((a, b) => b.s - a.s)
            .slice(0, 60)
            .map(x => x.it);
    }

    function enter(path) {
        stack = stack.concat(path);
        query = "";
        current = 0;
        const n = stack[stack.length - 1];
        if (n.provider === "command") loadCommand(n);
    }

    function back() {
        if (query.length) { query = ""; return; }
        if (stack.length === 0 || (Shell.overlay === "apps")) { Shell.close(); return; }
        stack = stack.slice(0, -1);
        current = 0;
        commandItems = [];
        const n = stack.length ? stack[stack.length - 1] : null;
        if (n && n.provider === "command") loadCommand(n);
    }

    function quote(v) { return "'" + String(v).replace(/'/g, "'\\''") + "'"; }

    function activate(it) {
        if (!it) return;
        if (it.entry) { Shell.launch(it.entry); Shell.close(); return; }
        if (it.children || it.provider) { enter([it]); return; }
        if (it.value !== undefined && it.run) {
            Shell.run(it.run.split("{}").join(quote(it.value)));
        } else if (it.terminal) {
            Shell.terminal(it.terminal);
        } else if (it.exec) {
            Shell.run(it.exec);
        }
        if (!it.keepOpen) Shell.close();
    }

    function loadCommand(n) {
        commandItems = [];
        loading = true;
        cmd.provider = n;
        cmd.command = n.list;
        cmd.running = true;
    }

    Process {
        id: cmd
        property var provider: null
        stdout: StdioCollector {
            onStreamFinished: {
                const n = cmd.provider;
                win.commandItems = this.text.split("\n").filter(l => l.length).map(l => {
                    // label<TAB>value<TAB>icon<TAB>hint
                    const [label, value, icon, hint] = l.split("\t");
                    return { name: label, value: value ?? label, icon: icon || n.itemIcon || "",
                             hint: hint ?? "", run: n.run, keepOpen: n.keepOpen === true };
                });
                win.loading = false;
            }
        }
    }

    // ---- UI ----------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Theme.light ? 0.22 : 0.5)
        MouseArea { anchors.fill: parent; onClicked: Shell.close() }
    }

    Glass {
        id: panel
        strong: true
        width: Math.min(win.gridMode ? 980 : 720, parent.width - 48)
        height: win.gridMode ? Math.min(header.height + grid.contentHeight + 56, parent.height - 160)
                             : Math.min(header.height + list.contentHeight + 40, 560)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * (win.gridMode ? 0.09 : 0.16))
        radius: Theme.radius + 10
        clip: true
        Behavior on width { NumberAnimation { duration: Theme.ms(160); easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // swallow clicks so the backdrop doesn't close us

        Column {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 22
            spacing: 14

            Text {
                visible: Shell.overlay === "apps" && win.stack.length === 0
                text: "Apps"
                font.family: Theme.displayFont
                font.pixelSize: 40
                color: Theme.text
            }

            // breadcrumb
            Row {
                spacing: 6
                visible: win.stack.length > 0
                Repeater {
                    model: win.stack
                    Label {
                        required property var modelData
                        required property int index
                        text: (index > 0 ? "›  " : "") + modelData.name
                        color: index === win.stack.length - 1 ? Theme.accent : Theme.muted
                        font.pixelSize: Theme.fontSize - 1
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 54
                radius: 18
                color: Theme.hover
                border.color: search.activeFocus ? Theme.accent : Theme.glassEdge
                border.width: 1.5

                Icon {
                    id: searchIcon
                    name: "search"
                    color: Theme.muted
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    size: 19
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: search
                    anchors.left: searchIcon.right
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    selectionColor: Theme.alpha(Theme.accent, 0.4)
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 4
                    onTextEdited: { win.query = text; win.current = 0; }

                    Label {
                        anchors.fill: parent
                        visible: search.text === ""
                        text: win.loading ? "Loading…" : Shell.overlay === "apps" ? "Search apps" : "Search apps, files, settings — or type a command"
                        color: Theme.muted
                        font.pixelSize: Theme.fontSize + 4
                    }

                    Keys.onPressed: e => {
                        const n = win.items.length;
                        if (win.gridMode && n) {
                            const c = win.gridColumns;
                            if (e.key === Qt.Key_Right) { win.current = Math.min(n - 1, win.current + 1); e.accepted = true; return; }
                            if (e.key === Qt.Key_Left) { win.current = Math.max(0, win.current - 1); e.accepted = true; return; }
                            if (e.key === Qt.Key_Down) { win.current = Math.min(n - 1, win.current + c); e.accepted = true; return; }
                            if (e.key === Qt.Key_Up) { win.current = Math.max(0, win.current - c); e.accepted = true; return; }
                        }
                        if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))
                            || (e.key === Qt.Key_J && (e.modifiers & Qt.ControlModifier))) {
                            win.current = n ? (win.current + 1) % n : 0; e.accepted = true;
                        } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab
                            || (e.key === Qt.Key_K && (e.modifiers & Qt.ControlModifier))) {
                            win.current = n ? (win.current - 1 + n) % n : 0; e.accepted = true;
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            win.activate(win.items[win.current]); e.accepted = true;
                        } else if (e.key === Qt.Key_Right && search.cursorPosition === search.text.length) {
                            const it = win.items[win.current];
                            if (it && (it.children || it.provider)) { win.enter([it]); e.accepted = true; }
                        } else if (e.key === Qt.Key_Escape
                            || (e.key === Qt.Key_Backspace && search.text === "")
                            || (e.key === Qt.Key_Left && search.text === "")) {
                            win.back(); e.accepted = true;
                        }
                    }
                }
            }
        }

        ListView {
            id: list
            visible: !win.gridMode
            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 14
            clip: true
            model: win.gridMode ? [] : win.items
            currentIndex: win.current
            highlightMoveDuration: 80
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2

            highlight: Rectangle {
                radius: 14
                color: Theme.tint
                border.color: Theme.alpha(Theme.accent, 0.35)
                border.width: 1
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 48

                Item {
                    id: iconBox
                    width: 28
                    height: 28
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    IconImage {
                        anchors.centerIn: parent
                        visible: row.modelData.appIcon !== undefined
                        implicitSize: 26
                        source: row.modelData.appIcon !== undefined
                            ? Quickshell.iconPath(row.modelData.appIcon, "application-x-executable") : ""
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: row.modelData.appIcon === undefined
                        name: row.modelData.icon || (row.modelData.children || row.modelData.provider ? "folder" : "command")
                        color: row.index === win.current ? Theme.accent : Theme.text
                        size: 17
                    }
                }

                Label {
                    id: name
                    anchors.left: iconBox.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width * 0.55)
                    text: row.modelData.name
                    font.bold: row.index === win.current
                }

                Label {
                    anchors.left: name.right
                    anchors.leftMargin: 12
                    anchors.right: tail.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: row.modelData.hint ?? ""
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize - 1
                }

                Row {
                    id: tail
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        visible: (row.modelData.keys ?? "") !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        height: 20
                        width: keysLabel.implicitWidth + 12
                        radius: 4
                        color: Theme.surface
                        border.color: Theme.border
                        Label {
                            id: keysLabel
                            anchors.centerIn: parent
                            text: row.modelData.keys ?? ""
                            color: Theme.muted
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                    Icon {
                        visible: !!(row.modelData.children || row.modelData.provider)
                        anchors.verticalCenter: parent.verticalCenter
                        name: "chevron-right"
                        color: Theme.muted
                        size: 15
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: win.current = row.index
                    onClicked: win.activate(row.modelData)
                }
            }

            Label {
                anchors.centerIn: parent
                visible: list.count === 0 && !win.loading
                text: win.query ? "Nothing matches “" + win.query + "”" : "Empty"
                color: Theme.muted
            }
        }
        GridView {
            id: grid
            visible: win.gridMode
            anchors.top: header.bottom
            anchors.topMargin: 18
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.bottomMargin: 18
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cellWidth: Math.floor(width / win.gridColumns)
            cellHeight: 128
            model: win.gridMode ? win.items : []
            currentIndex: win.current

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                readonly property bool selected: index === win.current

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 22
                    color: cell.selected ? Theme.tint : "transparent"
                    border.width: cell.selected ? 1 : 0
                    border.color: Theme.alpha(Theme.accent, 0.35)
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitSize: 64
                        scale: cell.selected ? 1.06 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.ms(120) } }
                        source: Quickshell.iconPath(cell.modelData.appIcon ?? "", "application-x-executable")
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: grid.cellWidth - 16
                        horizontalAlignment: Text.AlignHCenter
                        text: cell.modelData.name
                        font.weight: cell.selected ? Font.Bold : Font.DemiBold
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: win.current = cell.index
                    onClicked: win.activate(cell.modelData)
                }
            }
        }
    }
}
