import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    // 通过 TableView.view 附属性获取所在的 TableView
    property var tableView: TableView.view

    color: {
        if (root.tableView && row === root.tableView.currentRow)
            return "#1E90FF"
        if (root.tableView && root.tableView.alternatingRows && row % 2 !== 0)
            return Qt.darker("white", 1.1)
        return "white"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.tableView && root.tableView.selectRow)
                root.tableView.selectRow(row)
        }
    }

    // 底部网格线
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: "#d8d8d8"
    }
    // 右侧网格线
    Rectangle {
        anchors.right: parent.right
        height: parent.height
        width: 1
        color: "#d8d8d8"
    }
}
