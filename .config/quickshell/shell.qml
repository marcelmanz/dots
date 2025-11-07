import Quickshell
import Quickshell.Services
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
  id: bar
  anchors {
    top: true
    left: true
    right: true
  }
  height: 28
  color: "#1e1e2e"

  RowLayout {
    anchors.fill: parent
    anchors.margins: 6
    spacing: 12

    // Left section
    RowLayout {
      Layout.alignment: Qt.AlignLeft
      spacing: 8

      Text {
        text: "󰣇  Workspaces"
        color: "#cdd6f4"
        font.bold: true
      }
    }

    // Center section
    Item {
      Layout.fillWidth: true
      Text {
        anchors.centerIn: parent
        text: Shell.focusedWindow?.title ?? "Desktop"
        color: "#cdd6f4"
      }
    }

    // Right section
    RowLayout {
      Layout.alignment: Qt.AlignRight
      spacing: 12

      Text {
        text: VolumeService.default.sink.volume + "%"
        color: "#cdd6f4"
      }

      Text {
        text: Qt.formatDateTime(new Date(), "ddd dd MMM hh:mm")
        color: "#cdd6f4"
      }
    }
  }
}

