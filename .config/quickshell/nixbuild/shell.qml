import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/scripts/hyprland/nixbuild"
    readonly property int maxFiles: 8
    readonly property int autoHideMs: 8000
    readonly property var hosts: ["", "mlab"]

    readonly property color background: "#1c1c1c"
    readonly property color border: "#3a3a3a"
    readonly property color foreground: "#e6e6e6"
    readonly property color dim: "#8a8a8a"
    readonly property color green: "#5fb878"
    readonly property color red: "#e06c75"
    readonly property color yellow: "#d9a441"
    readonly property color blue: "#6aa9e0"

    property bool shown: false
    property string mode: "idle"
    property string host: ""
    property bool infoQueued: false
    property bool checkQueued: false
    property string target: ""
    property var files: []
    property int untracked: 0

    property string checkState: "idle"
    property bool upToDate: false
    property int toBuild: 0
    property int toFetch: 0
    property string checkError: ""

    property string label: ""
    property string line: ""
    property int done: 0
    property int total: 0
    property int percent: 0
    property bool cancellable: true
    property int elapsed: 0
    property string error: ""

    function show() {
        shown = true;
        if (mode === "building")
            return;
        mode = "idle";
        if (!infoProcess.running)
            infoProcess.running = true;
        if (!checkProcess.running) {
            checkState = "checking";
            checkProcess.running = true;
        }
    }

    function hide() {
        shown = false;
        hideTimer.stop();
    }

    function cycleHost() {
        host = hosts[(hosts.indexOf(host) + 1) % hosts.length];
        if (infoProcess.running)
            infoQueued = true;
        else
            infoProcess.running = true;
        checkState = "checking";
        if (checkProcess.running) {
            checkQueued = true;
            checkProcess.running = false;
        } else {
            checkProcess.running = true;
        }
    }

    function toggle() {
        if (shown)
            hide();
        else
            show();
    }

    function build() {
        if (mode === "building")
            return;
        hideTimer.stop();
        label = "evaluating configuration";
        line = "";
        done = 0;
        total = 0;
        percent = 0;
        cancellable = true;
        elapsed = 0;
        error = "";
        mode = "building";
        buildProcess.running = true;
    }

    function cancel() {
        if (mode === "building" && cancellable)
            buildProcess.running = false;
    }

    function diff() {
        hide();
        diffProcess.running = true;
    }

    function edit() {
        hide();
        editProcess.running = true;
    }

    function openLog() {
        hide();
        logProcess.running = true;
    }

    function applyCheck(text) {
        const result = JSON.parse(text);
        if (result.host !== host)
            return;
        if (!result.checked) {
            checkState = "idle";
            return;
        }
        checkError = result.error;
        if (result.error !== "") {
            checkState = "error";
            return;
        }
        upToDate = result.upToDate;
        toBuild = result.toBuild;
        toFetch = result.toFetch;
        checkState = "ready";
    }

    function applyInfo(text) {
        const info = JSON.parse(text);
        if (info.host !== host)
            return;
        target = info.target;
        files = info.files;
        untracked = info.untracked;
    }

    function applyBuildLine(text) {
        const update = JSON.parse(text);
        if (update.state === "building") {
            label = update.label;
            line = update.line;
            done = update.done;
            total = update.total;
            if (total > 0)
                percent = Math.max(percent, Math.min(100, Math.floor(100 * done / total)));
            cancellable = update.cancellable;
            return;
        }
        finish(update.state, update.seconds, update.error);
    }

    function finish(state, seconds, message) {
        if (mode !== "building")
            return;
        mode = state;
        elapsed = seconds;
        error = message;
        shown = true;
        if (state !== "failed")
            hideTimer.restart();
    }

    function formatDuration(seconds) {
        const minutes = Math.floor(seconds / 60);
        return minutes > 0 ? minutes + "m " + (seconds % 60) + "s" : seconds + "s";
    }

    function statusColor(status) {
        if (status === "A")
            return green;
        if (status === "D")
            return red;
        if (status === "?")
            return blue;
        return yellow;
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
            hide();
            event.accepted = true;
        } else if (mode === "idle" && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            build();
            event.accepted = true;
        } else if (mode === "idle" && event.key === Qt.Key_Backtab && hosts.length > 1) {
            cycleHost();
            event.accepted = true;
        } else if (mode === "idle" && event.key === Qt.Key_D && files.length > 0) {
            diff();
            event.accepted = true;
        } else if (mode === "failed" && event.key === Qt.Key_L) {
            openLog();
            event.accepted = true;
        } else if ((mode === "idle" || mode === "failed") && event.key === Qt.Key_E) {
            edit();
            event.accepted = true;
        }
    }

    IpcHandler {
        target: "nixbuild"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.show();
        }

        function hide(): void {
            root.hide();
        }
    }

    Process {
        id: infoProcess
        command: [root.script, "info", root.host]
        stdout: StdioCollector {
            onStreamFinished: root.applyInfo(text)
        }
        onExited: {
            if (root.infoQueued) {
                root.infoQueued = false;
                running = true;
            }
        }
    }

    Process {
        id: checkProcess
        command: [root.script, "check", root.host]
        stdout: StdioCollector {
            onStreamFinished: root.applyCheck(text)
        }
        onExited: {
            if (root.checkQueued) {
                root.checkQueued = false;
                running = true;
            }
        }
    }

    Process {
        id: diffProcess
        command: [root.script, "diff"]
        onExited: root.show()
    }

    Process {
        id: editProcess
        command: [root.script, "edit"]
        onExited: root.show()
    }

    Process {
        id: logProcess
        command: [root.script, "log"]
        onExited: root.shown = true
    }

    Process {
        id: buildProcess
        command: [root.script, "build", root.host]
        stdout: SplitParser {
            onRead: data => root.applyBuildLine(data)
        }
        onExited: root.finish("failed", root.elapsed, "build process exited unexpectedly")
    }

    Timer {
        id: hideTimer
        interval: root.autoHideMs
        onTriggered: root.hide()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.mode === "building"
        onTriggered: root.elapsed += 1
    }

    component Btn: Rectangle {
        id: btn
        property string text
        property string hint: ""
        property color tint: "#2a2a2a"
        signal clicked

        implicitWidth: caption.implicitWidth + 24
        implicitHeight: 30
        radius: 6
        opacity: enabled ? 1 : 0.4
        color: mouse.containsMouse ? Qt.lighter(tint, 1.3) : tint
        border.color: root.border

        Text {
            id: caption
            anchors.centerIn: parent
            text: btn.text + (btn.hint !== "" ? "  " + btn.hint : "")
            color: root.foreground
            font.family: "Myna Nerd Font"
            font.pixelSize: 13
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            onClicked: btn.clicked()
        }
    }

    PanelWindow {
        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            right: true
        }
        margins {
            top: 12
            right: 12
        }
        implicitWidth: 440
        implicitHeight: card.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nixbuild"
        WlrLayershell.keyboardFocus: root.mode === "idle" || root.mode === "failed" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            id: card
            width: parent.width
            implicitHeight: column.implicitHeight + 28
            radius: 10
            color: root.background
            border.color: root.border
            focus: true
            Keys.onPressed: event => root.handleKey(event)

            ColumnLayout {
                id: column
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.target
                        color: root.foreground
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.mode === "building" || root.mode === "done" || root.mode === "failed"
                        text: root.formatDuration(root.elapsed)
                        color: root.dim
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 12
                    }
                }

                ColumnLayout {
                    visible: root.mode === "idle"
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        visible: root.files.length === 0
                        text: "No uncommitted changes"
                        color: root.dim
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: root.files.slice(0, root.maxFiles)

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: modelData.status
                                color: root.statusColor(modelData.status)
                                font.family: "monospace"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.path
                                color: root.foreground
                                elide: Text.ElideLeft
                                font.family: "monospace"
                                font.pixelSize: 13
                            }
                        }
                    }

                    Text {
                        visible: root.files.length > root.maxFiles
                        text: "+" + (root.files.length - root.maxFiles) + " more"
                        color: root.dim
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        visible: root.checkState !== "idle"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 12
                        text: root.checkState === "checking" ? "checking for changes..."
                            : root.checkState === "error" ? root.checkError
                            : root.upToDate ? "Up to date, nothing to build"
                            : root.toBuild + " to build, " + root.toFetch + " to fetch"
                        color: root.checkState === "error" ? root.red
                            : root.checkState === "ready" && root.upToDate ? root.green
                            : root.checkState === "ready" ? root.blue
                            : root.dim
                    }

                    Text {
                        visible: root.untracked > 0
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: root.untracked + " untracked: the flake ignores them until git add"
                        color: root.yellow
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 12
                    }
                }

                ColumnLayout {
                    visible: root.mode === "building"
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: root.label
                            color: root.foreground
                            elide: Text.ElideMiddle
                            font.family: "Myna Nerd Font"
                            font.pixelSize: 13
                        }

                        Text {
                            visible: root.total > 0
                            text: root.percent + "%"
                            color: root.blue
                            font.family: "Myna Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    Rectangle {
                        id: track
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: "#2a2a2a"
                        clip: true

                        Rectangle {
                            visible: root.total > 0
                            height: parent.height
                            radius: 3
                            color: root.blue
                            width: track.width * root.percent / 100

                            Behavior on width {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                        }

                        Rectangle {
                            id: sweep
                            visible: root.total === 0
                            width: track.width * 0.3
                            height: parent.height
                            radius: 3
                            color: root.blue

                            SequentialAnimation on x {
                                running: sweep.visible
                                loops: Animation.Infinite

                                NumberAnimation {
                                    from: 0
                                    to: track.width * 0.7
                                    duration: 900
                                }

                                NumberAnimation {
                                    from: track.width * 0.7
                                    to: 0
                                    duration: 900
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.total > 0 ? root.done + "/" + root.total + (root.line !== "" ? "  " + root.line : "") : root.line
                        visible: text !== ""
                        color: root.dim
                        elide: Text.ElideRight
                        font.family: "monospace"
                        font.pixelSize: 12
                    }
                }

                Text {
                    visible: root.mode === "done"
                    text: "Done"
                    color: root.green
                    font.family: "Myna Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    visible: root.mode === "cancelled"
                    text: "Cancelled"
                    color: root.yellow
                    font.family: "Myna Nerd Font"
                    font.pixelSize: 14
                    font.bold: true
                }

                ColumnLayout {
                    visible: root.mode === "failed"
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Failed"
                        color: root.red
                        font.family: "Myna Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        visible: root.error !== ""
                        Layout.fillWidth: true
                        text: root.error
                        color: root.dim
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 8
                        elide: Text.ElideRight
                        font.family: "monospace"
                        font.pixelSize: 12
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Btn {
                        visible: root.mode === "idle"
                        text: root.checkState === "ready" && root.upToDate ? "Rebuild" : "Build"
                        hint: "Enter"
                        tint: "#24402f"
                        onClicked: root.build()
                    }

                    Btn {
                        visible: root.mode === "idle" && root.hosts.length > 1
                        text: "Host"
                        hint: "S-Tab"
                        onClicked: root.cycleHost()
                    }

                    Btn {
                        visible: root.mode === "idle"
                        enabled: root.files.length > 0
                        text: "Diff"
                        hint: "d"
                        onClicked: root.diff()
                    }

                    Btn {
                        visible: root.mode === "building"
                        enabled: root.cancellable
                        text: "Cancel"
                        tint: "#40262a"
                        onClicked: root.cancel()
                    }

                    Btn {
                        visible: root.mode === "failed"
                        text: "Open log"
                        hint: "l"
                        onClicked: root.openLog()
                    }

                    Btn {
                        visible: root.mode === "idle" || root.mode === "failed"
                        text: "Edit"
                        hint: "e"
                        onClicked: root.edit()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Btn {
                        text: "Close"
                        hint: "Esc q"
                        onClicked: root.hide()
                    }
                }
            }
        }
    }
}
