import QtQuick
import QtQuick.Controls

ToolTip {
    id: root
    visible: parent.hovered && String(text).length
    font.pixelSize: 16
    contentItem: Text {
        text: root.text
        font: root.font
        color: "white"
    }

    background: Rectangle {
        color: "#505050"
        radius: 4
    }
}
