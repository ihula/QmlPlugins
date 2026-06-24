import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import "../HulaUI"
import QmlPlugins

HulaDialog {
    id: root
    // 是否为编辑模式
    property bool isEdit: editUserData !== null
    // 编辑的用户数据（null表示新增）
    property var editUserData: null
    property bool isAdmin: false
    // 保存信号
    signal userSaved(var data)

    width: 480
    height: 480
    title: editUserData ? qsTr("User.Edit") : qsTr("User.Add")

    // 加载数据
    function loadUserData() {
        if (editUserData) {
            cmbType.currentIndex = editUserData[DbFields.userInfo_Status] >= 0 ? editUserData[DbFields.userInfo_Status] : 0;
            edtAccount.text = editUserData[DbFields.userInfo_Account] || "";
            edtName.text = editUserData[DbFields.userInfo_Name] || "";
            edtDept.text = editUserData[DbFields.userInfo_Dept] || "";
            edtContact.text = editUserData[DbFields.userInfo_Contact] || "";
            edtPassword.text = editUserData[DbFields.userInfo_Password] || "";
        } else {
            cmbType.currentIndex = 0;
            edtAccount.text = "";
            edtName.text = "";
            edtDept.text = "";
            edtContact.text = "";
            edtPassword.text = "";
        }
    }

    // 保存用户
    function saveUser() {
        // 验证
        if (cmbType.currentIndex < 0) {
            snackMessage("User.SelectType");
            return;
        }

        if (edtAccount.text.trim() === "") {
            snackMessage("User.AccountDontNull");
            return;
        }

        if (edtName.text.trim() === "") {
            snackMessage("User.NameDontNull");
            return;
        }

        // 新增时密码必填
        if (!isEdit && edtPassword.text.trim() === "") {
            snackMessage("User.PasswordDontNull");
            return;
        }

        // 编辑时如果填写了新密码，验证确认
        if (isEdit && edtPassword.text.trim() !== "")
        // 这里可以添加密码确认逻辑
        {}

        var data = {};
        data[DbFields.userInfo_Name] = edtName.text.trim();
        data[DbFields.userInfo_Account] = edtAccount.text.trim();
        data[DbFields.userInfo_Status] = cmbType.currentIndex;
        data[DbFields.userInfo_Dept] = edtDept.text.trim();
        data[DbFields.userInfo_Contact] = edtContact.text.trim();
        data[DbFields.userInfo_Password] = edtPassword.text.trim();

        if (edtPassword.text.trim() !== "") {
            data[DbFields.userInfo_Password] = edtPassword.text.trim();
        }

        var ret = 0;
        if (isEdit) {
            data[DbFields.userInfo_Id] = editUserData[DbFields.userInfo_Id];
            ret = userInfo.updateData(data);
            if (ret !== 0) {
                snackMessage("UpdateInvalid");
                return;
            }
            snackMessage("UpdateValid");
        } else {
            ret = userInfo.appendData(data);
            if (ret === 0) {
                snackMessage("AppendInvalid");
                return;
            }
            snackMessage("AppendValid");
        }

        userSaved(data);
        root.close();
    }

    // 显示表单时加载数据
    onShowForm: {
        loadUserData();
    }

    //onCallbackOnOKChanged: saveUser()

    GridLayout {
        id: editBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        columns: 2
        rowSpacing: 16
        columnSpacing: 12
        property int lblWidth: 90
        property int txtWidth: 280
        property int lblFontSize: 16
        property int txtFontSize: 16

        // 用户类型
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Type")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        ComboBox {
            id: cmbType
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            font.pixelSize: parent.txtFontSize
            currentIndex: -1
            selectTextByMouse: true
            editable: false
            model: [qsTr("User.Normal"), qsTr("User.Admin")]
        }

        // 账号
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Account")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        TextField {
            id: edtAccount
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: parent.txtFontSize
            enabled: !isEdit  // 编辑时不可修改账号
            placeholderText: isEdit ? "" : qsTr("User.AccountTip")
        }

        // 密码
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: isEdit ? qsTr("User.NewPassword") : qsTr("User.Password")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        TextField {
            id: edtPassword
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            echoMode: TextInput.Password
            font.pixelSize: parent.txtFontSize
            placeholderText: isEdit ? qsTr("User.PasswordEmpty") : "123456"
        }

        // 姓名
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Name")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        TextField {
            id: edtName
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: parent.txtFontSize
        }

        // 部门
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Dept")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        TextField {
            id: edtDept
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: parent.txtFontSize
        }

        // 手机
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Phone")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        TextField {
            id: edtContact
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: parent.txtFontSize
        }

        // 邮箱
        Label {
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Email")
            font.pixelSize: parent.lblFontSize
            color: "#535353"
        }
        TextField {
            id: edtEmail
            Layout.fillWidth: true
            Layout.preferredWidth: parent.txtWidth
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: parent.txtFontSize
        }
    }
}
