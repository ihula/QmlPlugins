import QtQuick
import QtQuick.Controls.Material

ScrollBar {
    id: customScrollBar
    policy: ScrollBar.AsNeeded

    // 自定义背景轨道（通常设为透明或极淡的颜色）
    background: Rectangle {
        implicitWidth: 6
        color: "transparent"
    }

    // 自定义滑块（实现现代圆形/胶囊形外观）
    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: (customScrollBar.pressed || customScrollBar.hovered) ? 12 : 6
        radius: width / 2
        color: "#B8B8B8"
    }
}
