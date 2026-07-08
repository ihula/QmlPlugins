import QtQuick
import QtQuick.Controls.Fusion
import Qt.labs.qmlmodels

TableView {
    id: tableview
    property QtObject horHeader: null
    property var headerTitles: []
    // required property int column0Width

    function selectRow(row) {
        var newIndex = tableview.index(row, 0);
        tableview.selectionModel.setCurrentIndex(newIndex, ItemSelectionModel.Select | ItemSelectionModel.Rows);
    }

    anchors.fill: horHeader ? parent : null
    anchors.leftMargin: horHeader ? tableheader.border.width : 0
    anchors.topMargin: horHeader ? (tableheader.horHeaderHeight + tableheader.border.width) : 0
    clip: true
    columnSpacing: 0
    rowSpacing: 0
    selectionMode: TableView.SingleSelection
    selectionBehavior: TableView.SelectRows

    ScrollBar.vertical: CustomScrollBar {
        visible: tableview.contentHeight > tableview.height
    }
    ScrollBar.horizontal: CustomScrollBar {
        visible: tableview.contentWidth > tableview.width
    }

    rowHeightProvider: function (row) {
        return tableheader.rowHeight;
    }
    //此属性可以保存一个函数，该函数返回模型中每个列的列宽
    columnWidthProvider: function (column) {
        var key = "column" + String(column) + "Width";
        if (tableview[key] !== undefined) {
            return tableview[key];
        } else {
            return 60;
        }
    }

    selectionModel: ItemSelectionModel {
        id: sltModel
        model: tableview.model
    }

    // 默认 delegate，可通过外部覆写 CellChooser 实现自定义单元格
    delegate: CellRect {
        Text {
            anchors.fill: parent
            anchors.margins: 2
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: modelData || ""
            elide: Text.ElideRight
        }
    }
}
