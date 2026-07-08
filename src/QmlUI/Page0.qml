import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root
    visible: true
    width: 400
    height: 300

    // 1. 模拟业务状态：当前页面是否有未保存的修改
    property bool hasUnsavedChanges: true

    ColumnLayout {
        anchors.fill: parent

        // 3. TabBar 核心拦截逻辑
        TabBar {
            id: tabBar
            property int pendingIndex: 0

            function jumpPage(jumped) {
                if (jumped)
                    pendingIndex = tabBar.currentIndex;
                else
                    tabBar.currentIndex = pendingIndex;
            }

            Layout.fillWidth: true

            Repeater {
                model: ["首页", "设置", "关于"]
                TabButton {
                    text: modelData

                    onClicked: {
                        // 如果存在未保存的修改，则拦截并弹窗
                        if (root.hasUnsavedChanges) {
                            confirmDialog.open();
                        }
                    }
                }
            }
        }

        // 4. 内容区域
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.pendingIndex

            // 首页：提供一个按钮来模拟“保存成功”，从而关闭拦截
            Rectangle {
                color: "#E3F2FD"
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text {
                        text: "这是首页 (有未保存的修改)"
                    }
                    Button {
                        text: "点击模拟保存成功"
                        onClicked: root.hasUnsavedChanges = false
                    }
                }
            }
            Rectangle {
                color: "#FFF3E0"
                Text {
                    anchors.centerIn: parent
                    text: "这是设置页"
                }
            }
            Rectangle {
                color: "#E8F5E9"
                Text {
                    anchors.centerIn: parent
                    text: "这是关于页"
                }
            }
        }
    }

    // 5. 确认对话框
    MessageDialog {
        id: confirmDialog
        title: "切换确认"
        text: "当前页面有未保存的修改，确定要放弃修改并切换吗？"
        buttons: MessageDialog.Yes | MessageDialog.No

        // 确认切换
        onAccepted: {
            tabBar.jumpPage(true);
        }

        // 取消切换：什么都不做，tabBar.currentIndex 保持不变
        onRejected: {
            tabBar.jumpPage(false);
        }
    }
}
