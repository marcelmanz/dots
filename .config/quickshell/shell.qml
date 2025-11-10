import Quickshell 1.0
import Quickshell.Widgets 1.0
import Quickshell.Layers 1.0

LayerSurface {
    layer: "overlay"
    anchor: "center"
    width: 400
    height: 60
    exclusiveZone: -1
    keyboardFocus: true

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#202020"
        border.color: "#404040"
        border.width: 1

        TextField {
            id: input
            anchors.fill: parent
            anchors.margins: 10
            placeholderText: "Type here..."
            font.pixelSize: 16
            focus: true
            onAccepted: {
                console.log(text)
                Quickshell.quit()
            }
        }
    }
}

