import QtQuick
import QtQuick.Controls.Fusion
import Qt.labs.qmlmodels
import QmlPlugins

Rectangle {
    id: control
    implicitHeight: 300
    implicitWidth: 500
    border.width: 1
    radius: 8
    border.color: "#d1d1d1"
    color: "#00000000"

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
    property int rowHeight: 40
    property int verHeaderWidth: 40
    //列表头-横向的
    property int horHeaderHeight: 40
    property bool displayRowNo: true
    property bool calced: false
    property int firstVisibleColumn: 0
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

    property TableView view: TableView {}

    //表格内容（不包含表头）
    //tableview {}
    //横项表头
    Item {
        id: horHeader
        anchors {
            left: view.left
            right: view.right
            top: parent.top
            topMargin: parent.border.width
        }
        height: control.horHeaderHeight
        z: 2
        //暂存鼠标拖动的位置
        property int lastX: 0
        Row {
            id: horHeaderRow
            anchors.fill: parent
            leftPadding: -view.contentX
            clip: true
            spacing: 0

            Repeater {
                model: view.columns > 0 ? view.columns : 0

                Rectangle {
                    id: horHeaderItem
                    width: view["col" + String(index)]
                    height: control.horHeaderHeight
                    color: headerColor
                    gradient: headerUseGradient ? headerGradient : null
                    topLeftRadius: control.radius
                    visible: width > 0

                    Text {
                        anchors.centerIn: parent
                        text: qsTr(index < view.headerTitles.length ? view.headerTitles[index] : "")
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
                            if (horHeader.width === 0)
                                return;
                            if ((horHeaderItem.width - (horHeader.lastX - mouseX)) > 10) {
                                horHeaderItem.width -= (horHeader.lastX - mouseX);
                            } else {
                                horHeaderItem.width = 10;
                            }
                            horHeader.lastX = mouseX;
                            var key = "col" + String(index);
                            view[key] = (horHeaderItem.width - view.columnSpacing);
                            //刷新布局，这样宽度才会改变
                            horHeaderRow.forceLayout();
                            view.forceLayout();
                        }
                    }
                }
            }
        }
    }
    /*
    //竖向表头
    Column {
        id: verHeader
        anchors {
            top: view.top
            bottom: view.bottom
            right: view.left
        }
        topPadding: -view.contentY
        z: 2
        clip: true
        spacing: 0
        Repeater {
            id: rowHeader
            model: view.rows > 0 ? view.rows : 0
            Rectangle {
                width: control.verHeaderWidth
                height: view.rowHeight(index)
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
            visible: useCheckBox && (view.rows > 0)
            anchors.centerIn: parent
            onCheckedChanged: {
                for (var i = 0; i < view.rows; i++) {
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
    */
}
