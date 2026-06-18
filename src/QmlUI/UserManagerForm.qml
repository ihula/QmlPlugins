import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import QtCore
import "../HulaUI"
import QmlPlugins

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

    // 列宽属性（可调整）
    property int col0Width: 0
    property int col1Width: tableview.columnsWidth[1]
    property int col2Width: 120
    property int col3Width: 0
    property int col4Width: 120
    property int col5Width: 120
    property int col6Width: 120
    property int col7Width: 110
    property QtObject myData: QtObject {
        property int col0: 0
        property int col1: 200
        property int col2: 300
    }

    property var headerTitles: ["", "User.Account", "User.Name", "User.Type", "User.Dept", "User.Phone", "User.Email"]
    property var columnsWidth: [40, 120, 100, 80, 120, 130, 180]

    function loadData() {
        tableview.model.clear();
        selectedIds = [];

        var allUsers = userInfo.getDatas();
        var filteredUsers = [];

        for (var i = 0; i < allUsers.length; i++) {
            var user = allUsers[i];
            if (searchAccount && user["Account"].indexOf(searchAccount) < 0) {
                continue;
            }
            if (searchName && user["Name"].indexOf(searchName) < 0) {
                continue;
            }
            if (searchType >= 0 && user["Type"] !== searchType) {
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

        var adminText = qsTr("User.Admin");
        var normalText = qsTr("User.Normal");

        for (var j = start; j < end && j < filteredUsers.length; j++) {
            var u = filteredUsers[j];
            u[DbFields.userInfo_Type] = u[DbFields.userInfo_Type] || 0;
            u[DbFields.userInfo_Type + "Text"] = (u[DbFields.userInfo_Type] === 1) ? adminText : normalText;
            tableview.model.appendRow(u);
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
        var component = Qt.createComponent("UserEditDialog.qml");
        if (component.status === Component.Ready) {
            var dlg = component.createObject(mainForm);
            dlg.x = (mainForm.width - dlg.width) / 2;
            dlg.y = (mainForm.height - dlg.height) / 2;
            dlg.isAdmin = true;
            if (userData) {
                dlg.editUserData = userData;
            }
            dlg.onUserSaved.connect(function () {
                loadData();
            });
            dlg.open();
        } else if (component.status === Component.Error) {
            console.error("加载 UserEditDialog 失败:", component.errorString());
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
                var ret = userInfo.deleteData(String(selectedIds[i]));
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
            var ret = userInfo.deleteData(String(userId));
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
        location: "file:" + APP_PATH + "/config1.ini"
        category: "UserManager"
        property alias savedCol0Width: tableview.col0
        property alias savedCol1Width: tableview.col1
        property alias savedCol2Width: tableview.col2
        property alias savedCol3Width: tableview.col3
        property alias savedCol4Width: tableview.col4
        property alias savedCol5Width: tableview.col5
        property alias savedCol6Width: tableview.col6
        property alias savedCol7Width: tableview.col7
    }

    Rectangle {
        id: searchBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 60
        color: "white"
        border.width: 1
        border.color: Themer.theme.borderColor
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
                height: Themer.theme.editorHeight
                placeholderText: qsTr("User.Account")
                font.pixelSize: Themer.theme.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                // verticalAlignment: Text.AlignVCenter
            }

            TextField {
                id: edtSearchName
                width: 160
                height: Themer.theme.editorHeight
                placeholderText: qsTr("User.Name")
                font.pixelSize: Themer.theme.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                // verticalAlignment: Text.AlignVCenter
            }

            ComboBox {
                id: cmbSearchType
                width: 160
                height: Themer.theme.editorHeight
                font.pixelSize: Themer.theme.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: 0
                model: [qsTr("User.TypeAll"), qsTr("User.Normal"), qsTr("User.Admin")]
            }

            Item {
                width: 20
            }

            RoundButton {
                id: btnSearch
                width: Themer.theme.buttonWidth
                implicitHeight: Themer.theme.buttonHeight
                font.pixelSize: Themer.theme.buttonFontSize
                Material.background: "white" //Themer.theme.buttonColor
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

            RoundButton {
                id: btnReset
                width: Themer.theme.buttonWidth
                implicitHeight: Themer.theme.buttonHeight
                font.pixelSize: Themer.theme.buttonFontSize
                Material.background: "#535353"//Themer.theme.buttonColor
                Material.foreground: "white"
                text: qsTr("User.Reset")
                radius: 4
                onClicked: {
                    edtSearchAccount.text = "";
                    edtSearchName.text = "";
                    cmbSearchType.currentIndex = 0;
                    searchAccount = "";
                    searchName = "";
                    searchType = -1;
                    currentPage = 1;
                    loadData();
                }
            }

            Rectangle {
                width: 1
                border.color: Themer.theme.lineColor
                implicitHeight: Themer.theme.editorHeight
                anchors.margins: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            RoundButton {
                id: btnBatchDelete
                width: Themer.theme.buttonWidth
                implicitHeight: Themer.theme.buttonHeight
                font.pixelSize: Themer.theme.buttonFontSize
                Material.background: Themer.theme.warnColor
                Material.foreground: "white"
                text: qsTr("User.Delete")
                radius: 4
                //visible: selectedIds.length > 0
                onClicked: batchDeleteUsers()
            }

            RoundButton {
                id: btnAdd
                width: Themer.theme.buttonWidth
                implicitHeight: Themer.theme.buttonHeight
                font.pixelSize: Themer.theme.buttonFontSize
                Material.background: Themer.theme.buttonColor
                Material.foreground: "white"
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.Add")
                radius: 4
                onClicked: openUserDialog()
            }

            RoundButton {
                id: btnEdit
                width: Themer.theme.buttonWidth
                implicitHeight: Themer.theme.buttonHeight
                font.pixelSize: Themer.theme.buttonFontSize
                Material.background: Themer.theme.buttonColor
                Material.foreground: "white"
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.Edit")
                radius: 4
                onClicked: {
                    var data = tableview.model.getRow(tableview.currentRow);
                    openUserDialog(data);
                }
            }
        }
    }

    HulaTableHeader {
        id: control
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchBar.bottom
        anchors.topMargin: 8
        anchors.bottom: paginationBar.top
        anchors.bottomMargin: 8
        color: Themer.theme.workFormColor
        radius: 8
        itemBorderColor: Themer.theme.lineColor
        border.color: Qt.alpha(Themer.theme.borderGrayColor, 0.2)
        view: tableview

        TableView {
            id: tableview

            // property bool firstLoaded: false
            property var headerTitles: ["Id", "User.Account", "User.Name", "Type", "User.Type", "User.Contact", "User.Dept", "Password"]
            property var columnsWidth: [col0Width, col1Width, col2Width, col3Width, col4Width, col5Width, col6Width, col7Width]

            property int col0: 0
            property int col1: 200
            property int col2: 200
            property int col3: 200
            property int col4: 200
            property int col5: 200
            property int col6: 200
            property int col7: 200
            property int col8: 200

            function selectRow(row) {
                var newIndex = tableview.index(row, 0);
                tableview.selectionModel.setCurrentIndex(newIndex, ItemSelectionModel.Select | ItemSelectionModel.Rows);
            }

            // onRowsChanged: {
            //     if (!firstLoaded && (tableview.rows > 0)) {
            //         firstLoaded = true;
            //         tableview.selectRow(0);
            //     }
            // }

            anchors.fill: parent
            //anchors.rightMargin: control.border.width
            anchors.leftMargin: control.border.width
            anchors.topMargin: control.horHeaderHeight + control.border.width
            // 多1个高度,防止最后一行边框与外边框相连
            //anchors.bottomMargin: control.border.width * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            columnSpacing: 0
            rowSpacing: 0
            selectionMode: TableView.SingleSelection // 或 ExtendedSelection
            selectionBehavior: TableView.SelectRows
            ScrollBar.vertical: ScrollBar {}

            ScrollBar.horizontal: ScrollBar {}

            rowHeightProvider: function (row) {
                return control.rowHeight;
            }
            //此属性可以保存一个函数，该函数返回模型中每个列的列宽
            columnWidthProvider: function (column) {
                if ((column >= 0) && (column < tableview.columnsWidth.length)) {
                    var key = "col" + String(column);
                    return tableview[key];
                } else {
                    return 60;
                }
            }
            model: TableModel {
                TableModelColumn {
                    display: DbFields.userInfo_Id
                }
                TableModelColumn {
                    display: DbFields.userInfo_Account
                }
                TableModelColumn {
                    display: DbFields.userInfo_Name
                }
                TableModelColumn {
                    display: DbFields.userInfo_Type
                }
                TableModelColumn {
                    display: DbFields.userInfo_Type + "Text"
                }
                TableModelColumn {
                    display: DbFields.userInfo_Contact
                }
                TableModelColumn {
                    display: DbFields.userInfo_Dept
                }
                TableModelColumn {
                    display: DbFields.userInfo_Password
                }
            }

            selectionModel: ItemSelectionModel {
                id: sltModel
                model: tableview.model
            }

            delegate: Rectangle {
                color: (row === tableview.currentRow) ? "#1E90FF" : (tableview.alternatingRows && row % 2 !== 0) ? Qt.darker("white", 1.1) : "white"
                MouseArea {
                    anchors.fill: parent
                    onClicked: tableview.selectRow(row)
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

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Themer.theme.lineColor
                }
                Rectangle {
                    anchors.right: parent.right
                    height: parent.height
                    width: 1
                    color: Themer.theme.lineColor
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
        border.color: Themer.theme.borderColor
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
