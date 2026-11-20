import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int autoHideMs: 2600
    readonly property int urgentHoldMs: 6000
    readonly property int startupGraceMs: 1000

    readonly property int islandHeight: 34
    readonly property int filletRadius: 10
    readonly property int bottomRadius: 13
    readonly property int sidePadding: 6

    readonly property bool dark: themeMode.text().trim() === "dark"
    readonly property color background: dark ? "#000000" : "#e0e4de"
    readonly property color border: dark ? "#3a3a3a" : "#adb0ab"
    readonly property color strong: dark ? "#ffffff" : "#000000"
    readonly property color muted: dark ? "#808080" : "#64666c"
    readonly property color focusBlob: dark ? "#262626" : "#c9cdc6"
    readonly property color urgent: dark ? "#ff8a3d" : "#c4501a"

    property bool shown: false
    property bool ready: false
    property bool hovered: false
    property bool pinned: false

    // Built from hyprctl, not Hyprland.workspaces: with the Lua config Hyprland sends workspace ids where Quickshell expects names, so its model loses windows.
    property var workspaces: []
    property int focusedId: -1
    property string focusedMonitorName: ""
    property var urgentAddresses: []
    readonly property bool anyUrgent: workspaces.some(workspace => workspace.urgent)

    readonly property real contentWidth: row.implicitWidth + 2 * sidePadding
    property real animatedContentWidth: contentWidth
    Behavior on animatedContentWidth {
        enabled: root.reveal > 0.3
        SpringAnimation { spring: 3; damping: 0.35; epsilon: 0.25 }
    }

    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        SpringAnimation {
            spring: root.shown ? 7 : 9
            damping: root.shown ? 0.5 : 0.85
            epsilon: 0.002
        }
    }

    readonly property real collapsedWidth: 56
    readonly property real dropHeight: Math.max(0, reveal * islandHeight)
    readonly property real bodyWidth: Math.max(0, collapsedWidth + (animatedContentWidth - collapsedWidth) * reveal)

    function focusedScreen() {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === focusedMonitorName)
                return screens[i];
        }
        return screens[0];
    }

    function flash() {
        if (!ready)
            return;
        shown = true;
        hideTimer.restart();
    }

    function refresh() {
        refreshDebounce.restart();
    }

    function applyState(state) {
        const byId = {};
        for (const workspace of state.workspaces) {
            if (workspace.id > 0)
                byId[workspace.id] = {
                    id: workspace.id,
                    name: workspace.name,
                    monitor: workspace.monitor,
                    windows: 0,
                    urgent: false
                };
        }

        for (const client of state.clients) {
            const workspace = client.mapped ? byId[client.workspace.id] : undefined;
            if (!workspace)
                continue;
            workspace.windows++;
            if (urgentAddresses.includes(client.address))
                workspace.urgent = true;
        }

        focusedId = state.active.id;
        focusedMonitorName = state.active.monitor;
        const visibleWorkspaces = Object.values(byId)
            .filter(workspace => workspace.monitor === state.active.monitor
                && (workspace.windows > 0 || workspace.id === state.active.id))
            .sort((a, b) => a.id - b.id);
        if (JSON.stringify(visibleWorkspaces) !== JSON.stringify(workspaces))
            workspaces = visibleWorkspaces;
    }

    function focusWorkspace(id) {
        if (id !== focusedId)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function cycle(step) {
        const ids = workspaces.map(workspace => workspace.id);
        const index = ids.indexOf(focusedId);
        if (ids.length > 1)
            focusWorkspace(ids[(index + step + ids.length) % ids.length]);
    }

    FileView {
        id: themeMode
        path: Quickshell.env("HOME") + "/.cache/.theme_mode"
        watchChanges: true
        onFileChanged: reload()
    }

    Process {
        id: stateQuery
        property bool stale: false
        command: ["sh", "-c", "printf '{\"workspaces\":%s,\"clients\":%s,\"active\":%s}' \"$(hyprctl -j workspaces)\" \"$(hyprctl -j clients)\" \"$(hyprctl -j activeworkspace)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.applyState(JSON.parse(text));
                } catch (error) {
                    console.warn("workspaces: bad hyprctl output:", error);
                }
            }
        }
        onRunningChanged: {
            if (!running && stale) {
                stale = false;
                running = true;
            }
        }
    }

    Timer {
        id: refreshDebounce
        interval: 30
        onTriggered: {
            if (stateQuery.running)
                stateQuery.stale = true;
            else
                stateQuery.running = true;
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            switch (event.name) {
            case "workspacev2":
            case "focusedmonv2":
            case "movewindowv2":
                root.refresh();
                root.flash();
                break;
            case "urgent":
                root.urgentAddresses = root.urgentAddresses.concat(["0x" + event.data]);
                root.refresh();
                root.flash();
                break;
            case "activewindowv2": {
                const address = "0x" + event.data;
                if (root.urgentAddresses.includes(address)) {
                    root.urgentAddresses = root.urgentAddresses.filter(urgent => urgent !== address);
                    root.refresh();
                }
                break;
            }
            case "openwindow":
            case "closewindow":
            case "createworkspacev2":
            case "destroyworkspacev2":
            case "moveworkspacev2":
            case "renameworkspace":
            case "monitoraddedv2":
            case "monitorremovedv2":
                root.refresh();
                break;
            }
        }
    }

    IpcHandler {
        target: "workspaces"

        function flash(): void {
            root.flash();
        }

        function toggle(): void {
            root.pinned = !root.pinned;
            if (root.pinned)
                root.shown = true;
            else
                hideTimer.restart();
        }
    }

    Timer {
        running: true
        interval: root.startupGraceMs
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: root.anyUrgent ? root.urgentHoldMs : root.autoHideMs
        onTriggered: {
            if (!root.hovered && !root.pinned)
                root.shown = false;
        }
    }

    Timer {
        id: wheelThrottle
        interval: 180
    }

    Component.onCompleted: refresh()

    PanelWindow {
        // Stays mapped while hidden so showing never waits on a new surface; the empty mask lets input through.
        visible: true
        screen: root.focusedScreen()
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: root.islandHeight + 12
        mask: Region { item: hitArea }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "workspaces"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: hitArea
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.shown ? root.animatedContentWidth + 2 * root.filletRadius : 0
            height: root.shown ? root.islandHeight : 0
        }

        Item {
            id: drop
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.bodyWidth + 2 * root.filletRadius
            height: root.dropHeight
            visible: root.reveal > 0.005

            HoverHandler {
                onHoveredChanged: {
                    root.hovered = hovered;
                    if (!hovered)
                        hideTimer.restart();
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    if (wheelThrottle.running || event.angleDelta.y === 0)
                        return;
                    wheelThrottle.start();
                    root.cycle(event.angleDelta.y < 0 ? 1 : -1);
                }
            }

            Repeater {
                model: [false, true]

                Shape {
                    required property bool modelData
                    readonly property real f: root.filletRadius

                    x: modelData ? drop.width - f : 0
                    width: f
                    height: f
                    preferredRendererType: Shape.CurveRenderer
                    transform: [
                        Scale {
                            origin.x: root.filletRadius / 2
                            xScale: modelData ? -1 : 1
                        },
                        Scale {
                            origin.x: modelData ? 0 : root.filletRadius
                            xScale: Math.min(1, root.dropHeight / (2 * root.filletRadius))
                            yScale: xScale
                        }
                    ]

                    ShapePath {
                        strokeWidth: -1
                        fillColor: root.background
                        PathSvg { path: `M 0 0 L ${root.filletRadius} 0 L ${root.filletRadius} ${root.filletRadius} A ${root.filletRadius} ${root.filletRadius} 0 0 0 0 0 Z` }
                    }

                    ShapePath {
                        strokeWidth: 1
                        strokeColor: root.border
                        fillColor: "transparent"
                        PathSvg { path: `M 0 0 A ${root.filletRadius} ${root.filletRadius} 0 0 1 ${root.filletRadius} ${root.filletRadius}` }
                    }
                }
            }

            Rectangle {
                readonly property real corner: Math.max(0, Math.min(root.bottomRadius, height / 2, width / 2))

                x: root.filletRadius
                y: -1
                width: root.bodyWidth
                height: parent.height + 1
                color: root.background
                border.color: root.border
                topLeftRadius: 0
                topRightRadius: 0
                bottomLeftRadius: corner
                bottomRightRadius: corner
                clip: true

                Item {
                    x: (parent.width - width) / 2
                    y: 1
                    width: root.contentWidth
                    height: root.islandHeight
                    opacity: Math.max(0, Math.min(1, (root.reveal - 0.5) / 0.4))
                    scale: 0.92 + 0.08 * Math.min(1, root.reveal)
                    transformOrigin: Item.Top

                    Rectangle {
                        id: blob
                        property real targetX: 0
                        property real targetWidth: 0

                        x: row.x + targetX
                        y: row.y + (row.height - height) / 2
                        width: targetWidth
                        height: 24
                        radius: height / 2
                        color: root.focusBlob

                        Behavior on x {
                            enabled: root.reveal > 0.3
                            SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.25 }
                        }
                        Behavior on width {
                            enabled: root.reveal > 0.3
                            SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.25 }
                        }
                    }

                    Row {
                        id: row
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 1
                        spacing: 0

                        Repeater {
                            model: root.workspaces

                            Item {
                                id: pill
                                required property var modelData
                                readonly property bool isFocused: modelData.id === root.focusedId

                                implicitWidth: pillRow.implicitWidth + 14
                                implicitHeight: 26

                                function syncBlob() {
                                    if (isFocused) {
                                        blob.targetX = x;
                                        blob.targetWidth = width;
                                    }
                                }

                                onIsFocusedChanged: syncBlob()
                                onXChanged: syncBlob()
                                onWidthChanged: syncBlob()
                                Component.onCompleted: syncBlob()

                                RowLayout {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: pill.modelData.name
                                        color: pill.modelData.urgent ? root.urgent : pill.isFocused ? root.strong : root.muted
                                        font.family: "Myna Nerd Font"
                                        font.pointSize: 13.3333
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.focusWorkspace(pill.modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
