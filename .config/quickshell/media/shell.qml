import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int cardWidth: 360
    readonly property int labelMaxLength: 40

    readonly property bool dark: themeMode.text().trim() === "dark"
    readonly property color background: dark ? "#000000" : "#e0e4de"
    readonly property color raised: dark ? "#2e2e2e" : "#adb0ab"
    readonly property color border: dark ? "#3a3a3a" : "#adb0ab"
    readonly property color foreground: dark ? "#d0d0d0" : "#2c2e33"
    readonly property color strong: dark ? "#ffffff" : "#000000"
    readonly property color muted: dark ? "#808080" : "#64666c"

    property bool shown: false
    property string pinnedPlayer: ""

    readonly property var players: Mpris.players.values
    readonly property var player: {
        const playing = players.filter(candidate => candidate.isPlaying);
        const pinned = players.find(candidate => candidate.dbusName === pinnedPlayer);
        if (pinned && (pinned.isPlaying || playing.length === 0))
            return pinned;
        return playing[0] ?? pinned ?? players[0] ?? null;
    }

    readonly property string label: {
        if (!player || player.trackTitle === "")
            return "";
        const text = player.trackArtist !== "" ? player.trackTitle + " - " + player.trackArtist : player.trackTitle;
        const truncated = text.length > labelMaxLength ? text.slice(0, labelMaxLength - 1) + "…" : text;
        return (player.isPlaying ? "\u{f040a} " : "\u{f03e4} ") + truncated;
    }

    function focusedScreen() {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === Hyprland.focusedMonitor?.name)
                return screens[i];
        }
        return screens[0];
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        const secondsPart = total % 60;
        return Math.floor(total / 60) + ":" + (secondsPart < 10 ? "0" : "") + secondsPart;
    }

    FileView {
        id: themeMode
        path: Quickshell.env("HOME") + "/.cache/.theme_mode"
        watchChanges: true
        onFileChanged: reload()
    }

    IpcHandler {
        target: "media"

        function toggle(): void {
            root.shown = !root.shown;
        }

        function open(): void {
            root.shown = true;
        }

        function close(): void {
            root.shown = false;
        }

        function playPause(): void {
            if (root.player?.canTogglePlaying)
                root.player.togglePlaying();
        }

        function label(): string {
            return root.label;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.shown && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    component Btn: Rectangle {
        id: btn
        property string text
        property bool highlighted: false
        property real pointSize: 10
        signal clicked

        implicitWidth: caption.implicitWidth + 16
        implicitHeight: caption.implicitHeight + 8
        radius: 5
        opacity: enabled ? 1 : 0.4
        color: highlighted || mouse.containsMouse ? root.raised : "transparent"

        Text {
            id: caption
            anchors.centerIn: parent
            text: btn.text
            color: btn.highlighted ? root.strong : root.foreground
            font.family: "Myna Nerd Font"
            font.pointSize: btn.pointSize
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            onClicked: btn.clicked()
        }
    }

    component Track: Rectangle {
        id: track
        property real value: 0
        property bool interactive: false
        signal picked(real ratio)

        implicitHeight: 4
        radius: 2
        color: root.raised

        Rectangle {
            width: track.width * Math.max(0, Math.min(1, track.value))
            height: parent.height
            radius: 2
            color: root.foreground
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            enabled: track.interactive
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => track.picked(Math.max(0, Math.min(1, mouse.x / track.width)))
        }
    }

    PanelWindow {
        visible: root.shown
        screen: root.focusedScreen()
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors {
            bottom: true
            left: true
        }
        margins {
            bottom: 40
            left: 12
        }
        implicitWidth: root.cardWidth
        implicitHeight: card.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "media"
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
                spacing: 10

                Flow {
                    Layout.fillWidth: true
                    visible: root.players.length > 1
                    spacing: 6

                    Repeater {
                        model: root.players

                        Btn {
                            required property var modelData
                            text: modelData.identity
                            pointSize: 9
                            highlighted: modelData === root.player
                            onClicked: root.pinnedPlayer = modelData.dbusName
                        }
                    }
                }

                Text {
                    visible: !root.player
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    horizontalAlignment: Text.AlignHCenter
                    text: "No media playing"
                    color: root.muted
                    font.family: "Myna Nerd Font"
                    font.pointSize: 10
                }

                RowLayout {
                    visible: !!root.player
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 72
                        radius: 5
                        color: root.raised
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            visible: art.status !== Image.Ready
                            text: "\u{f075a}"
                            color: root.muted
                            font.family: "Myna Nerd Font"
                            font.pointSize: 22
                        }

                        Image {
                            id: art
                            anchors.fill: parent
                            source: root.player?.trackArtUrl ?? ""
                            sourceSize.width: 144
                            sourceSize.height: 144
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: root.player?.trackTitle || "Unknown title"
                            color: root.strong
                            elide: Text.ElideRight
                            font.family: "Myna Nerd Font"
                            font.pointSize: 11
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: root.player?.trackArtist ?? ""
                            color: root.foreground
                            elide: Text.ElideRight
                            font.family: "Myna Nerd Font"
                            font.pointSize: 10
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: root.player?.trackAlbum ?? ""
                            color: root.muted
                            elide: Text.ElideRight
                            font.family: "Myna Nerd Font"
                            font.pointSize: 9.5
                        }
                    }
                }

                ColumnLayout {
                    visible: !!root.player && root.player.lengthSupported && root.player.length > 0
                    Layout.fillWidth: true
                    spacing: 4

                    Track {
                        Layout.fillWidth: true
                        value: root.player ? root.player.position / root.player.length : 0
                        interactive: root.player?.canSeek ?? false
                        onPicked: ratio => root.player.position = ratio * root.player.length
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.formatTime(root.player?.position ?? 0)
                            color: root.muted
                            font.family: "Myna Nerd Font"
                            font.pointSize: 9
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: root.formatTime(root.player?.length ?? 0)
                            color: root.muted
                            font.family: "Myna Nerd Font"
                            font.pointSize: 9
                        }
                    }
                }

                RowLayout {
                    visible: !!root.player
                    Layout.fillWidth: true
                    spacing: 4

                    Btn {
                        text: "\u{f04ae}"
                        pointSize: 13
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player.previous()
                    }

                    Btn {
                        text: root.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}"
                        pointSize: 13
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player.togglePlaying()
                    }

                    Btn {
                        text: "\u{f04ad}"
                        pointSize: 13
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player.next()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.player?.volumeSupported ?? false
                        text: "\u{f057e}"
                        color: root.muted
                        font.family: "Myna Nerd Font"
                        font.pointSize: 11
                    }

                    Track {
                        visible: root.player?.volumeSupported ?? false
                        Layout.preferredWidth: 90
                        value: root.player?.volume ?? 0
                        interactive: true
                        onPicked: ratio => root.player.volume = ratio
                    }
                }
            }
        }
    }
}
