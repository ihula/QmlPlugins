import QtQuick
import QtQuick.Controls

Rectangle {
    color: "#E3F2FD"
    // 接收参数
    property string userName: "未知"
    property int userAge: 0
    radius: 8

    Component.onDestruction: {
        console.log("✅ 页面1 已销毁")
    }

    Column {
        id: col
        // 测试状态保留
        property int count: 0
        anchors.centerIn: parent
        spacing: 20

        Text {
            text: "页面 1（带缓存）"
            font.pixelSize: 22
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "接收参数：\n姓名：" + userName + "\n年龄：" + userAge
            font.pixelSize: 18
            anchors.horizontalCenter: parent.horizontalCenter
        }


        Button {
            text: "计数：" + col.count
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: col.count++
        }
    }
}
