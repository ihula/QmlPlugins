import QtQuick
import QtQuick.Controls.Fusion
import Qt.labs.qmlmodels
import QmlPlugins

Rectangle {
    id: control
    implicitHeight: 300
    implicitWidth: 500
    border.width: 1
    radius: 0
    border.color: "#d1d1d1"
    color: "#00000000"

    property var colModel: [][tableview.columns]
    property var buttonColumns: []
    property alias rows: tableview.rows
    property alias columns: tableview.columns
    property alias view: tableview
    property alias selectionMode: tableview.selectionMode
    property bool useCellCheckbox: false
    property bool useCellButton: false
    property bool useCheckBox: false
    property bool useSelection: true
    property int rowBorderWidth: 1
    property int columnBorderWidth: 1
    property color itemBorderColor: "#DCDCDC"
    property color highlightColor: useSelection ? "#1E90FF" : "transparent"
    property color rowColor: "white"
    property color alternatingRow: Qt.darker("white", 1.1)
    property color headerColor: "#F5F5F5"
    //行表头-竖向的
    property int rowHeight: 30
    property int verHeaderWidth: 30
    //列表头-横向的
    property int horHeaderHeight: 30
    //列宽
    property variant columnsWidth: []
    property variant headerTitles: []
    property alias model: tableview.model
    property alias selectionModel: tableview.selectionModel
    property alias editTriggers: tableview.editTriggers
    property alias alternatingRows: tableview.alternatingRows
    property alias currentRow: tableview.currentRow
    property bool displayRowNo: true
    property bool calced: false
    property int firstVisibleColumn: 0
    property int lastVisibleColumn: tableview.rows
    property bool headerUseGradient: true
    property Gradient headerGradient: Gradient {
        GradientStop {
            position: 0.0
            color: "#F5F5F5"
        }
        GradientStop {
            position: 1.0
            color: "#ECECEC"
        }
    }

    signal cellClicked(var row, var column)
    signal cellDoubleClicked(var row, var column)
    signal btnClicked(var sender)

    signal rowCountChanged
    signal itemReused

    function itemAtIndex(row, column) {
        return tableview.itemAtIndex(tableview.index(row, column));
    }

    //表格内容（不包含表头）
    TableView {
        id: tableview
        anchors {
            fill: parent
            rightMargin: control.border.width
            leftMargin: control.verHeaderWidth + control.border.width
            topMargin: control.horHeaderHeight + control.border.width
            // 多1个高度,防止最后一行边框与外边框相连
            bottomMargin: control.border.width * 2
        }

        //selectionBehavior: TableView.SelectColumns
        //editTriggers: TableView.AnyKeyPressed | TableView.DoubleTapped
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        columnSpacing: 0
        rowSpacing: 0
        //selectionBehavior: TableView.SelectRows
        //selectionMode: TableView.ExtendedSelection
        //reuseItems: false
        onTopRowChanged: itemReused()

        rowHeightProvider: function (row) {
            return control.rowHeight;
        }
        //此属性可以保存一个函数，该函数返回模型中每个列的列宽
        columnWidthProvider: function (column) {
            if (!calced) {
                calced = true;
                calcFirstLastColumn();
            }

            if (column < control.columnsWidth.length)
                return control.columnsWidth[column];
            else
                return 60;
        }

        ScrollBar.vertical: ScrollBar {}

        ScrollBar.horizontal: ScrollBar {}

        selectionModel: ItemSelectionModel {
            id: sltModel
            model: tableview.model
        }

        delegate: Rectangle {
            property alias checkBox: cbtn
            property alias button: btn
            property alias itemTxt: txt
            required property bool editing
            required property bool selected
            required property bool current

            clip: true
            color: (row === tableview.currentRow) ? highlightColor : (alternatingRows && row % 2 !== 0) ? alternatingRow : rowColor

            MouseArea {
                anchors.fill: parent
                //propagateComposedEvents: true
                onClicked: mouse => {
                    mouse.accepted = false;
                    selectRow(row);
                    cellClicked(row, column);
                }
                onDoubleClicked: mouse => {
                    cellDoubleClicked(row, column);
                    mouse.accepted = false;
                }
            }
            Rectangle {
                width: columnBorderWidth
                height: parent.height
                anchors.right: parent.right
                color: itemBorderColor
            }
            Rectangle {
                width: parent.width
                height: rowBorderWidth
                anchors.bottom: parent.bottom
                color: itemBorderColor
            }
            CheckBox {
                id: cbtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: editing ? false : control.useCellCheckbox
            }

            Rectangle {
                id: btn
                anchors.left: parent.left
                anchors.leftMargin: (cbtn.visible ? cbtn.width : 0) + 4
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height - 8
                width: height
                visible: editing ? false : control.useCellButton
                color: (typeof display !== "undefined") ? display : "transparent"
                property string str: String(row) + String(column)
            }

            Text {
                id: txt
                anchors.fill: parent
                anchors.margins: 2
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                //获取单元格对应的值
                text: (typeof display !== "undefined") ? display : ""
                elide: Text.ElideRight
            }
            TableView.editDelegate: TextField {
                visible: txt.visible
                anchors.fill: parent
                anchors.margins: 2
                text: (typeof display !== "undefined") ? display : ""
                horizontalAlignment: TextInput.AlignLeft
                verticalAlignment: TextInput.AlignVCenter
                Component.onCompleted: selectAll()

                TableView.onCommit: {
                    display = text;
                    //model.edit = text
                    // 'display = text' is short-hand for:
                    //let index = TableView.view.index(row, column)
                    //TableView.view.model.setData(index, Qt.EditRole, text)
                }
            }
        }
    }

    //横项表头
    Item {
        id: horHeader
        anchors {
            left: tableview.left
            right: tableview.right
            bottom: tableview.top
        }
        height: control.horHeaderHeight
        z: 2
        //暂存鼠标拖动的位置
        property int lastX: 0
        Row {
            id: horHeaderRow
            anchors.fill: parent
            leftPadding: -tableview.contentX
            clip: true
            spacing: 0

            Repeater {
                model: tableview.columns > 0 ? tableview.columns : 0

                Rectangle {
                    id: horHeaderItem
                    width: index < columnsWidth.length ? columnsWidth[index] : 60
                    height: control.horHeaderHeight
                    color: headerColor
                    gradient: headerUseGradient ? headerGradient : null

                    Text {
                        anchors.centerIn: parent
                        text: qsTr(index < headerTitles.length ? headerTitles[index] : "") + Translater.change
                        //text: tablemodel.headerData(index, Qt.Horizontal)
                    }

                    Rectangle {
                        width: columnBorderWidth
                        height: parent.height
                        anchors.right: parent.right
                        color: itemBorderColor
                    }
                    Rectangle {
                        width: parent.width
                        height: rowBorderWidth
                        anchors.bottom: parent.bottom
                        color: itemBorderColor
                    }
                    MouseArea {
                        width: 3
                        height: parent.height
                        anchors.right: parent.right
                        cursorShape: Qt.SplitHCursor
                        onPressed: horHeader.lastX = mouseX
                        onPositionChanged: {
                            if ((horHeaderItem.width - (horHeader.lastX - mouseX)) > 10) {
                                horHeaderItem.width -= (horHeader.lastX - mouseX);
                            } else {
                                horHeaderItem.width = 10;
                            }
                            horHeader.lastX = mouseX;
                            control.columnsWidth[index] = (horHeaderItem.width - tableview.columnSpacing);
                            //刷新布局，这样宽度才会改变
                            horHeaderRow.forceLayout();
                            tableview.forceLayout();
                        }
                    }
                }
            }
        }
    }

    //竖向表头
    Column {
        id: verHeader
        anchors {
            top: tableview.top
            bottom: tableview.bottom
            right: tableview.left
        }
        topPadding: -tableview.contentY
        z: 2
        clip: true
        spacing: 0
        Repeater {
            id: rowHeader
            model: tableview.rows > 0 ? tableview.rows : 0
            Rectangle {
                width: control.verHeaderWidth
                height: tableview.rowHeightProvider(index)
                color: headerColor
                gradient: headerUseGradient ? headerGradient : null
                property alias checkbox: rowCheckbox
                Text {
                    anchors.centerIn: parent
                    visible: !useCheckBox
                    text: String(index + 1)
                    //text: tablemodel.headerData(index, Qt.Vertical)
                }
                CheckBox {
                    id: rowCheckbox
                    anchors.centerIn: parent
                    visible: useCheckBox
                }
                Rectangle {
                    width: columnBorderWidth
                    height: parent.height
                    anchors.right: parent.right
                    color: itemBorderColor
                }
                Rectangle {
                    width: parent.width
                    height: rowBorderWidth
                    anchors.bottom: parent.bottom
                    color: itemBorderColor
                }
            }
        }
    }

    Rectangle {
        anchors.right: horHeader.left
        anchors.top: horHeader.top
        height: horHeader.height
        width: verHeaderWidth
        color: headerColor
        gradient: headerUseGradient ? headerGradient : null
        visible: (verHeaderWidth !== 0) && (horHeaderHeight !== 0)
        CheckBox {
            id: ckbAll
            visible: useCheckBox && (tableview.rows > 0)
            anchors.centerIn: parent
            onCheckedChanged: {
                for (var i = 0; i < tableview.rows; i++) {
                    checkBoxAt(i).checked = checked;
                }
            }
        }

        Rectangle {
            width: parent.width
            height: rowBorderWidth
            anchors.bottom: parent.bottom
            color: itemBorderColor
        }
        Rectangle {
            width: columnBorderWidth
            height: parent.height
            anchors.right: parent.right
            color: itemBorderColor
        }
    }

    function calcFirstLastColumn() {
        for (var i = 0; i < columnsWidth.length; i++) {
            if (columnsWidth[i] > 0) {
                firstVisibleColumn = i;
                break;
            }
        }
        for (i = columnsWidth.length - 1; i > -1; i--) {
            if (columnsWidth[i] > 0) {
                lastVisibleColumn = i;
                break;
            }
        }
    }

    function getColumnWidth(column) {
    }

    function checkBoxAt(index) {
        return rowHeader.itemAt(index).checkbox;
    }

    function uncheckAll() {
        ckbAll.checked = false;
    }

    Timer {
        id: timer
        interval: 300
        running: false
        property int row: -1
        onTriggered: {
            if (row === -1)
                stop();

            if (tableview.model.rowCount !== tableview.rows) {
                restart();
                return;
            }
            selectRow(row);
            row = -1;
            stop();
        }
    }

    function selectRow(row) {
        if (tableview.model.rowCount !== tableview.rows) {
            timer.row = row;
            timer.start();
            return;
        }

        var index = tableview.index(row, 0);
        tableview.selectionModel.setCurrentIndex(index, ItemSelectionModel.Select | ItemSelectionModel.Rows);
    }
}
