import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

Item {
    id: root
    width: 800
    height: 500
    property bool autoDestroy: false
    property QtObject ownerLoader: null

    onVisibleChanged: {
        if (visible) {
            return
        }
        if (autoDestroy) {
            if (ownerLoader !== null) {
                ownerLoader.source = ""
            } else {
                destroy()
            }
        }
    }

    // 1. 原始数据模型
    ListModel {
        id: sourceModel
        ListElement {
            name: "张三"
            dept: "研发部"
            job: "工程师"
        }
        ListElement {
            name: "李四"
            dept: "市场部"
            job: "运营"
        }
        ListElement {
            name: "王五"
            dept: "研发部"
            job: "架构师"
        }
        ListElement {
            name: "赵六"
            dept: "人事部"
            job: "HR"
        }
        ListElement {
            name: "张七"
            dept: "财务部"
            job: "会计"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 筛选输入框
        TextField {
            id: searchInput
            Layout.fillWidth: true
            placeholderText: "输入姓名/部门/职位 筛选..."
        }

        // 自定义复杂表格（绑定过滤后的 filterModel）
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: sourceModel // 关键：绑定代理模型
            clip: true
            // 列宽绑定变量
            property real nameColWidth: 160
            property real deptColWidth: 180
            property real jobColWidth: 160
            property real statusColWidth: 120

            // 表头
            header: RowLayout {
                id: headerRow
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 1

                ResizeCell {
                    text: "姓名"
                    width: 160
                    onWidthChanged: nameColWidth = width
                }
                ResizeCell {
                    text: "部门"
                    width: 180
                    onWidthChanged: deptColWidth = width
                }
                ResizeCell {
                    text: "职位"
                    width: 160
                    onWidthChanged: jobColWidth = width
                }
            }

            // 表格行代理
            delegate: RowLayout {
                width: parent.width
                height: 36
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: index % 2 ? "#f5f5f5" : "#ffffff"
                    border.color: "#eee"
                }
                Text {
                    text: model.name
                    width: 120
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: model.dept
                    width: 180
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    text: model.job
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
