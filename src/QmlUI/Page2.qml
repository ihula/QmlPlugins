import QtQuick
import QtQuick.Controls
import Qt.labs.qmlmodels
import QmlPlugins
import "../HulaUI"

Rectangle {
    color: Themer.theme.workFormColor
    // 接收参数
    property string content: "无内容"
    radius: 8

    Component.onDestruction: {
        console.log("✅ 页面2 已销毁");
    }

    HulaTableHeader {
        id: control
        anchors.fill: parent
        view: tableview

        //表格内容（不包含表头）
        TableView {
            id: tableview
            anchors.fill: parent
            //anchors.rightMargin: control.border.width
            //anchors.leftMargin: control.verHeaderWidth + control.border.width
            anchors.topMargin: control.horHeaderHeight + control.border.width
            // 多1个高度,防止最后一行边框与外边框相连
            //anchors.bottomMargin: control.border.width * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            columnSpacing: 0
            rowSpacing: 0
            ScrollBar.vertical: ScrollBar {}

            ScrollBar.horizontal: ScrollBar {}

            property var headerTitles: ["Id", "Home.TestId", "Home.Name", "Home.Sex", "Home.Age", "Home.MRN"]
            property var columnsWidth: [100, 100, 100, 100, 100, 100, 100]
            property var fieldNames: ["Id", "TestId", "Name", "Sex", "Age", "MRN"]
            rowHeightProvider: function (row) {
                return control.rowHeight;
            }
            //此属性可以保存一个函数，该函数返回模型中每个列的列宽
            columnWidthProvider: function (column) {
                // if (!calced) {
                //     calced = true;
                //     //calcFirstLastColumn()
                // }

                if (column < columnsWidth.length)
                    return columnsWidth[column];
                else
                    return 60;
            }
            model: TableModel {
                TableModelColumn {
                    display: tableview.fieldNames[0]
                }
                TableModelColumn {
                    display: tableview.fieldNames[1]
                }
                // TableModelColumn {
                //     display: tableview.fieldNames[2]
                // }
                // TableModelColumn {
                //     display: tableview.fieldNames[3]
                // }
                // TableModelColumn {
                //     display: tableview.fieldNames[4]
                // }
                // TableModelColumn {
                //     display: tableview.fieldNames[5]
                // }
                rows: [
                    {
                        "Id": "cat",
                        "TestId": "black"
                    },
                    {
                        "Id": "dog",
                        "TestId": "brown"
                    },
                    {
                        "Id": "bird",
                        "TestId": "white"
                    }
                ]
            }

            selectionModel: ItemSelectionModel {
                id: sltModel
                model: tableview.model
            }

            delegate: Rectangle {
                implicitWidth: tableview.columnsWidth[index]
                //implicitHeight: 50
                clip: true
                border.width: 1

                Text {
                    text: display
                    anchors.fill: parent
                    color: "black"
                }
            }
            /*
            delegate: Rectangle {
                property alias checkBox: cbtn
                property alias button: btn
                property alias itemTxt: txt
                required property bool editing
                required property bool selected
                required property bool current

                clip: true
                color: (row === tableview.currentRow) ? control.highlightColor : (control.alternatingRows && row % 2 !== 0) ? control.alternatingRow : control.rowColor

                // MouseArea {
                //     anchors.fill: parent
                //     //propagateComposedEvents: true
                //     onClicked: mouse => {
                //         mouse.accepted = false;
                //         selectRow(row);
                //         cellClicked(row, column);
                //     }
                //     onDoubleClicked: mouse => {
                //         cellDoubleClicked(row, column);
                //         mouse.accepted = false;
                //     }
                // }
                Rectangle {
                    width: control.columnBorderWidth
                    height: parent.height
                    anchors.right: parent.right
                    color: control.itemBorderColor
                }
                Rectangle {
                    width: parent.width
                    height: control.rowBorderWidth
                    anchors.bottom: parent.bottom
                    color: control.itemBorderColor
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
            */
        }
    }
}
