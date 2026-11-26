import QtQuick
import QtQuick.Layouts
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
    readonly property int secondRowHeight: 26
    readonly property int screenGap: 20
    readonly property int chinGap: 8
    readonly property int cornerRadius: 8
    readonly property int innerRadius: 5
    readonly property int ironbarHeight: 30
    readonly property int sidePadding: 6
    readonly property int chinHeight: 28

    readonly property bool dark: themeMode.text().trim() === "dark"
    readonly property color background: dark ? "#000000" : "#ffffff"
    readonly property color strong: dark ? "#ffffff" : "#000000"
    readonly property color muted: dark ? "#808080" : "#64666c"
    readonly property color focusBlob: dark ? "#262626" : "#e4e4e4"
    readonly property color urgent: dark ? "#ff8a3d" : "#c4501a"
    readonly property color danger: dark ? "#ff5f57" : "#c62828"
    readonly property color scratchpad: dark ? "#ff79c6" : "#d0389a"

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

    property var scratchpadNames: ({})
    property var scratchpads: []

    property bool managing: false
    property bool confirming: false
    property int cursorIndex: 0
    property int anchorIndex: -1
    property var selectedIds: []
    readonly property var targets: {
        const ids = selectedIds.length > 0 ? selectedIds : [workspaces[cursorIndex]?.id];
        return workspaces.filter(workspace => ids.includes(workspace.id));
    }
    readonly property int targetWindows: targets.reduce((count, workspace) => count + workspace.closable.length, 0)
    readonly property int targetLocked: targets.reduce((count, workspace) => count + workspace.locked, 0)

    readonly property real contentWidth: Math.max(row.implicitWidth, managing ? secondRow.implicitWidth : 0) + 2 * sidePadding
    property real animatedContentWidth: contentWidth
    Behavior on animatedContentWidth {
        enabled: root.reveal > 0.3
        SpringAnimation { spring: 5; damping: 0.45; epsilon: 0.25 }
    }

    readonly property real targetHeight: islandHeight + (managing ? secondRowHeight : 0)
    property real animatedHeight: targetHeight
    Behavior on animatedHeight {
        enabled: root.reveal > 0.3
        SpringAnimation { spring: 6; damping: 0.5; epsilon: 0.25 }
    }

    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        SpringAnimation {
            spring: root.shown ? 16 : 9
            damping: root.shown ? 0.6 : 0.85
            epsilon: 0.002
        }
    }

    readonly property real collapsedWidth: 56
    readonly property real bodyWidth: Math.max(0, collapsedWidth + (animatedContentWidth - collapsedWidth) * reveal)

    onWorkspacesChanged: Qt.callLater(() => {
        cursorIndex = Math.max(0, Math.min(cursorIndex, workspaces.length - 1));
        const ids = workspaces.map(workspace => workspace.id);
        selectedIds = selectedIds.filter(id => ids.includes(id));
        if (confirming && targetWindows === 0)
            confirming = false;
    })

    function focusedScreen() {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === focusedMonitorName)
                return screens[i];
        }
        return screens[0];
    }

    function flash(armArrows = true) {
        if (!ready)
            return;
        shown = true;
        hideTimer.restart();
        if (armArrows && !managing)
            Hyprland.dispatch("function() workspacesPeek(true) end");
    }

    function endPeek() {
        Hyprland.dispatch("function() workspacesPeek(false) end");
    }

    function scratchpadOf(workspaceName) {
        return workspaceName.match(/^special:S-(.+)$/)?.[1];
    }

    onShownChanged: {
        if (!shown)
            endPeek();
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
                    persistent: false,
                    windows: 0,
                    closable: [],
                    locked: 0,
                    urgent: false
                };
        }

        for (const rule of state.rules) {
            const id = Number(rule.workspaceString);
            if (!rule.persistent || !(id > 0))
                continue;
            if (!byId[id])
                byId[id] = {
                    id: id,
                    name: rule.defaultName ?? String(id),
                    monitor: "",
                    windows: 0,
                    closable: [],
                    locked: 0,
                    urgent: false
                };
            byId[id].persistent = true;
        }

        for (const client of state.clients) {
            const workspace = client.mapped ? byId[client.workspace.id] : undefined;
            if (!workspace)
                continue;
            workspace.windows++;
            // Same "locked" tag safe-killactive.sh honours; Hyprland suffixes dynamic tags with "*".
            if ((client.tags ?? []).some(tag => tag.replace(/\*$/, "") === "locked"))
                workspace.locked++;
            else
                workspace.closable.push(client.address);
            if (urgentAddresses.includes(client.address))
                workspace.urgent = true;
        }

        const names = {};
        for (const client of state.clients) {
            const name = scratchpadOf(client.workspace.name) ?? scratchpadNames[client.address];
            if (name)
                names[client.address] = name;
        }
        scratchpadNames = names;
        const shownScratchpads = state.clients
            .filter(client => client.mapped && names[client.address] && client.workspace.address === state.active.address)
            .map(client => names[client.address]);
        if (JSON.stringify(shownScratchpads) !== JSON.stringify(scratchpads))
            scratchpads = shownScratchpads;

        focusedId = state.active.id;
        focusedMonitorName = state.active.monitor;
        const visibleWorkspaces = Object.values(byId)
            .filter(workspace => workspace.persistent || workspace.id === state.active.id
                || (workspace.monitor === state.active.monitor && workspace.windows > 0))
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

    function startManaging() {
        const focusedIndex = workspaces.findIndex(workspace => workspace.id === focusedId);
        cursorIndex = Math.max(0, focusedIndex);
        anchorIndex = -1;
        selectedIds = [];
        confirming = false;
        managing = true;
        shown = true;
        hideTimer.stop();
        endPeek();
    }

    function stopManaging() {
        managing = false;
        confirming = false;
        selectedIds = [];
        anchorIndex = -1;
        hideTimer.restart();
    }

    function moveCursor(step, extend) {
        const next = Math.max(0, Math.min(workspaces.length - 1, cursorIndex + step));
        if (extend) {
            if (anchorIndex < 0)
                anchorIndex = cursorIndex;
            selectedIds = workspaces
                .slice(Math.min(anchorIndex, next), Math.max(anchorIndex, next) + 1)
                .map(workspace => workspace.id);
        } else {
            anchorIndex = -1;
        }
        cursorIndex = next;
    }

    function toggleSelected() {
        const id = workspaces[cursorIndex]?.id;
        if (id === undefined)
            return;
        selectedIds = selectedIds.includes(id) ? selectedIds.filter(selected => selected !== id) : selectedIds.concat([id]);
        anchorIndex = cursorIndex;
    }

    function closeTargets() {
        const addresses = targets.flatMap(workspace => workspace.closable);
        if (addresses.length > 0) {
            windowCloser.command = ["sh", "-c", 'for address; do hyprctl dispatch "hl.dsp.window.close({ window = \\"address:$address\\" })"; done', "sh"].concat(addresses);
            windowCloser.running = true;
        }
        stopManaging();
    }

    function handleKey(key, modifiers) {
        const extend = (modifiers & Qt.ShiftModifier) !== 0;

        if (confirming) {
            if (key === Qt.Key_Y || key === Qt.Key_Return || key === Qt.Key_Enter)
                closeTargets();
            else if (key === Qt.Key_N || key === Qt.Key_Escape)
                confirming = false;
            return true;
        }

        switch (key) {
        case Qt.Key_Left:
        case Qt.Key_H:
            moveCursor(-1, extend);
            break;
        case Qt.Key_Right:
        case Qt.Key_L:
            moveCursor(1, extend);
            break;
        case Qt.Key_Home:
            moveCursor(-workspaces.length, extend);
            break;
        case Qt.Key_End:
            moveCursor(workspaces.length, extend);
            break;
        case Qt.Key_Space:
            toggleSelected();
            break;
        case Qt.Key_A:
            selectedIds = selectedIds.length === workspaces.length ? [] : workspaces.map(workspace => workspace.id);
            break;
        case Qt.Key_X:
        case Qt.Key_Delete:
            if (targetWindows > 0)
                confirming = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            focusWorkspace(workspaces[cursorIndex]?.id);
            stopManaging();
            break;
        case Qt.Key_Escape:
        case Qt.Key_Q:
            if (selectedIds.length > 0) {
                selectedIds = [];
                anchorIndex = -1;
            } else {
                stopManaging();
            }
            break;
        default:
            return false;
        }
        return true;
    }

    // Called from the arrow binds workspacesPeek arms in keybinds.lua: enter manage mode, then act on the key that triggered it.
    function enterWithKey(name) {
        const keys = {
            "left": [Qt.Key_Left, Qt.NoModifier],
            "right": [Qt.Key_Right, Qt.NoModifier]
        };
        if (!managing)
            startManaging();
        if (keys[name])
            handleKey(keys[name][0], keys[name][1]);
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
        command: ["sh", "-c", "printf '{\"workspaces\":%s,\"clients\":%s,\"active\":%s,\"rules\":%s}' \"$(hyprctl -j workspaces)\" \"$(hyprctl -j clients)\" \"$(hyprctl -j activeworkspace)\" \"$(hyprctl -j workspacerules)\""]
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

    Process {
        id: windowCloser
        stdout: StdioCollector {
            onStreamFinished: {
                const failures = text.split("\n").filter(line => line.trim() !== "" && line.trim() !== "ok");
                if (failures.length > 0)
                    console.warn("workspaces: close failed:", failures.join(" | "));
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
                root.refresh();
                root.flash();
                break;
            case "movewindowv2": {
                const [address, workspaceName] = event.data.split(",");
                const name = root.scratchpadOf(workspaceName);
                if (name)
                    root.scratchpadNames["0x" + address] = name;
                root.refresh();
                root.flash(!root.scratchpadNames["0x" + address]);
                break;
            }
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

        function enter(key: string): void {
            root.enterWithKey(key);
        }

        function manage(): void {
            if (root.managing)
                root.stopManaging();
            else
                root.startManaging();
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
            if (!root.hovered && !root.pinned && !root.managing)
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
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        margins {
            bottom: root.ironbarHeight + root.screenGap
            right: root.screenGap
        }
        implicitHeight: root.islandHeight + root.secondRowHeight + root.chinHeight + root.chinGap + 12
        mask: Region { item: hitArea }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "workspaces"
        WlrLayershell.keyboardFocus: root.managing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: keyHandler
            focus: true
            Keys.onPressed: event => {
                event.accepted = root.managing && root.handleKey(event.key, event.modifiers);
            }
        }

        Item {
            id: hitArea
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: root.shown ? Math.max(root.animatedContentWidth, chin.width) : 0
            height: root.shown ? root.targetHeight + (root.scratchpads.length > 0 ? root.chinHeight + root.chinGap : 0) : 0
        }

        Item {
            id: drop
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: root.bodyWidth
            height: root.animatedHeight
            visible: root.reveal > 0.005
            opacity: Math.max(0, Math.min(1, root.reveal / 0.6))
            scale: 0.9 + 0.1 * root.reveal
            transformOrigin: Item.BottomRight

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
                    if (root.managing)
                        root.moveCursor(event.angleDelta.y < 0 ? 1 : -1, false);
                    else
                        root.cycle(event.angleDelta.y < 0 ? 1 : -1);
                }
            }

            Rectangle {
                anchors.fill: parent
                color: root.background
                radius: root.cornerRadius
                clip: true

                Item {
                    x: (parent.width - width) / 2
                    width: root.contentWidth
                    height: root.targetHeight
                    opacity: Math.max(0, Math.min(1, (root.reveal - 0.5) / 0.4))
                    scale: 0.92 + 0.08 * Math.min(1, root.reveal)
                    transformOrigin: Item.Top

                    Rectangle {
                        id: blob
                        property real targetX: 0
                        property real targetWidth: 0
                        // Leading edge springs fast and the trailing edge lags, so the blob stretches then snaps like a drop.
                        property bool movingRight: true
                        property real leftEdge: targetX
                        property real rightEdge: targetX + targetWidth

                        x: row.x + leftEdge
                        y: row.y + (row.height - height) / 2
                        width: Math.max(height, rightEdge - leftEdge)
                        height: 24
                        radius: root.innerRadius
                        color: root.focusBlob

                        Behavior on leftEdge {
                            enabled: root.reveal > 0.3
                            SpringAnimation {
                                spring: blob.movingRight ? 5 : 11
                                damping: blob.movingRight ? 0.5 : 0.6
                                epsilon: 0.25
                            }
                        }
                        Behavior on rightEdge {
                            enabled: root.reveal > 0.3
                            SpringAnimation {
                                spring: blob.movingRight ? 11 : 5
                                damping: blob.movingRight ? 0.6 : 0.5
                                epsilon: 0.25
                            }
                        }
                    }

                    Rectangle {
                        id: cursorRing
                        property real targetX: 0
                        property real targetWidth: 0

                        x: row.x + targetX
                        y: row.y + (row.height - height) / 2
                        width: targetWidth
                        height: 24
                        radius: root.innerRadius
                        color: "transparent"
                        border.color: root.confirming ? root.danger : root.strong
                        border.width: 1.5
                        opacity: root.managing ? 1 : 0
                        z: 1

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on x {
                            enabled: root.managing
                            SpringAnimation { spring: 9; damping: 0.55; epsilon: 0.25 }
                        }
                        Behavior on width {
                            enabled: root.managing
                            SpringAnimation { spring: 9; damping: 0.55; epsilon: 0.25 }
                        }
                    }

                    Row {
                        id: row
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (root.islandHeight - height) / 2 + 1
                        spacing: 0

                        Repeater {
                            model: root.workspaces

                            Item {
                                id: pill
                                required property var modelData
                                required property int index
                                readonly property bool isFocused: modelData.id === root.focusedId
                                readonly property bool isCursor: root.managing && index === root.cursorIndex
                                readonly property bool isSelected: root.managing && root.selectedIds.includes(modelData.id)

                                implicitWidth: pillRow.implicitWidth + 14
                                implicitHeight: 26

                                function syncBlob() {
                                    if (isFocused) {
                                        blob.movingRight = x > blob.targetX;
                                        blob.targetX = x;
                                        blob.targetWidth = width;
                                    }
                                    if (index === root.cursorIndex) {
                                        cursorRing.targetX = x;
                                        cursorRing.targetWidth = width;
                                    }
                                }

                                onIsFocusedChanged: syncBlob()
                                onIsCursorChanged: syncBlob()
                                onXChanged: syncBlob()
                                onWidthChanged: syncBlob()
                                Component.onCompleted: syncBlob()

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: 24
                                    radius: root.innerRadius
                                    color: root.danger
                                    opacity: pill.isSelected ? (root.dark ? 0.35 : 0.25) : 0

                                    Behavior on opacity { NumberAnimation { duration: 120 } }
                                }

                                RowLayout {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: pill.modelData.name
                                        color: pill.isSelected || pill.isFocused ? root.strong : pill.modelData.urgent ? root.urgent : root.muted
                                        font.family: "Myna Nerd Font"
                                        font.pointSize: 13.3333
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.managing) {
                                            root.cursorIndex = pill.index;
                                            root.toggleSelected();
                                        } else {
                                            root.focusWorkspace(pill.modelData.id);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: secondRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.islandHeight - 2
                        height: root.secondRowHeight - 4
                        spacing: 10
                        opacity: root.managing ? 1 : 0

                        Behavior on opacity { NumberAnimation { duration: 140 } }

                        Text {
                            visible: !root.confirming
                            text: "←→ move   ⇧ range   space pick   a all   x close   esc"
                            color: root.muted
                            font.family: "Myna Nerd Font"
                            font.pointSize: 9.5
                        }

                        Text {
                            visible: root.confirming
                            text: `Close ${root.targetWindows} window${root.targetWindows === 1 ? "" : "s"} in ${root.targets.map(workspace => workspace.name).join(", ")}?`
                                + (root.targetLocked > 0 ? ` (${root.targetLocked} locked kept)` : "")
                            color: root.strong
                            font.family: "Myna Nerd Font"
                            font.pointSize: 10
                        }

                        Text {
                            visible: root.confirming
                            text: "y close"
                            color: root.danger
                            font.family: "Myna Nerd Font"
                            font.pointSize: 10
                            font.bold: true

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeTargets()
                            }
                        }

                        Text {
                            visible: root.confirming
                            text: "n cancel"
                            color: root.muted
                            font.family: "Myna Nerd Font"
                            font.pointSize: 10

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.confirming = false
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: chin
                anchors.right: parent.right
                y: -height - root.chinGap
                width: chinRow.implicitWidth + 20
                height: root.chinHeight
                visible: root.scratchpads.length > 0
                opacity: Math.max(0, Math.min(1, (root.reveal - 0.5) / 0.4))
                color: root.background
                border.color: root.scratchpad
                border.width: 1.5
                radius: root.cornerRadius

                Row {
                    id: chinRow
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        model: root.scratchpads

                        Text {
                            required property string modelData
                            text: modelData
                            color: root.scratchpad
                            font.family: "Myna Nerd Font"
                            font.pointSize: 13.3333
                        }
                    }
                }
            }
        }
    }
}
