import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.components

// Cipher dock: pinned apps, then anything else that's running.
// Bottom, left or right (shell.json "dockPosition"); magnifies on hover;
// a dot marks running apps, a longer pill marks the focused one.
PanelWindow {
    id: dock

    required property var modelData
    screen: modelData

    readonly property string pos: Settings.dockPosition
    readonly property bool vertical: pos === "left" || pos === "right"
    readonly property int icon: Settings.dockIconSize
    readonly property int pad: 12
    readonly property int thick: icon + pad * 2 + 8
    readonly property int labelRoom: 44

    visible: pos !== "hidden"
    anchors {
        bottom: dock.pos === "bottom"
        left: dock.pos === "left"
        right: dock.pos === "right"
    }
    margins {
        bottom: dock.pos === "bottom" ? 12 : 0
        left: dock.pos === "left" ? 12 : 0
        right: dock.pos === "right" ? 12 : 0
    }
    implicitWidth: vertical ? thick + labelRoom * 3 : glass.width + 40
    implicitHeight: vertical ? glass.height + 40 : thick + labelRoom
    exclusiveZone: thick + 8
    color: "transparent"
    mask: Region { item: glass }

    WlrLayershell.namespace: "cipher-dock"
    WlrLayershell.layer: WlrLayer.Top

    // ---- model -------------------------------------------------------------
    function entryFor(spec) {
        const ids = String(spec).split("|");
        for (const id of ids) {
            const e = DesktopEntries.byId(id);
            if (e) return e;
        }
        return ids.length === 1 ? DesktopEntries.heuristicLookup(ids[0]) : null;
    }
    function matches(entry, appId) {
        if (!entry || !appId) return false;
        const a = appId.toLowerCase();
        const id = entry.id.toLowerCase();
        const cls = (entry.startupClass || "").toLowerCase();
        return a === id || (cls && a === cls) || id.endsWith("." + a) || a.endsWith("." + id) || id.startsWith(a + "-") || a === id.replace(/-esr$/, "");
    }

    readonly property var toplevels: ToplevelManager.toplevels.values
    readonly property var items: {
        const out = [];
        const used = new Set();
        for (const id of Settings.dockPinned) {
            const e = entryFor(id);
            if (!e || out.some(o => o.entry === e)) continue;
            const wins = toplevels.filter(t => matches(e, t.appId));
            wins.forEach(w => used.add(w));
            out.push({ entry: e, wins, pinned: true });
        }
        let first = true;
        for (const t of toplevels) {
            if (used.has(t) || !t.appId) continue;
            const e = entryFor(t.appId);
            const existing = out.find(o => !o.pinned && (o.entry === e && e) || (o.appId === t.appId));
            if (existing) { existing.wins.push(t); continue; }
            out.push({ entry: e, appId: t.appId, wins: [t], pinned: false, sep: first });
            first = false;
        }
        return out;
    }

    // ---- view --------------------------------------------------------------
    Glass {
        id: glass
        radius: Theme.radius + 4
        width: dock.vertical ? dock.thick : grid.implicitWidth + dock.pad * 2
        height: dock.vertical ? grid.implicitHeight + dock.pad * 2 : dock.thick
        x: dock.pos === "left" ? 0 : dock.pos === "right" ? parent.width - width : (parent.width - width) / 2
        y: dock.vertical ? (parent.height - height) / 2 : parent.height - height

        Grid {
            id: grid
            anchors.centerIn: parent
            flow: dock.vertical ? Grid.TopToBottom : Grid.LeftToRight
            rows: dock.vertical ? 64 : 1
            columns: dock.vertical ? 1 : 64
            spacing: 8

            // launcher
            DockTile {
                size: dock.icon
                label: "Apps"
                glyph: "layout-grid"
                vertical: dock.vertical
                side: dock.pos
                onActivated: Shell.open("apps", [])
            }

            Repeater {
                model: dock.items
                DockTile {
                    required property var modelData
                    size: dock.icon
                    vertical: dock.vertical
                    side: dock.pos
                    separator: modelData.sep === true
                    label: modelData.entry?.name ?? modelData.appId ?? ""
                    iconSource: modelData.entry ? Quickshell.iconPath(modelData.entry.icon, "application-x-executable")
                                                : Quickshell.iconPath(modelData.appId, "application-x-executable")
                    running: modelData.wins.length > 0
                    focused: modelData.wins.some(w => w.activated)
                    onActivated: {
                        if (modelData.wins.length > 0) {
                            // cycle through this app's windows
                            const i = modelData.wins.findIndex(w => w.activated);
                            modelData.wins[(i + 1) % modelData.wins.length].activate();
                        } else if (modelData.entry) {
                            modelData.entry.execute();
                        }
                    }
                    onLaunchNew: if (modelData.entry) modelData.entry.execute()
                }
            }
        }
    }
}
