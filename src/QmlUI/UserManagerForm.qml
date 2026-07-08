import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import QtCore
import "../Components"
import HulaPlugins

Item {
    id: root
    property string searchAccount: ""
    property string searchName: ""
    property int searchType: -1
    property int totalCount: 0
    property int pageSize: 20
    property int currentPage: 1
    property int totalPages: 1
    property var selectedIds: []

    function loadData() {
        tableview.model.clear();
        selectedIds = [];

        var allUsers = UserInfo.getUsers();
        var filteredUsers = [];

        for (var i = 0; i < allUsers.length; i++) {
            var user = allUsers[i];
            if (searchAccount && user["Account"].indexOf(searchAccount) < 0) {
                continue;
            }
            if (searchName && user["Name"].indexOf(searchName) < 0) {
                continue;
            }
            if (searchType >= 0 && user["Status"] !== searchType) {
                continue;
            }
            filteredUsers.push(user);
        }

        totalCount = filteredUsers.length;
        totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
        if (currentPage > totalPages)
            currentPage = totalPages;

        var start = (currentPage - 1) * pageSize;
        var end = Math.min(start + pageSize, totalCount);

        for (var j = start; j < end && j < filteredUsers.length; j++) {
            var u = filteredUsers[j];
            tableview.model.appendRow(filteredUsers[j]);
        }
    }

    function updateSelectedIds() {
        selectedIds = [];
        for (var i = 0; i < tableview.rows; i++) {
            var item = tableview.itemAtIndex(tableview.index(i, 0));
            if (item && item.checked) {
                var data = tableview.model.getRow(i);
                selectedIds.push(data["Id"]);
            }
        }
        btnBatchDelete.visible = selectedIds.length > 0;
    }

    function openUserDialog(userData) {
        var component = Qt.createComponent("UserEditForm.qml");
        if (component.status === Component.Ready) {
            var dlg = component.createObject(Window.window);
            dlg.modelStatus = modelStatus;
            dlg.isAdmin = true;
            if (userData) {
                dlg.editUserData = userData;
            }
            dlg.onUserSaved.connect(function () {
                loadData();
            });
            dlg.open();
        } else if (component.status === Component.Error) {
            console.error("加载 UserEditForm 失败:", component.errorString());
            snackMessage("加载 UserEditForm 失败:", component.errorString());
        }
    }

    function batchDeleteUsers() {
        if (selectedIds.length === 0) {
            snackMessage("NullRow");
            return;
        }

        var funcDelete = function () {
            var failed = [];
            for (var i = 0; i < selectedIds.length; i++) {
                var ret = UserInfo.deleteData(String(selectedIds[i]));
                if (ret !== 0) {
                    failed.push(selectedIds[i]);
                }
            }
            if (failed.length === 0) {
                snackMessage("DeleteValid");
            } else {
                snackMessage("DeleteInvalid");
            }
            loadData();
        };

        openDialogConfirm("ConfirmDelete", funcDelete);
    }

    function deleteUser(userId) {
        var funcDelete = function () {
            var ret = UserInfo.deleteData(String(userId));
            if (ret === 0) {
                snackMessage("DeleteValid");
                loadData();
            } else {
                snackMessage("DeleteInvalid");
            }
        };
        openDialogConfirm("ConfirmDelete", funcDelete);
    }

    Component.onCompleted: {
        loadData();
    }

    // 持久化列宽设置
    Settings {
        property string account: UserInfo.userAccount
        location: "file:" + CUSTOM_PATH + (account ? account + ".ini" : "Custom.ini")
        category: "UserManager"
        property alias column0Width: tableview.column0Width
        property alias column1Width: tableview.column1Width
        property alias column2Width: tableview.column2Width
        property alias column3Width: tableview.column3Width
        property alias column4Width: tableview.column4Width
        property alias column5Width: tableview.column5Width
        property alias column6Width: tableview.column6Width
        property alias column7Width: tableview.column7Width
    }

    ListModel {
        id: modelStatus
        ListElement {
            value: 1
            text: qsTr("User.Enabled")
        }
        ListElement {
            value: 0
            text: qsTr("User.Disabled")
        }
    }

    Rectangle {
        id: searchBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 60
        color: "white"
        border.width: 1
        border.color: Themer.borderColor
        radius: 8

        Row {
            id: itemSearch
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            TextField {
                id: edtSearchAccount
                width: 160
                height: Themer.editorHeight
                placeholderText: qsTr("User.Account")
                font.pixelSize: Themer.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                // verticalAlignment: Text.AlignVCenter
            }

            TextField {
                id: edtSearchName
                width: 160
                height: Themer.editorHeight
                placeholderText: qsTr("User.Name")
                font.pixelSize: Themer.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                // verticalAlignment: Text.AlignVCenter
            }

            ComboBox {
                id: cmbSearchType
                valueRole: "value"
                textRole: "text"
                implicitContentWidthPolicy: ComboBox.WidestText
                height: Themer.editorHeight
                font.pixelSize: Themer.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: 0
                model: modelStatus
            }

            ComboBox {
                id: cmbSearchRole
                implicitContentWidthPolicy: ComboBox.WidestText
                height: Themer.editorHeight
                font.pixelSize: Themer.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: 0
                model: {
                    var p = [qsTr("User.RoleAll")];
                    var roles = RoleManager.getRoles();
                    for (let i = 0; i < roles.length; i++) {
                        p.push(roles[i][RoleManager.NAME]);
                    }
                    return p;
                }
            }

            Item {
                width: 20
            }

            RoundButton {
                id: btnSearch
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: "white"
                Material.foreground: "black"
                text: qsTr("User.Search")
                radius: 4
                onClicked: {
                    searchAccount = edtSearchAccount.text.trim();
                    searchName = edtSearchName.text.trim();
                    searchType = cmbSearchType.currentIndex - 1;
                    currentPage = 1;
                    loadData();
                }
            }

            Rectangle {
                width: 1
                border.color: Themer.lineColor
                implicitHeight: Themer.editorHeight
                anchors.margins: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            RoundButton {
                id: btnAdd
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: Themer.buttonColor
                Material.foreground: "white"
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.Add")
                radius: 4
                onClicked: openUserDialog()
            }

            RoundButton {
                id: btnEdit
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: Themer.buttonColor
                Material.foreground: "white"
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.Edit")
                radius: 4
                onClicked: {
                    if (tableview.currentRow < 0)
                        return;
                    var data = tableview.model.getRow(tableview.currentRow);
                    openUserDialog(data);
                }
            }

            RoundButton {
                id: btnBatchDelete
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: Themer.warnColor
                Material.foreground: "white"
                text: qsTr("User.Delete")
                radius: 4
                //visible: selectedIds.length > 0
                onClicked: batchDeleteUsers()
            }
        }
    }

    HulaTableHeader {
        id: tableheader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchBar.bottom
        anchors.topMargin: 8
        anchors.bottom: paginationBar.top
        anchors.bottomMargin: 8
        color: Themer.workFormColor
        radius: 8
        itemBorderColor: Themer.lineColor
        border.color: Qt.alpha(Themer.borderGrayColor, 0.2)
        view: tableview

        TableViewEx {
            id: tableview
            property int column0Width: 0
            property int column1Width: 0
            property int column2Width: 200
            property int column3Width: 200
            property int column4Width: 200
            property int column5Width: 200
            property int column6Width: 200
            property int column7Width: 200

            headerTitles: ["Id", "User.Account", "User.Name", "User.Status", "User.RoleName", "User.Contact", "User.LastLogin", "User.CreateTime"]
            horHeader: tableheader

            model: TableModel {
                TableModelColumn {
                    display: UserInfo.ID
                }
                TableModelColumn {
                    display: UserInfo.ACCOUNT
                }
                TableModelColumn {
                    display: UserInfo.NAME
                }
                TableModelColumn {
                    display: UserInfo.STATUS
                }
                TableModelColumn {
                    display: UserInfo.ROLENAME
                }
                TableModelColumn {
                    display: UserInfo.CONTACT
                }
                TableModelColumn {
                    display: UserInfo.LASTLOGIN
                }
                TableModelColumn {
                    display: UserInfo.CREATETIME
                }
            }

            selectionModel: ItemSelectionModel {
                id: sltModel
                model: tableview.model
            }

            delegate: DelegateChooser {
                DelegateChoice {
                    id: choiceStatus
                    column: 3
                    delegate: CellRect {
                        Text {
                            id: txt
                            property int content: display || 0
                            anchors.fill: parent
                            anchors.margins: 2
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: {
                                if (content === 0)
                                    return qsTr("User.Disabled");
                                else
                                    return qsTr("User.Enabled");
                            }
                            elide: Text.ElideRight
                        }
                    }
                }
                DelegateChoice {
                    delegate: CellRect {
                        Text {
                            anchors.fill: parent
                            anchors.margins: 2
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: display || ""
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: paginationBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 50
        color: "white"
        border.width: 1
        border.color: Themer.borderColor
        radius: 8

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Label {
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.Total") + ": " + totalCount + " " + qsTr("User.Records")
                font.pixelSize: 14
                color: "#535353"
            }

            Item {
                Layout.preferredWidth: 20
            }

            RoundButton {
                id: btnFirst
                Layout.preferredWidth: 36
                Layout.preferredHeight: 28
                text: "<<"
                radius: 4
                font.pixelSize: 12
                Material.background: "white"
                Material.foreground: "#535353"
                enabled: currentPage > 1
                onClicked: {
                    currentPage = 1;
                    loadData();
                }
            }

            RoundButton {
                id: btnPrev
                Layout.preferredWidth: 36
                Layout.preferredHeight: 28
                text: "<"
                radius: 4
                font.pixelSize: 12
                Material.background: "white"
                Material.foreground: "#535353"
                enabled: currentPage > 1
                onClicked: {
                    currentPage--;
                    loadData();
                }
            }

            Label {
                Layout.alignment: Qt.AlignVCenter
                text: currentPage + " / " + totalPages
                font.pixelSize: 14
                color: "#535353"
                minimumPixelSize: 12
            }

            RoundButton {
                id: btnNext
                Layout.preferredWidth: 36
                Layout.preferredHeight: 28
                text: ">"
                radius: 4
                font.pixelSize: 12
                Material.background: "white"
                Material.foreground: "#535353"
                enabled: currentPage < totalPages
                onClicked: {
                    currentPage++;
                    loadData();
                }
            }

            RoundButton {
                id: btnLast
                Layout.preferredWidth: 36
                Layout.preferredHeight: 28
                text: ">>"
                radius: 4
                font.pixelSize: 12
                Material.background: "white"
                Material.foreground: "#535353"
                enabled: currentPage < totalPages
                onClicked: {
                    currentPage = totalPages;
                    loadData();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.PerPage")
                font.pixelSize: 14
                color: "#535353"
            }

            ComboBox {
                id: cmbPageSize
                Layout.preferredWidth: 70
                Layout.preferredHeight: 28
                font.pixelSize: 12
                model: [10, 20, 50, 100]
                currentIndex: 1
                onCurrentIndexChanged: {
                    pageSize = model[currentIndex];
                    currentPage = 1;
                    loadData();
                }
            }
        }
    }
}
