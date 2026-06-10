import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QmlPlugins 1.0

TextField {
    id: textField
    placeholderText: qsTr("请输入")
    font.pixelSize: 14
    verticalAlignment: Text.AlignVCenter

    // 背景颜色
    background: Rectangle {
        color: Themer.theme.backColor
        border.color: Themer.theme.borderColor
        border.width: 1
        radius: 4
    }

    // 焦点状态
    states: State {
        name: "focused"
        when: textField.activeFocus
        PropertyChanges {
            target: textField.background
            border.color: Material.Indigo
            border.width: 2
        }
    }

    // 过渡动画
    transitions: Transition {
        PropertyAnimation {
            properties: "border.color, border.width"
            duration: 150
        }
    }

    // 左侧留白
    leftPadding: 10
    rightPadding: 10
    topPadding: 0
    bottomPadding: 0
}
