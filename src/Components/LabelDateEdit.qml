import QtQuick
import QtQuick.Controls.Fusion

TextField {
    id: control
    readonly property int labelLeft: 1
    readonly property int labelTop: 2
    property int labelPosition: labelLeft
    property int labelSpacing: 2
    property color accentColor: "#2196f3"
    property bool hasEdited: false
    property string dateFormat: "yyyy-MM-dd"
    property string labelText: ""
    property alias date: calendarPicker.selectedDate
    signal editFinished
    text: calendarPicker.selectedDate.toLocaleString(Qt.locale(), dateFormat)
    bottomPadding: 0
    leftPadding: (labelPosition === labelLeft) ? label.width + labelSpacing : 0
    topPadding: (labelPosition === labelTop) ? label.height + labelSpacing : 0
    width: label.width

    onEditingFinished: {
        if (hasEdited) {
            hasEdited = false
            editFinished()
        }
    }

    onTextEdited: hasEdited = true

    Label {
        id: label
        height: parent.height
        text: labelText
        font: control.font
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }

    //指示器的绘制（上下箭头）
    Canvas {
        id: canvas
        width: 12
        height: 12
        x: control.width - width - 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        contextType: "2d"
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: popup.open()
        }

        Connections {
            target: mouse
            function onPressedChanged() {
                canvas.requestPaint()
            }
        }
        onPaint: {
            // 定义箭头路径
            var ctx = getContext("2d")
            ctx.beginPath()
            ctx.moveTo(0, 0) // 移动到起始点位置
            ctx.lineTo(width / 2, height) // 连接第三个点位置
            ctx.lineTo(width, 0) // 连接第二个点位置
            ctx.closePath() // 闭合路径
            //设置填充色
            ctx.fillStyle = mouse.pressed ? "#888888" : "#444444"
            // 设置边线颜色
            ctx.strokeStyle = mouse.pressed ? "#888888" : "#444444"
            // 设置边线宽度
            ctx.lineWidth = 2

            // 绘制箭头形状
            ctx.fill() // 填充箭头内部区域
            ctx.stroke() // 绘制箭头轮廓
        }
    }

    Popup {
        id: popup
        y: control.height
        implicitHeight: contentItem.implicitHeight
        padding: 0
        background: Rectangle {
            id: popupBak
            radius: 4
        }

        contentItem: CalendarPicker {
            id: calendarPicker
            clip: true
            radius: 4
            onClicked: {
                text = selectedDate.toLocaleString(Qt.locale(), dateFormat)
                editFinished()
                popup.close()
            }
        }
    }

    background: Rectangle {
        id: bak
        anchors.leftMargin: (labelPosition === labelLeft) ? label.width + labelSpacing : 0
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: control.activeFocus ? 2 : 1
        color: control.activeFocus ? accentColor : "#42000000"
        Behavior on height {
            NumberAnimation {
                duration: 200
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
    }
}
