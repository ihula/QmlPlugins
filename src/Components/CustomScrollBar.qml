import QtQuick
import QtQuick.Controls.Material

ScrollBar {
    id: customScrollBar
    policy: ScrollBar.AsNeeded
    visible: customScrollBar.size < 1.0
    x: parent.mirrored ? 0 : parent.width - width
    height: parent.height
    active: parent.ScrollBar.vertical.active

    // 自定义背景轨道（通常设为透明或极淡的颜色）
    background: Rectangle {
        implicitWidth: 8
        color: "transparent"
    }

    // 自定义滑块（实现现代圆形/胶囊形外观）
    contentItem: Rectangle {
        implicitWidth: 8
        implicitHeight: (customScrollBar.pressed || customScrollBar.hovered) ? 12 : 8
        radius: 4
        color: "#999999"
    }
}
