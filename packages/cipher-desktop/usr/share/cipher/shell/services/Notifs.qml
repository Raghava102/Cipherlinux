pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Cipher's notification daemon (replaces mako/dunst).
// Live notifications are shown as popups; a plain-data copy of every
// notification is kept in `history` for the notification center.
Singleton {
    id: root

    readonly property var popups: server.trackedNotifications
    property var history: []
    readonly property int historyLimit: 50

    function remember(n) {
        const entry = {
            id: n.id,
            appName: n.appName || "System",
            appIcon: n.appIcon,
            summary: n.summary,
            body: n.body,
            urgency: n.urgency,
            time: new Date()
        };
        root.history = [entry, ...root.history].slice(0, root.historyLimit);
    }

    function clearHistory() { root.history = []; }

    function dismissAll() {
        const live = server.trackedNotifications.values.slice();
        for (const n of live) n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            root.remember(n);
            // Do-not-disturb silences everything except critical alerts;
            // silenced notifications still land in the history.
            const critical = n.urgency === NotificationUrgency.Critical;
            n.tracked = !Shell.dnd || critical;
        }
    }

    IpcHandler {
        target: "notify"
        function dismissAll(): void { root.dismissAll(); }
        function clear(): void { root.clearHistory(); }
        function count(): int { return root.history.length; }
    }
}
