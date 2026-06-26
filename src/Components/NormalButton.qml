import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Fusion
import HulaPlugins

Button {
    id: root
    implicitWidth: 64
    implicitHeight: 32
    property int radius: 2
    signal mousePressed(int x, int y, var obj)

    background: Rectangle {
        id: btnBack
        radius: root.radius
        border.width: root.focus ? 0 : 0
        border.color: "#1afa29"
        color: parent.pressed ? Themer.pressedColor : (parent.hovered ? Themer.normalColor : Themer.hoveredColor)
    }

    contentItem: Text {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.text
        color: "white"
    }

    onPressed: {
        mousePressed(pressX, pressY, this);
    }

    // ClickShow {
    //     id: clickShow
    // }
}
