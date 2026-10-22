# Cipher app test

| App | Result | Time | Note |
|---|---|---|---|
| Bluetooth Manager (`blueman-manager`) | PASS | 1s |  |
| btop++ (`btop`) | PASS | 1s | terminal app;  |
| Chromium Web Browser (`chromium`) | FAIL | 25s | ntu 23.10+ or another Linux distro that has disabled unprivileged user namespaces with AppArmor, see https://chromium.googlesource.com/chromium/src/+/main/docs/security/apparmor-userns-restrictions.md. If you want to live dangerously and need an immediate workaround, you can try using --no-sandbox.  |
| Firefox ESR (`firefox-esr`) | PASS | 2s |  |
| Foot (`foot`) | PASS | 1s |  |
| LibreOffice Calc (`libreoffice-calc`) | PASS | 1s |  |
| LibreOffice Draw (`libreoffice-draw`) | PASS | 1s |  |
| LibreOffice Impress (`libreoffice-impress`) | PASS | 1s |  |
| LibreOffice Math (`libreoffice-math`) | PASS | 1s |  |
| LibreOffice (`libreoffice-startcenter`) | PASS | 1s |  |
| LibreOffice Writer (`libreoffice-writer`) | PASS | 2s |  |
| Advanced Network Configuration (`nm-connection-editor`) | PASS | 1s |  |
| IBus Preferences (`org.freedesktop.IBus.Setup`) | PASS | 1s |  |
| Parental Controls (`org.freedesktop.MalcontentControl`) | FAIL | 26s |  |
| Calculator (`org.gnome.Calculator`) | PASS | 2s |  |
| Calendar (`org.gnome.Calendar`) | PASS | 1s |  |
| Characters (`org.gnome.Characters`) | PASS | 1s |  |
| Connections (`org.gnome.Connections`) | PASS | 1s |  |
| Contacts (`org.gnome.Contacts`) | PASS | 1s |  |
| Disks (`org.gnome.DiskUtility`) | FAIL | 25s |  |
| Document Viewer (`org.gnome.Evince`) | PASS | 2s |  |
| Evolution (`org.gnome.Evolution`) | PASS | 1s |  |
| File Roller (`org.gnome.FileRoller`) | PASS | 1s |  |
| Logs (`org.gnome.Logs`) | PASS | 1s |  |
| Image Viewer (`org.gnome.Loupe`) | PASS | 1s |  |
| Maps (`org.gnome.Maps`) | PASS | 2s |  |
| Music (`org.gnome.Music`) | PASS | 1s |  |
| Files (`org.gnome.Nautilus`) | PASS | 1s |  |
| Settings (`org.gnome.Settings`) | PASS | 14s |  |
| Shotwell (`org.gnome.Shotwell`) | PASS | 1s |  |
| Camera (`org.gnome.Snapshot`) | PASS | 1s |  |
| Software (`org.gnome.Software`) | FAIL | 25s |  |
| Sound Recorder (`org.gnome.SoundRecorder`) | PASS | 1s |  |
| System Monitor (`org.gnome.SystemMonitor`) | PASS | 2s |  |
| Terminal (`org.gnome.Terminal`) | PASS | 1s |  |
| Text Editor (`org.gnome.TextEditor`) | PASS | 1s |  |
| Videos (`org.gnome.Totem`) | PASS | 1s |  |
| Tour (`org.gnome.Tour`) | PASS | 1s |  |
| Weather (`org.gnome.Weather`) | PASS | 1s |  |
| Disk Usage Analyzer (`org.gnome.baobab`) | PASS | 1s |  |
| Clocks (`org.gnome.clocks`) | PASS | 1s |  |
| Fonts (`org.gnome.font-viewer`) | PASS | 1s |  |
| Passwords and Keys (`org.gnome.seahorse.Application`) | PASS | 1s |  |
| Tweaks (`org.gnome.tweaks`) | PASS | 1s |  |
| Volume Control (`org.pulseaudio.pavucontrol`) | PASS | 1s |  |
| Document Scanner (`simple-scan`) | PASS | 1s |  |
| Print Settings (`system-config-printer`) | FAIL | 25s |  |
| Bulk Rename (`thunar-bulk-rename`) | PASS | 1s |  |
| Removable Drives and Media (`thunar-volman-settings`) | PASS | 2s |  |
| Thunar File Manager (`thunar`) | PASS | 1s |  |
| Help (`yelp`) | PASS | 1s |  |
