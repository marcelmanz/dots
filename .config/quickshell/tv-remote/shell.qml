import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property bool dark: themeMode.text().trim() === "dark"
    readonly property color background: dark ? "#000000" : "#e0e4de"
    readonly property color raised: dark ? "#2e2e2e" : "#adb0ab"
    readonly property color border: dark ? "#3a3a3a" : "#adb0ab"
    readonly property color foreground: dark ? "#d0d0d0" : "#2c2e33"
    readonly property color strong: dark ? "#ffffff" : "#000000"
    readonly property color muted: dark ? "#808080" : "#64666c"

    readonly property var keyRows: [
        ["Arrows", "Navigate"],
        ["Space / Enter", "OK"],
        ["Backspace / Esc", "Back"],
        ["H", "Home"],
        ["M", "Menu"],
        ["A", "Apps"],
        ["P", "Play / pause"],
        ["+ / -", "Volume up / down"],
        ["0", "Mute"],
        ["K", "Type on TV"],
        ["B", "Restart box Bluetooth"],
        ["Q / Mod+X", "Leave TV mode"]
    ]

    property bool shown: false
    property string status: ""

    function focusedScreen() {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === Hyprland.focusedMonitor?.name)
                return screens[i];
        }
        return screens[0];
    }

    FileView {
        id: themeMode
        path: Quickshell.env("HOME") + "/.cache/.theme_mode"
        watchChanges: true
        onFileChanged: reload()
    }

    IpcHandler {
        target: "tvRemote"

        function open(): void {
            root.status = "";
            root.shown = true;
        }

        function close(): void {
            root.shown = false;
        }

        function status(text: string): void {
            root.status = text;
        }
    }

    Process {
        id: leaveTvMode
        command: [Quickshell.env("HOME") + "/scripts/hyprland/tv-remote", "close"]
    }

    PanelWindow {
        visible: root.shown
        screen: root.focusedScreen()
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: 40
            right: 12
        }
        implicitWidth: 300
        implicitHeight: card.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "tv-remote"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            id: card
            width: parent.width
            implicitHeight: column.implicitHeight + 24
            radius: 7
            color: root.background
            border.color: root.border

            ColumnLayout {
                id: column
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "\u{f0502}  Xiaomi TV remote"
                        color: root.strong
                        font.family: "Myna Nerd Font"
                        font.pointSize: 11
                        font.bold: true
                    }

                    Rectangle {
                        implicitWidth: closeIcon.implicitWidth + 12
                        implicitHeight: closeIcon.implicitHeight + 6
                        radius: 5
                        color: closeMouse.containsMouse ? root.raised : "transparent"

                        Text {
                            id: closeIcon
                            anchors.centerIn: parent
                            text: "\u{f0156}"
                            color: root.foreground
                            font.family: "Myna Nerd Font"
                            font.pointSize: 11
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // the script also leaves the Hyprland submap, which the card can't do alone
                            onClicked: leaveTvMode.running = true
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 4

                    Repeater {
                        model: root.keyRows.length * 2

                        Rectangle {
                            required property int index
                            readonly property bool isKey: index % 2 === 0
                            readonly property string label: root.keyRows[Math.floor(index / 2)][index % 2]

                            Layout.fillWidth: !isKey
                            implicitWidth: caption.implicitWidth + (isKey ? 12 : 0)
                            implicitHeight: caption.implicitHeight + (isKey ? 4 : 0)
                            radius: 4
                            color: isKey ? root.raised : "transparent"

                            Text {
                                id: caption
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.isKey ? parent.horizontalCenter : undefined
                                text: parent.label
                                color: parent.isKey ? root.strong : root.foreground
                                font.family: "Myna Nerd Font"
                                font.pointSize: parent.isKey ? 9 : 10
                            }
                        }
                    }
                }

                Text {
                    visible: root.status !== ""
                    Layout.fillWidth: true
                    text: root.status
                    color: root.muted
                    wrapMode: Text.Wrap
                    font.family: "Myna Nerd Font"
                    font.pointSize: 9
                }
            }
        }
    }
}
