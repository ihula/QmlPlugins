import QtQuick
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import HulaPlugins

HulaDialog {
    id: root
    width: 960
    height: 660
    title: qsTr("MessageCenter.Title")

    onVisibleChanged: {
        if (visible) {
            loadDatas();
        }
    }

    Rectangle {
        id: btnBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        radius: 8
        border.width: 1
        border.color: Themer.borderColor
        color: "#F1F1F1"
        height: 56
        Row {
            id: buttonBar
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            height: 36
            spacing: 18
            LabelDateEdit {
                id: dateText
                anchors.verticalCenter: parent.verticalCenter
                width: 200
                labelText: "选择日期"
                placeholderText: "请选择"
                onEditFinished: loadDatas()
            }

            NormalButton {
                id: btnDelete
                implicitWidth: 100
                text: qsTr("Delete")
                onClicked: deleteData()
            }

            NormalButton {
                id: btnDeleteAll
                implicitWidth: 100
                text: qsTr("DeleteAll")
                onClicked: deleteAllData()
            }

            NormalButton {
                implicitWidth: 100
                text: qsTr("Close")
                onClicked: hide()
            }
        }
    }

    Rectangle {
        anchors.top: btnBar.bottom
        anchors.bottom: errorInfoBorder.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        radius: 4
        border.width: 1
        border.color: Themer.barColor
        Label {
            id: tableTitle
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 1
            height: 32
            text: "错误信息列表"
            color: "white"
            leftPadding: 12
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                color: Themer.barColor
            }
        }

        HulaTableView {
            id: tableview
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tableTitle.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 1
            anchors.bottomMargin: 12
            alternatingRows: false
            color: "white"
            headerColor: "white"
            headerGradient: Themer.viewGradient
            editTriggers: TableView.NoEditTriggers
            columnBorderWidth: 0
            border.width: 0
            verHeaderWidth: 0
            useCheckBox: false
            columnsWidth: [0, 100, 420, 100, 200]
            headerTitles: ["Id", "MessageCenter.ErrorNum", "MessageCenter.ErrorInfo", "MessageCenter.UserName", "MessageCenter.LogTime"]

            model: TableModel {
                TableModelColumn {
                    id: colId
                    display: "Id"
                }
                TableModelColumn {
                    id: colErrorNum
                    display: "StatusCode"
                }
                TableModelColumn {
                    id: colErrorInfo
                    display: "ErrorInfo"
                }
                TableModelColumn {
                    id: colUserName
                    display: "UserName"
                }
                TableModelColumn {
                    id: colLogTime
                    display: "LogTime"
                }
            }

            onCurrentRowChanged: {
                if (currentRow < 0)
                    return;
                var data = tableview.model.getRow(currentRow);
                viewData(data);
            }
        }
    }

    Rectangle {
        id: errorInfoBorder
        anchors.bottom: edtDetailBorder.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        border.width: 1
        border.color: Themer.barColor
        implicitHeight: 100
        radius: 4
        Label {
            id: infoTitle
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 1
            height: 32
            text: "错误信息"
            color: "white"
            leftPadding: 12
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                color: Themer.barColor
            }
        }
        TextArea {
            id: edtErrorInfo
            anchors.fill: parent
            anchors.margins: 1
            anchors.topMargin: infoTitle.height
            readOnly: true
            wrapMode: TextEdit.WordWrap
            text: ""
        }
    }

    Rectangle {
        id: edtDetailBorder
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        implicitHeight: 160
        border.width: 1
        border.color: Themer.barColor
        radius: 4
        Label {
            id: detailTitle
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 1
            height: 32
            text: "解决方法"
            leftPadding: 12
            color: "white"
            verticalAlignment: Text.AlignVCenter
            background: Rectangle {
                color: Themer.barColor
            }
        }
        TextArea {
            id: edtDetail
            anchors.fill: parent
            anchors.margins: 1
            anchors.topMargin: detailTitle.height
            readOnly: true
            wrapMode: TextEdit.WordWrap
        }
    }

    function loadDatas() {
        tableview.model.clear();
        var strDate = dateText.date.toLocaleString(Qt.locale(), "yyyyMMdd");
        var dataList = MessageCenter.getDatas(strDate);
        for (var i = 0; i < dataList.length; ++i) {
            tableview.model.appendRow(dataList[i]);
        }

        if (dataList.length > 0) {
            tableview.selectionModel.clear();
            if (tableview.rows > 0)
                tableview.selectionModel.select(0);
            viewData(tableview.model.getRow(0));
        } else {
            clearEditor();
        }
    }

    function viewData(data) {
        edtErrorInfo.text = data[colErrorInfo.display];
        edtDetail.text = JSON.stringify(data);
    // if (tableview.currentRow > -1)
    //     console.log(1, tableview.checkBox(tableview.currentRow).checked)
    }

    function clearEditor() {
        edtErrorInfo.text = "";
        edtDetail.text = "";
    }

    function deleteData() {
        if (tableview.currentRow < 0) {
            snackMessage("NullRow");
            return;
        }
        var funcDelete = function () {
            var data = tableview.model.getRow(tableview.currentRow);
            var ret = messageCenter.deleteData(data.Id);
            if (ret === 0) {
                tableview.model.removeRow(tableview.currentRow, 1);
                clearEditor();
                snackMessage("DeleteValid");
                return;
            }
            snackMessage("DeleteInvalid");
        };

        openDialogConfirm("ConfirmDelete", funcDelete);
    }

    function deleteAllData() {
        var funcDelete = function () {
            var ret = MessageCenter.deleteAllData();
            if (ret === 0) {
                tableview.model.clear();
                clearEditor();
                snackMessage("DeleteValid");
                return;
            }
            snackMessage("DeleteInvalid");
        };

        openDialogConfirm("ConfirmDelete", funcDelete);
    }
}
