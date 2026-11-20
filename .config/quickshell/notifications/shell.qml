//@ pragma IconTheme breeze-dark

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int panelWidth: 380
    readonly property int maxPopups: 5
    readonly property int timeoutLowMs: 4000
    readonly property int timeoutNormalMs: 6000

    readonly property bool dark: themeMode.text().trim() === "dark"
    readonly property color background: dark ? "#000000" : "#e0e4de"
    readonly property color surface: dark ? "#141414" : "#d4d8d2"
    readonly property color raised: dark ? "#2e2e2e" : "#adb0ab"
    readonly property color border: dark ? "#3a3a3a" : "#adb0ab"
    readonly property color foreground: dark ? "#d0d0d0" : "#2c2e33"
    readonly property color strong: dark ? "#ffffff" : "#000000"
    readonly property color muted: dark ? "#808080" : "#64666c"
    readonly property color critical: dark ? "#e06c75" : "#b3261e"

    property bool centerOpen: false
    property bool dnd: false
    property bool dndToastShown: false
    property string toastText: ""
    property bool toastMuted: false
    property var popups: []
    property var arrivals: ({})
    property real now: Date.now()

    readonly property var history: server.trackedNotifications.values.slice().reverse()

    onDndChanged: showToast(dnd ? "\u{f009b}  Do not disturb on" : "\u{f009a}  Do not disturb off", !dnd)

    function showToast(text, muted) {
        toastText = text;
        toastMuted = muted;
        dndToastShown = true;
        dndToastTimer.restart();
    }

    readonly property string icon: {
        const some = history.length > 0;
        if (centerOpen)
            return dnd ? "\u{f116e}" : some ? "\u{f1941}" : "\u{f0361}";
        return dnd ? "\u{f116f}" : some ? "\u{f1942}" : "\u{f0365}";
    }

    function focusedScreen() {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === Hyprland.focusedMonitor?.name)
                return screens[i];
        }
        return screens[0];
    }

    function receive(notification) {
        arrivals[notification.id] = Date.now();
        notification.tracked = true;
        notification.closed.connect(() => removePopup(notification));
        if (dnd && notification.urgency !== NotificationUrgency.Critical)
            return;
        popups = [notification].concat(popups.filter(popup => popup !== notification)).slice(0, maxPopups);
    }

    function removePopup(notification) {
        popups = popups.filter(popup => popup && popup !== notification);
    }

    function timeoutFor(notification) {
        if (notification.expireTimeout > 0)
            return notification.expireTimeout;
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        return notification.urgency === NotificationUrgency.Low ? timeoutLowMs : timeoutNormalMs;
    }

    function expirePopup(notification) {
        removePopup(notification);
        if (notification.transient)
            notification.expire();
    }

    function defaultAction(notification) {
        return notification.actions.find(action => action.identifier === "default") ?? null;
    }

    function activate(notification) {
        const action = defaultAction(notification);
        if (action)
            action.invoke();
        else
            removePopup(notification);
    }

    function clear() {
        server.trackedNotifications.values.slice().forEach(notification => notification.dismiss());
    }

    function iconSource(notification) {
        const image = notification.image;
        if (image.startsWith("image://icon/"))
            return Quickshell.iconPath(image.slice("image://icon/".length), true);
        if (image !== "")
            return image;
        const appIcon = notification.appIcon;
        if (appIcon.startsWith("/"))
            return "file://" + appIcon;
        if (appIcon.startsWith("file://"))
            return appIcon;
        if (appIcon !== "")
            return Quickshell.iconPath(appIcon, true);
        if (notification.desktopEntry !== "")
            return Quickshell.iconPath(notification.desktopEntry, true);
        return "";
    }

    function formatTime(id) {
        const arrival = arrivals[id];
        if (arrival === undefined)
            return "";
        const minutes = Math.floor((now - arrival) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return minutes + "m";
        return Qt.formatTime(new Date(arrival), "hh:mm");
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: notification => root.receive(notification)
    }

    FileView {
        id: themeMode
        path: Quickshell.env("HOME") + "/.cache/.theme_mode"
        watchChanges: true
        onFileChanged: reload()
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            root.centerOpen = !root.centerOpen;
        }

        function open(): void {
            root.centerOpen = true;
        }

        function close(): void {
            root.centerOpen = false;
        }

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }

        function clear(): void {
            root.clear();
        }

        function toast(text: string): void {
            root.showToast(text, false);
        }

        function icon(): string {
            return root.icon;
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }

    Timer {
        id: dndToastTimer
        interval: 1500
        onTriggered: root.dndToastShown = false
    }

    component Btn: Rectangle {
        id: btn
        property string text
        property string keyHint
        property bool highlighted: false
        signal clicked

        implicitWidth: captionRow.implicitWidth + 16
        implicitHeight: 24
        radius: 5
        color: highlighted || mouse.containsMouse ? root.raised : "transparent"
        border.color: root.border

        Row {
            id: captionRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: btn.text
                color: btn.highlighted ? root.strong : root.foreground
                font.family: "Myna Nerd Font"
                font.pointSize: 10
            }

            Text {
                visible: btn.keyHint !== ""
                text: btn.keyHint
                color: root.muted
                font.family: "Myna Nerd Font"
                font.pointSize: 9
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    component Card: Rectangle {
        id: card
        required property var notification
        property bool popup: false
        readonly property bool hovered: hover.containsMouse
        readonly property string iconUrl: root.iconSource(notification)

        implicitWidth: root.panelWidth
        implicitHeight: content.implicitHeight + 20
        radius: 7
        color: popup ? root.background : root.surface
        border.color: notification.urgency === NotificationUrgency.Critical ? root.critical : root.border

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.activate(card.notification)
        }

        Timer {
            interval: root.timeoutFor(card.notification)
            running: card.popup && interval > 0 && !card.hovered
            onTriggered: root.expirePopup(card.notification)
        }

        RowLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 10
            }
            spacing: 10

            Image {
                visible: card.iconUrl !== "" && status !== Image.Error
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignTop
                source: card.iconUrl
                sourceSize.width: 80
                sourceSize.height: 80
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: card.notification.appName
                        color: root.muted
                        elide: Text.ElideRight
                        font.family: "Myna Nerd Font"
                        font.pointSize: 9.5
                    }

                    Text {
                        text: root.formatTime(card.notification.id)
                        color: root.muted
                        font.family: "Myna Nerd Font"
                        font.pointSize: 9.5
                    }

                    Text {
                        text: "\u{f0156}"
                        color: closeMouse.containsMouse ? root.critical : root.muted
                        font.family: "Myna Nerd Font"
                        font.pointSize: 11

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            onClicked: card.notification.dismiss()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notification.summary
                    color: root.strong
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: "Myna Nerd Font"
                    font.pointSize: 11
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: card.notification.body
                    textFormat: Text.StyledText
                    color: root.foreground
                    linkColor: root.strong
                    wrapMode: Text.Wrap
                    maximumLineCount: card.popup ? 4 : 8
                    elide: Text.ElideRight
                    font.family: "Myna Nerd Font"
                    font.pointSize: 10
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    visible: actionRepeater.count > 0
                    spacing: 6

                    Repeater {
                        id: actionRepeater
                        model: card.notification.actions.filter(action => action.identifier !== "default")

                        Btn {
                            required property var modelData
                            text: modelData.text
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: (root.popups.length > 0 || root.dndToastShown) && !root.centerOpen
        screen: root.focusedScreen()
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
        implicitWidth: Math.max(1, popupColumn.implicitWidth)
        implicitHeight: Math.max(1, popupColumn.implicitHeight)

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notifications-popup"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        ColumnLayout {
            id: popupColumn
            width: parent.width
            spacing: 8

            Rectangle {
                id: dndToast
                visible: root.dndToastShown
                Layout.alignment: Qt.AlignRight
                implicitWidth: dndToastLabel.implicitWidth + 24
                implicitHeight: 30
                radius: 7
                color: root.background
                border.color: root.border

                Text {
                    id: dndToastLabel
                    anchors.centerIn: parent
                    text: root.toastText
                    color: root.toastMuted ? root.muted : root.strong
                    font.family: "Myna Nerd Font"
                    font.pointSize: 10
                }
            }

            Repeater {
                model: root.popups

                Card {
                    required property var modelData
                    Layout.fillWidth: true
                    notification: modelData
                    popup: true
                }
            }
        }
    }

    PanelWindow {
        id: centerWindow
        visible: root.centerOpen
        screen: root.focusedScreen()
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
        implicitWidth: root.panelWidth + 20
        implicitHeight: panel.implicitHeight

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notifications-center"
        WlrLayershell.keyboardFocus: root.centerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            active: root.centerOpen
            windows: [centerWindow]
            onCleared: root.centerOpen = false
        }

        Rectangle {
            id: panel
            width: parent.width
            implicitHeight: panelColumn.implicitHeight + 20
            radius: 7
            color: root.background
            border.color: root.border
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                    root.centerOpen = false;
                    event.accepted = true;
                } else if (event.key === Qt.Key_D) {
                    root.dnd = !root.dnd;
                    event.accepted = true;
                } else if (event.key === Qt.Key_C) {
                    root.clear();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: panelColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 10
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Notifications"
                        color: root.strong
                        font.family: "Myna Nerd Font"
                        font.pointSize: 12
                        font.bold: true
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Btn {
                        text: "\u{f009b} DND"
                        keyHint: "d"
                        highlighted: root.dnd
                        onClicked: root.dnd = !root.dnd
                    }

                    Btn {
                        text: "Clear"
                        keyHint: "c"
                        onClicked: root.clear()
                    }

                    Btn {
                        text: "\u{f0156}"
                        keyHint: "q"
                        onClicked: root.centerOpen = false
                    }
                }

                Text {
                    visible: root.history.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    Layout.bottomMargin: 12
                    horizontalAlignment: Text.AlignHCenter
                    text: "No notifications"
                    color: root.muted
                    font.family: "Myna Nerd Font"
                    font.pointSize: 10
                }

                ListView {
                    visible: root.history.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, (centerWindow.screen?.height ?? 1080) - 120)
                    clip: true
                    spacing: 8
                    model: root.history

                    delegate: Card {
                        required property var modelData
                        width: ListView.view.width
                        notification: modelData
                    }
                }
            }
        }
    }
}
