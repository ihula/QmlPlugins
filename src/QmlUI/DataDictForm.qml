import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.Fusion as Fusion
import Qt.labs.qmlmodels
import QtQuick.Layouts
import "../HulaUI"
import DataDict 1.0
import QmlUI 1.0

HulaDialog {
    id: root
    width: 360
    height: 460
    property int dictType: 0
    formTitle: qsTr("DataDict.Title") + translater.change
    signal selected(int dictType, string text)

    onShowForm: {
        loadDatas()
    }

    ColumnLayout {
        id: edtBar
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        height: areaInfo.visible ? 120 : 64
        spacing: 18
        Label {
            id: lblInfo
            Layout.fillHeight: true
            width: 80
            verticalAlignment: Text.AlignVCenter
            text: qsTr("DataDict.AddNew") + translater.change
        }
        TextField {
            id: edtInfo
            visible: !areaInfo.visible
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Fusion.ScrollView {
            clip: true
            visible: (DictType.Advice === root.dictType)
            ScrollBar.vertical.interactive: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: areaInfo.paintedWidth
            contentHeight: areaInfo.paintedHeight
            topPadding: -9
            TextArea {
                id: areaInfo
                topPadding: 16
                clip: true
                visible: (DictType.Advice === root.dictType)
                wrapMode: TextArea.WordWrap
            }
        }
    }

    RowLayout {
        id: buttonBar
        anchors.top: edtBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        height: 46
        spacing: 18

        RoundButton {
            id: btnAdd
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: qsTr("DataDict.Add") + translater.change
            onClicked: appendData()
        }

        RoundButton {
            id: btnChange
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: qsTr("DataDict.Save") + translater.change
            onClicked: updateData()
        }

        RoundButton {
            id: btnDelete
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: qsTr("DataDict.Delete") + translater.change
            onClicked: deleteData()
        }
    }

    HulaTableView {
        id: tableview
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: buttonBar.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 12
        alternatingRows: false
        color: "white"
        headerColor: "white"
        headerGradient: HulaTheme.viewGradient
        editTriggers: TableView.NoEditTriggers
        columnBorderWidth: 0
        border.width: 1
        horHeaderHeight: 0
        verHeaderWidth: 0
        useCheckBox: false
        columnsWidth: [0, 340]
        headerTitles: ["", "DataDict.Value"]
        model: TableModel {
            TableModelColumn {
                id: colId
                display: "Id"
            }
            TableModelColumn {
                id: colInfo
                display: "Value"
            }
        }

        onCurrentRowChanged: {
            if (currentRow < 0)
                return
            var data = tableview.model.getRow(currentRow)
            viewData(data)
        }

        onCellDoubleClicked: {
            if ((root.dictType !== DictType.Advice)
                    && (root.dictType !== DictType.Parse))
                return

            var data = tableview.model.getRow(currentRow)
            selected(root.dictType, data[colInfo.display])
        }
    }

    function loadDatas() {
        tableview.model.clear()
        var dataList = dataDict.getDatas(dictType)
        for (var i = 0; i < dataList.length; ++i) {
            tableview.model.appendRow(dataList[i])
        }

        if (dataList.length > 0) {
            tableview.selectionModel.clear()
            if (tableview.rows > 0)
                tableview.selectionModel.select(0)
            viewData(tableview.model.getRow(0))
        } else {
            clearEditor()
        }
    }

    function viewData(data) {
        if (edtInfo.visible)
            edtInfo.text = data[colInfo.display]
        else
            areaInfo.text = data[colInfo.display]
    }

    function clearEditor() {
        edtInfo.text = ""
        areaInfo.text = ""
    }

    function appendData() {
        var data = {}
        if (edtInfo.visible)
            data[colInfo.display] = edtInfo.text.trim()
        else
            data[colInfo.display] = areaInfo.text.trim()
        data["Type"] = root.dictType
        var ret = dataDict.appendData(data)
        if (ret === 0) {
            snackMessage("AppendInvalid")
            edtInfo.focus = true
            return
        }
        data["Id"] = ret
        tableview.model.appendRow(data)
        snackMessage("AppendValid")
    }

    function updateData() {
        var data = tableview.model.getRow(tableview.currentRow)
        if (edtInfo.visible)
            data[colInfo.display] = edtInfo.text.trim()
        else
            data[colInfo.display] = areaInfo.text.trim()
        var ret = dataDict.updateData(data)
        if (ret !== 0) {
            snackMessage("UpdateInvalid")
            edtInfo.focus = true
            return
        }
        tableview.model.setRow(tableview.currentRow, data)
        snackMessage("UpdateValid")
    }

    function deleteData() {
        if (tableview.currentRow < 0) {
            snackMessage("NullRow")
            return
        }
        var funcDelete = function () {
            var data = tableview.model.getRow(tableview.currentRow)
            var ret = dataDict.deleteData(data.Id)
            if (ret === 0) {
                tableview.model.removeRow(tableview.currentRow, 1)
                clearEditor()
                snackMessage("DeleteValid")
                return
            }
            snackMessage("DeleteInvalid")
        }

        openDialogConfirm("ConfirmDelete", funcDelete)
    }
}
