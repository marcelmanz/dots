import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int autoHideMs: 1500
    readonly property int startupGraceMs: 1000

    readonly property bool dark: themeMode.text().trim() === "dark"
    readonly property color background: dark ? "#000000" : "#e0e4de"
    readonly property color border: dark ? "#3a3a3a" : "#adb0ab"
    readonly property color strong: dark ? "#ffffff" : "#000000"
    readonly property color muted: dark ? "#808080" : "#64666c"

    property bool shown: false
    property bool ready: false

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(workspace => workspace.id > 0 && workspace.monitor === Hyprland.focusedMonitor)
        .sort((a, b) => a.id - b.id)

    function focusedScreen() {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === Hyprland.focusedMonitor?.name)
                return screens[i];
        }
        return screens[0];
    }

    function flash() {
        shown = true;
        hideTimer.restart();
    }

    FileView {
        id: themeMode
        path: Quickshell.env("HOME") + "/.cache/.theme_mode"
        watchChanges: true
        onFileChanged: reload()
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() {
            if (root.ready)
                root.flash();
        }
    }

    IpcHandler {
        target: "workspaces"

        function flash(): void {
            root.flash();
        }
    }

    Timer {
        running: true
        interval: root.startupGraceMs
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: root.autoHideMs
        onTriggered: root.shown = false
    }

    PanelWindow {
        visible: root.shown
        screen: root.focusedScreen()
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        margins.top: 12
        implicitWidth: island.implicitWidth
        implicitHeight: island.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "workspaces"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            id: island
            anchors.fill: parent
            implicitWidth: row.implicitWidth + 12
            implicitHeight: 30
            radius: 7
            color: root.background
            border.color: root.border

            RowLayout {
                id: row
                anchors.centerIn: parent
                spacing: 0

                Repeater {
                    model: root.workspaces

                    Text {
                        required property var modelData

                        leftPadding: 6
                        rightPadding: 6
                        text: modelData.name
                        color: modelData.focused ? root.strong : root.muted
                        font.family: "Myna Nerd Font"
                        font.pointSize: 13.3333

                        MouseArea {
                            anchors.fill: parent
                            onClicked: parent.modelData.activate()
                        }
                    }
                }
            }
        }
    }
}
