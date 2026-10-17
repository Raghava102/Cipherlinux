pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Loads the Cipher menu tree.
//   /usr/share/cipher/menu.json       - the system menu
//   ~/.config/cipher/menu.json        - your additions (merged in, live-reloaded)
//
// Node fields: name, icon, hint, keys,
//   exec      shell command to run
//   terminal  command to run in a terminal window
//   children  sub-nodes
//   provider  "apps" | "command"
//   list      (provider=command) argv printing "label<TAB>value[<TAB>icon]" lines
//   run       (provider=command) shell command, "{}" is replaced by the quoted value
Singleton {
    id: root

    property var system: []
    property var user: []
    readonly property var tree: merge(system, user)

    // User nodes with the same name as a system node merge their children
    // into it; anything else is appended.
    function merge(base, extra) {
        const out = base.map(n => Object.assign({}, n));
        for (const n of extra) {
            const twin = out.find(o => o.name === n.name && o.children && n.children);
            if (twin) twin.children = merge(twin.children, n.children);
            else out.push(n);
        }
        return out;
    }

    function parse(text, what) {
        try {
            const v = JSON.parse(text);
            return Array.isArray(v) ? v : (v.items ?? []);
        } catch (e) {
            console.warn(`cipher: could not parse ${what} menu`, e);
            return [];
        }
    }

    FileView {
        path: "/usr/share/cipher/menu.json"
        watchChanges: true
        onLoaded: root.system = root.parse(text(), "system")
        onFileChanged: reload()
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/cipher/menu.json"
        watchChanges: true
        printErrors: false
        onLoaded: root.user = root.parse(text(), "user")
        onLoadFailed: root.user = []
        onFileChanged: reload()
    }
}
