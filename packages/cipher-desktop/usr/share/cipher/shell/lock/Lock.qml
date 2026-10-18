import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services
import qs.components

// Cipher lock screen (replaces hyprlock): ext-session-lock + PAM.
// Triggered by `cipher-lock` (hypridle, SUPER+ESCAPE, before sleep).
// If this shell ever dies while locked, the compositor keeps the screen
// locked — it fails closed, never open.
Scope {
    id: root

    property string password: ""
    property string message: ""
    property bool busy: false
    property bool failed: false
    property var pending: null

    function lock() {
        password = ""; message = ""; failed = false; busy = false;
        Shell.close();
        sessionLock.locked = true;
    }

    function submit() {
        if (busy || password.length === 0) return;
        busy = true;
        failed = false;
        message = "";
        if (pam.active && pam.responseRequired) {
            pam.respond(password);
        } else {
            pending = password;
            if (!pam.active) pam.start();
        }
    }

    PamContext {
        id: pam
        config: "cipher-lock"
        configDirectory: "/etc/pam.d"

        onResponseRequiredChanged: {
            if (responseRequired && root.pending !== null) {
                respond(root.pending);
                root.pending = null;
            }
        }
        onPamMessage: if (pam.messageIsError) root.message = pam.message
        onCompleted: result => {
            root.busy = false;
            root.pending = null;
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                root.password = "";
            } else {
                root.failed = true;
                root.password = "";
                root.message = root.message || "Wrong password";
            }
        }
        onError: { root.busy = false; root.pending = null; root.message = "Authentication error"; }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        function isLocked(): bool { return sessionLock.locked; }
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface
            color: Theme.bg

            Image {
                anchors.fill: parent
                source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: surface.width
                asynchronous: true
            }
            Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.bg, 0.72) }

            SystemClock { id: clock; precision: SystemClock.Seconds }

            Column {
                anchors.centerIn: parent
                spacing: 14

                Logo {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 44; height: 44
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, Settings.clock24h ? "HH:mm" : "h:mm")
                    font.family: Theme.displayFont
                    font.pixelSize: 120
                    font.weight: Font.Light
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize + 4
                }

                Item { width: 1; height: 24 }

                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 340
                    height: 50
                    radius: height / 2
                    color: Theme.surface
                    border.width: 2
                    border.color: root.failed ? Theme.red : input.activeFocus ? Theme.accent : Theme.border

                    // shake on failure
                    SequentialAnimation on anchors.horizontalCenterOffset {
                        running: root.failed
                        loops: 1
                        NumberAnimation { to: -12; duration: Theme.ms(50) }
                        NumberAnimation { to: 12; duration: Theme.ms(70) }
                        NumberAnimation { to: -6; duration: Theme.ms(60) }
                        NumberAnimation { to: 0; duration: Theme.ms(50) }
                    }

                    Icon {
                        id: lockIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.busy ? "refresh-cw" : "lock"
                        color: root.failed ? Theme.red : Theme.muted
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        Repeater {
                            model: Math.min(root.password.length, 24)
                            Rectangle { width: 9; height: 9; radius: 4.5; color: Theme.accent }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        visible: root.password.length === 0
                        text: root.busy ? "Checking…" : "Password"
                        color: Theme.muted
                    }

                    TextInput {
                        id: input
                        anchors.fill: parent
                        opacity: 0
                        focus: true
                        echoMode: TextInput.Password
                        onTextEdited: { root.password = text; root.failed = false; }
                        onAccepted: root.submit()
                        Keys.onEscapePressed: root.password = ""
                        Component.onCompleted: forceActiveFocus()

                        // every screen shares one password buffer
                        Connections {
                            target: root
                            function onPasswordChanged() {
                                if (input.text !== root.password) input.text = root.password;
                            }
                        }
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.message
                    color: Theme.red
                    visible: text !== ""
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Quickshell.env("USER") ?? ""
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
