import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QmlPlugins

HulaDialog {
    id: root
    property bool isAdmin: false
    width: 540
    height: isAdmin ? 480 : 360
    x: (mainForm.width - width) / 2
    y: (mainForm.height - height) / 2
    formTitle: qsTr("User.Title") + Translater.change
    property int dictType: 0

    onShowForm: {
        loadData()
    }

    GridLayout {
        id: editBar
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        columns: 2
        rowSpacing: 12
        columnSpacing: 12
        property int lblWidth: 88
        property int txtWidth: 178
        property int lblFontSize: 16
        property int txtFontSize: 16

        Label {
            id: lblType
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Type") + Translater.change
            font.pixelSize: parent.lblFontSize
        }
        ComboBox {
            id: cmbType
            property string fieldName: "Type"
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 32
            font.pixelSize: parent.txtFontSize
            currentIndex: -1
            selectTextByMouse: true
            editable: false
            enabled: isAdmin
            property string admin: qsTr("User.Admin") + Translater.change
            property string normal: qsTr("User.Normal") + Translater.change
            model: [normal, admin]
        }

        Label {
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Name") + Translater.change
            font.pixelSize: parent.lblFontSize
        }
        TextField {
            id: edtName
            property string fieldName: "Name"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            text: ""
            font.pixelSize: parent.txtFontSize
        }

        Label {
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Account") + Translater.change
            font.pixelSize: parent.lblFontSize
        }
        TextField {
            id: edtAccount
            property string fieldName: "Account"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            text: ""
            font.pixelSize: parent.txtFontSize
        }

        Label {
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.NewPassword") + Translater.change
            font.pixelSize: parent.lblFontSize
        }
        TextField {
            id: edtNewPassword
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            echoMode: TextInput.Password
            text: ""
            font.pixelSize: parent.txtFontSize
        }

        Label {
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            property string title: (!isAdmin) ? "User.OldPassword" : (btnAdd.enabled ? "User.OldPassword" : "User.RepeatPassword")
            text: qsTr(title) + Translater.change
            font.pixelSize: parent.lblFontSize
        }
        TextField {
            id: edtOldPassword
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 32
            verticalAlignment: Text.AlignVCenter
            echoMode: TextInput.Password
            text: ""
            font.pixelSize: parent.txtFontSize
        }
    }

    HulaTableView {
        id: tvData
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: editBar.bottom
        anchors.bottom: btnBar.top
        anchors.margins: 12
        visible: isAdmin
        columnsWidth: [0, 220, 260]
        headerTitles: ["Id", "User.Account", "User.Name"]
        model: TableModel {
            TableModelColumn {
                id: idColumn
                display: "Id"
            }
            TableModelColumn {
                id: accountColumn
                display: "Account"
            }
            TableModelColumn {
                id: nameColumn
                display: "Name"
            }
        }
        onCurrentRowChanged: {
            if (currentRow < 0)
                return
            if (isAdmin)
                btnAdd.enabled = true
            var data = tvData.model.getRow(currentRow)
            viewData(data)
        }
    }

    Row {
        id: btnBar
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 12
        height: 54
        spacing: 8
        RoundButton {
            id: btnAdd
            radius: 4
            font.pixelSize: editBar.lblFontSize
            text: qsTr("User.Add") + Translater.change
            Material.background: "white"
            Material.foreground: "#535353"
            width: parent.width / 4 - 8
            height: 46
            enabled: isAdmin
            onClicked: {
                enabled = false
                btnSave.enabled = true
                tvData.selectionModel.clear()
                clearEditor()
            }
        }
        RoundButton {
            id: btnSave
            radius: 4
            font.pixelSize: editBar.lblFontSize
            text: qsTr("User.Save") + Translater.change
            Material.background: "white"
            Material.foreground: "#535353"
            width: parent.width / 4 - 8
            height: 46
            onClicked: {
                saveData()
            }
        }

        RoundButton {
            radius: 4
            font.pixelSize: editBar.lblFontSize
            text: qsTr("User.Delete") + Translater.change
            Material.background: "white"
            Material.foreground: "#535353"
            width: parent.width / 4 - 8
            height: 46
            enabled: isAdmin
            onClicked: {
                btnAdd.enabled = true
                deleteData()
            }
        }
        RoundButton {
            radius: 4
            font.pixelSize: editBar.lblFontSize
            text: qsTr("User.Back") + Translater.change
            Material.background: "white"
            Material.foreground: "#535353"
            width: parent.width / 4 - 8
            height: 46
            onClicked: {
                root.close()
            }
        }
    }

    function loadData() {
        var currUserRow = -1
        clearEditor()
        tvData.model.clear()
        var dataList = userInfo.getDatas()
        for (var i = 0; i < dataList.length; ++i) {
            tvData.model.appendRow(dataList[i])
            if (dataList[i]["Account"] === Configer.userAccount()) {

                currUserRow = i
                if (dataList[i]["Type"] === 1)
                    isAdmin = true
                else
                    isAdmin = false
            }
        }

        if (currUserRow >= 0) {
            tvData.selectionModel.clear()
            tvData.selectRow(currUserRow)
            viewData(tvData.model.getRow(currUserRow))
        }
    }

    function viewData(data) {
        cmbType.currentIndex = data["Type"]
        edtName.text = data[nameColumn.display]
        edtAccount.text = data[accountColumn.display]
        edtNewPassword.text = ""
        edtOldPassword.text = ""
        if (btnAdd.enabled) {
            if (data["Account"] !== Configer.userAccount())
                btnSave.enabled = false
            else
                btnSave.enabled = true
        }
    }

    function clearEditor() {
        edtName.text = ""
        edtAccount.text = ""
        edtNewPassword.text = ""
        edtOldPassword.text = ""
    }

    function saveData() {
        if (cmbType.currentIndex < 0) {
            snackMessage("User.SelectType")
            return false
        }

        if (edtName.text.trim() === "") {
            snackMessage("User.NameDontNull")
            return false
        }

        if (edtAccount.text.trim() === "") {
            snackMessage("User.AccountDontNull")
            return false
        }

        if (edtOldPassword.text.trim() === "") {
            snackMessage("User.PasswordDontNull")
            return false
        }
        var data = {}
        data[nameColumn.display] = edtName.text.trim()
        data[accountColumn.display] = edtAccount.text.trim()
        data["Type"] = cmbType.currentIndex
        if (edtNewPassword.text.trim() !== "") {
            data["Password"] = edtNewPassword.text.trim()
        }

        if (btnAdd.enabled) {
            if (tvData.currentRow < 0) {
                snackMessage("NullRow")
                return false
            }
            if (edtNewPassword.text.trim() !== "") {
                let ret = userInfo.checkPassword(userInfo.currUserAccount(),
                                                    edtOldPassword.text.trim())
                if (ret !== 0) {
                    snackMessage("User.PasswordValidateError")
                    return false
                }
            }

            var currData = tvData.model.getRow(tvData.currentRow)
            let ret = userInfo.accountExisted(edtAccount.text.trim(),
                                           String(currData["Id"]))
            if (ret !== 0) {
                snackMessage("User.AccountExisted")
                return
            }

            data["Id"] = currData["Id"]
            ret = userInfo.updateData(data)
            if (ret !== 0) {
                snackMessage("UpdateInvalid")
                return false
            }
            tvData.model.setRow(tvData.currentRow, data)
            snackMessage("UpdateValid")
        } else {
            if (edtNewPassword.text.trim() !== "") {
                if (edtOldPassword.text.trim() === "") {
                    snackMessage("User.RepeatInputPassword")
                    return false
                }
                if (edtNewPassword.text.trim() !== edtOldPassword.text.trim()) {
                    snackMessage("User.RepeatPasswordError")
                    return false
                }
            }
            let ret = userInfo.accountExisted(edtAccount.text.trim())

            if (ret !== 0) {
                snackMessage("User.AccountExisted")
                return
            }

            ret = userInfo.appendData(data)
            if (ret === 0) {
                snackMessage("AppendInvalid")
                return false
            }
            data["Id"] = ret
            tvData.model.appendRow(data)
            if (isAdmin)
                btnAdd.enabled = true
            snackMessage("AppendValid")
        }

        return true
    }

    function deleteData() {
        btnAdd.enabled = true
        if (tvData.currentRow < 0) {
            snackMessage("NullRow")
            return
        }
        var funcDelete = function () {
            var data = tvData.model.getRow(tvData.currentRow)
            var ret = userInfo.deleteData(String(data["Id"]))
            if (ret === 0) {
                tvData.model.removeRow(tvData.currentRow, 1)
                clearEditor()
                snackMessage("DeleteValid")
                return
            }
            snackMessage("DeleteInvalid")
        }

        openDialogConfirm("ConfirmDelete", funcDelete)
    }
}
