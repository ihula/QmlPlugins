import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQml.Models
import QtQuick.Layouts
import "../Components"
import HulaPlugins

HulaDialog {
    id: root
    property ListModel modelStatus: null
    // 是否为编辑模式
    property bool isEdit: editUserData !== null
    // 编辑的用户数据（null表示新增）
    property var editUserData: null
    property bool isAdmin: false
    // 保存信号
    signal userSaved(var data)

    width: 480
    title: editUserData ? qsTr("User.Edit") : qsTr("User.Add")
    // 高度随表单内容自适应：HulaDialog 高度 = header + footer + contentHeight + 10
    contentHeight: editBar.height

    // 加载数据
    function loadUserData() {
        if (editUserData) {
            cmbType.currentIndex = editUserData[UserInfo.STATUS] >= 0 ? editUserData[UserInfo.STATUS] : 0;
            edtAccount.text = editUserData[UserInfo.ACCOUNT] || "";
            edtName.text = editUserData[UserInfo.NAME] || "";
            edtContact.text = editUserData[UserInfo.CONTACT] || "";
            edtPassword.text = editUserData[UserInfo.PASSWORD] || "";
            cmbRole.currentIndex = -1;
            let roleName = editUserData[UserInfo.ROLENAME] || "";
            for (let i = 0; i < cmbRole.count; i++) {
                if (cmbRole.textAt(i) === roleName) {
                    cmbRole.currentIndex = i;
                    break;
                }
            }
        } else {
            cmbType.currentIndex = 0;
            cmbRole.currentIndex = 0;
            edtAccount.text = "";
            edtName.text = "";
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
        data[UserInfo.NAME] = edtName.text.trim();
        data[UserInfo.ACCOUNT] = edtAccount.text.trim();
        data[UserInfo.STATUS] = cmbType.currentIndex;
        data[UserInfo.DEPT] = edtDept.text.trim();
        data[UserInfo.CONTACT] = edtContact.text.trim();
        data[UserInfo.PASSWORD] = edtPassword.text.trim();

        if (edtPassword.text.trim() !== "") {
            data[UserInfo.PASSWORD] = edtPassword.text.trim();
        }

        var ret = 0;
        if (isEdit) {
            data[UserInfo.ID] = editUserData[UserInfo.ID];
            ret = UserInfo.updateData(data);
            if (ret !== 0) {
                snackMessage("UpdateInvalid");
                return;
            }
            snackMessage("UpdateValid");
        } else {
            ret = UserInfo.appendData(data);
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

        // 用户类型
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Status")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
        }
        ComboBox {
            id: cmbType
            valueRole: "value"
            textRole: "text"
            Layout.fillWidth: true
            topInset: 0
            bottomInset: 0
            font.pixelSize: Themer.editorFontSize
            currentIndex: -1
            selectTextByMouse: true
            editable: false
            model: modelStatus
        }

        // 用户角色
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Role")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
        }
        HulaComboBox {
            id: cmbRole
            Layout.fillWidth: true
            // Layout.preferredHeight: contentHeight + topPadding + bottomPadding
            font.pixelSize: Themer.editorFontSize
            currentIndex: -1
            selectTextByMouse: true
            editable: false
            model: {
                var p = [];
                var roles = RoleManager.getRoles();
                for (let i = 0; i < roles.length; i++) {
                    p.push(roles[i][RoleManager.NAME]);
                }
                return p;
            }
        }

        // 账号
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Account")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
        }
        TextField {
            id: edtAccount
            Layout.fillWidth: true
            // Layout.preferredHeight: contentHeight + topPadding + bottomPadding
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
            enabled: !isEdit  // 编辑时不可修改账号
            placeholderText: isEdit ? "" : qsTr("User.AccountTip")
        }

        // 密码
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.CurrentPassword")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
            visible: isEdit
        }
        TextField {
            id: edtOldPassword
            Layout.fillWidth: true
            // Layout.preferredHeight: contentHeight + topPadding + bottomPadding
            verticalAlignment: Text.AlignVCenter
            echoMode: TextInput.Password
            font.pixelSize: Themer.editorFontSize
            placeholderText: isEdit ? qsTr("User.PasswordEmpty") : "123456"
            visible: isEdit
        }

        // 密码
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: isEdit ? qsTr("User.NewPassword") : qsTr("User.Password")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
        }
        TextField {
            id: edtPassword
            Layout.fillWidth: true
            // Layout.preferredHeight: contentHeight + topPadding + bottomPadding
            verticalAlignment: Text.AlignVCenter
            echoMode: TextInput.Password
            font.pixelSize: Themer.editorFontSize
            placeholderText: isEdit ? qsTr("User.PasswordEmpty") : "123456"
        }

        // 姓名
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Name")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
        }
        TextField {
            id: edtName
            Layout.fillWidth: true
            // Layout.preferredHeight: contentHeight + topPadding + bottomPadding
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
        }

        // 联系方式
        Label {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: qsTr("User.Contact")
            font.pixelSize: Themer.editorFontSize
            color: Themer.fontDarkColor
        }
        TextField {
            id: edtContact
            Layout.fillWidth: true
            // Layout.preferredHeight: contentHeight + topPadding + bottomPadding
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
        }
    }
}
