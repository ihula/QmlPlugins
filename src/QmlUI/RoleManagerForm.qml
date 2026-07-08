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
    property var roleData: ({})
    // 模块定义 - 从 C++ 端获取，与 common.h 中 moduleActionDefs() 同步
    property var moduleDefs: RoleManager.getModuleDefines()
    // 权限数据: { "customers": ["read","write"], "orders": ["read","review","print"], ... }
    property var rolePermissions: ({})

    function cleraForm() {
        edtName.text = "";
        edtDesc.text = "";
        ckbStatus.checked = true;
    }

    function loadData() {
        listview.model.clear();
        var roles = RoleManager.getRoles();
        for (let i = 0; i < roles.length; i++) {
            listview.model.append(roles[i]);
        }
    }

    function loadRole(data) {
        root.roleData = data;
        edtName.text = root.roleData[RoleManager.NAME] || "";
        edtDesc.text = root.roleData[RoleManager.DESC] || "";
        ckbStatus.checked = parseInt(root.roleData[RoleManager.STATUS]) || 0;
        rolePermissions = JSON.parse(root.roleData[RoleManager.PERMS] || "{}");
    }

    function hasModuleAction(module, action) {
        var perms = root.rolePermissions;
        if (!perms[module])
            return false;
        return perms[module].indexOf(action) >= 0;
    }

    function setModuleAction(module, action, enabled) {
        // 手工深拷贝,避免 JSON.parse/stringify 在 QML 引擎中的兼容问题
        var perms = root.rolePermissions;

        if (!perms[module]) {
            perms[module] = [];
            if (!enabled)
                return;
        }

        var idx = perms[module].indexOf(action);
        if (enabled && idx < 0) {
            perms[module].push(action);
        } else if (!enabled && idx >= 0) {
            perms[module].splice(idx, 1);
        }

        rolePermissions = perms;
    }

    function appendRole() {
        let data = {};
        listModel.append(data);
        listview.currentIndex = listModel.count - 1;
    }

    // 保存
    function saveRole() {
        // 验证
        if (edtName.text.trim() === "") {
            snackMessage("Role.NameDontNull");
            return;
        }

        if (listview.currentIndex < 0) {
            snackMessage("Role.UnselectRow");
            return;
        }

        var oldData = listModel.get(listview.currentIndex);
        let isEdit = (oldData[RoleManager.ID] || 0) !== -1;

        // 构造不含 Id 的更新数据
        var data = {};
        data[RoleManager.NAME] = edtName.text.trim();
        data[RoleManager.DESC] = edtDesc.text.trim();
        data[RoleManager.STATUS] = ckbStatus.checked ? 1 : 0;
        data[RoleManager.PERMS] = JSON.stringify(rolePermissions);

        var ret = 0;
        if (isEdit) {
            let condData = {};
            condData[RoleManager.ID] = oldData[RoleManager.ID];
            ret = RoleManager.updateRole(data, condData);
            if (ret !== 0) {
                snackMessage("UpdateInvalid");
                return;
            }
            snackMessage("UpdateValid");

            data = RoleManager.findRole(condData);
            listModel.set(listview.currentIndex, data);
        } else {
            ret = RoleManager.appendRole(data);
            if (ret === 0) {
                snackMessage("AppendInvalid");
                return -1;
            }
            snackMessage("AppendValid");
            let condData = {};
            condData[RoleManager.ID] = ret;
            data = RoleManager.findRole(condData);
            listModel.set(listview.currentIndex, data);
        }
    }

    function deleteRole() {
        if (listview.currentIndex < 0) {
            snackMessage("NullRow");
            return;
        }
        let idlist = [];
        let data = listModel.get(listview.currentIndex);
        idlist.push(String(data[RoleManager.ID]));

        var funcDelete = function () {
            var ret = RoleManager.deleteRoles(idlist);
            if (ret === 0) {
                snackMessage("DeleteValid");
                var idx = listview.currentIndex;
                listModel.remove(idx);
                // 强制刷新 currentIndex: 先重置为 -1，再设为目标索引，触发 onCurrentIndexChanged
                if (listModel.count > 0) {
                    var newIdx = Math.min(idx, listModel.count - 1);
                    listview.currentIndex = -1;
                    listview.currentIndex = newIdx;
                } else {
                    listview.currentIndex = -1;
                }
            } else {
                snackMessage("DeleteInvalid");
            }
        };
        openDialogConfirm("ConfirmDelete", funcDelete);
    }

    Component.onCompleted: {
        loadData();
    }

    Rectangle {
        id: itemPatients
        radius: 8
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        width: 320
        color: Themer.workFormColor
        Label {
            id: lblSpecimenList
            anchors.left: parent.left
            anchors.top: parent.top
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            height: Themer.editorHeight
            anchors.margins: 8
            anchors.leftMargin: 18
            text: qsTr("Role.RoleList")
            font.pixelSize: Themer.editorFontSize
            palette.button: Themer.editorFontColor
        }

        Rectangle {
            id: lineSpecimenList
            anchors.top: lblSpecimenList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            anchors.topMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            color: Themer.lineColor
        }

        Row {
            id: btnListBar
            anchors.top: lineSpecimenList.bottom
            anchors.left: parent.left
            anchors.leftMargin: 12
            spacing: 8
            visible: false

            CheckBox {
                id: chkSelect
                font.pixelSize: 16
                text: qsTr("Role.EnableSelect")
                Material.background: "white"
                Material.foreground: "#535353"
                height: 46
            }

            CheckBox {
                id: chkAll
                font.pixelSize: 16
                text: qsTr("Role.SelectAll")
                Material.background: "white"
                Material.foreground: "#535353"
                height: 46
                tristate: true
                checkState: childGroup.checkState

                onClicked: {
                    if (checkState === Qt.PartiallyChecked) {
                        checkState = Qt.Checked;
                    }
                    for (let i = 0; i < childGroup.buttons.length; i++) {
                        childGroup.buttons[i].checked = (checkState === Qt.Checked);
                    }
                }
            }
        }

        ButtonGroup {
            id: childGroup
            exclusive: false  // 关键：允许同时选中多个子项
        }

        ListView {
            id: listview
            property color itemColor: Qt.alpha("#F4F4F4", Window.window.alpha)
            property color highColor: Qt.alpha(Themer.hoveredColor, Window.window.alpha)
            property int spaceing: 2

            clip: true
            anchors.top: btnListBar.visible ? btnListBar.bottom : lineSpecimenList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8

            onCurrentIndexChanged: {
                cleraForm();
                if (currentIndex >= 0)
                    loadRole(listModel.get(currentIndex));
            }

            highlight: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: listview.spaceing
                    color: listview.highColor
                    radius: 6
                }
            }

            ScrollBar.vertical: CustomScrollBar {
                policy: ScrollBar.AsNeeded
            }

            model: ListModel {
                id: listModel
            }

            delegate: ItemDelegate {
                id: item
                required property int index
                required property string name
                required property string description
                property alias itemChecked: checkbox.checked
                property color backColor: ListView.isCurrentItem ? listview.highColor : listview.itemColor
                property color textColor: ListView.isCurrentItem ? Themer.fontLightColor : Themer.fontDarkColor
                width: ListView.view.width
                height: 60
                contentItem: Rectangle {
                    radius: 6
                    anchors.fill: parent
                    anchors.margins: listview.spaceing
                    color: item.backColor

                    CheckBox {
                        id: checkbox
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        ButtonGroup.group: childGroup
                        visible: chkSelect.checked
                        onClicked: {
                            let hasChecked = false;
                            let hasUnchecked = false;
                            for (let i = 0; i < childGroup.buttons.length; i++) {
                                if (childGroup.buttons[i].checked)
                                    hasChecked = true;
                                else
                                    hasUnchecked = true;
                            }

                            if (!hasUnchecked) {
                                chkAll.checkState = Qt.Checked;
                            } else if (!hasChecked) {
                                chkAll.checkState = Qt.Unchecked;
                            } else {
                                chkAll.checkState = Qt.PartiallyChecked;
                            }
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 4
                        anchors.leftMargin: checkbox.visible ? checkbox.width : 4

                        Text {
                            color: item.textColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: item.name
                            height: parent.height / 2
                            font.pixelSize: Themer.editorFontSize
                        }
                        Text {
                            color: item.textColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: item.description
                            height: parent.height / 2
                            font.pixelSize: Themer.editorFontSize - 2
                            font.weight: Font.Light
                        }
                    }
                }
                onClicked: {
                    listview.currentIndex = index;
                }
            }
        }
    }

    Rectangle {
        id: searchBar
        anchors.left: itemPatients.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 8
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

            RoundButton {
                id: btnAdd
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: Themer.buttonColor
                Material.foreground: "white"
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("Role.Add")
                radius: 4
                onClicked: appendRole()
            }

            RoundButton {
                id: btnSave
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: Themer.buttonColor
                Material.foreground: Themer.fontLightColor
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("Role.Save")
                // enabled: UserInfo.hasModuleAction(UserInfo.ROLEMANAGER, UserInfo.READ)
                radius: 4
                onClicked: saveRole()
            }

            RoundButton {
                id: btnDelete
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: Themer.warnColor
                Material.foreground: Themer.fontLightColor
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("Role.Delete")
                //enabled: UserInfo.hasModuleAction(UserInfo.ROLEMANAGER, UserInfo.READ)
                radius: 4
                onClicked: {
                    deleteRole();
                }
            }
        }
    }

    Rectangle {
        id: infoBar
        anchors.left: searchBar.left
        anchors.right: searchBar.right
        anchors.top: searchBar.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 8
        radius: 8

        GridLayout {
            id: editBar
            anchors.left: infoBar.left
            anchors.right: infoBar.right
            anchors.top: infoBar.top
            anchors.topMargin: 12
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            columns: 2
            rowSpacing: 16
            columnSpacing: 12

            // 姓名
            Label {
                Layout.preferredHeight: Themer.editorHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: qsTr("Role.Name") + "*"
                font.pixelSize: Themer.editorFontSize
                color: Themer.fontDarkColor
            }

            TextField {
                id: edtName
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight + topPadding + bottomPadding
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Themer.editorFontSize
                placeholderText: !focus ? qsTr("Role.InputName") : ""
            }

            // 描述
            Label {
                Layout.preferredHeight: Themer.editorHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: qsTr("Role.Description")
                font.pixelSize: Themer.editorFontSize
                color: Themer.fontDarkColor
            }
            TextField {
                id: edtDesc
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight + topPadding + bottomPadding
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Themer.editorFontSize
                placeholderText: !focus ? qsTr("Role.InputDesc") : ""
            }

            // 状态
            Label {
                Layout.preferredHeight: Themer.editorHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: qsTr("Role.Status")
                font.pixelSize: Themer.editorFontSize
                color: Themer.fontDarkColor
            }
            CheckBox {
                id: ckbStatus
                Layout.fillWidth: true
                Layout.preferredHeight: edtDesc.height
                font.pixelSize: Themer.editorFontSize
                Material.foreground: Themer.fontDarkColor
                text: qsTr("Role.Enabled")
            }
        }

        // 权限配置（多选 CheckBox）
        ColumnLayout {
            anchors.left: editBar.left
            anchors.right: editBar.right
            anchors.top: editBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 0
            spacing: 5

            RowLayout {
                Label {
                    text: "权限配置"
                    color: Themer.fontDarkColor
                }
                Item {
                    Layout.fillWidth: true
                }
                Button {
                    text: "全选"
                    Material.foreground: Themer.fontDarkColor
                    flat: true
                    onClicked: setAllPermissions(true)
                    visible: false
                }
                Button {
                    text: "清空"
                    flat: true
                    Material.foreground: Themer.fontDarkColor
                    onClicked: setAllPermissions(false)
                    visible: false
                }
            }

            ScrollView {
                id: sclvPrem
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 12
                Layout.topMargin: 0
                ScrollBar.vertical: CustomScrollBar {
                    parent: sclvPrem
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: root.moduleDefs

                        delegate: GroupBox {
                            required property string module
                            required property var actions

                            Layout.fillWidth: true
                            topPadding: 32
                            font.pixelSize: Themer.editorFontSize
                            title: qsTr("PermModule." + module)

                            background: Rectangle {
                                border.width: 0
                            }

                            label: Text {
                                color: Themer.fontDarkColor
                                text: parent.title
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 12

                                Repeater {
                                    id: rptCheckbox
                                    model: actions

                                    delegate: CheckBox {
                                        required property string modelData
                                        property string moduleName: module
                                        implicitHeight: Themer.editorHeight
                                        Material.foreground: Themer.fontDarkColor
                                        text: qsTr("PermAction." + modelData)
                                        checked: hasModuleAction(module, modelData)/*{
                                            console.log(1, moduleName, modelData);
                                            var p = JSON.parse(rolePermissions);
                                            var arr = (p && typeof p === 'object') ? p[moduleName] : undefined;
                                            console.log(22, arr);
                                            return arr ? arr.indexOf(modelData) >= 0 : false;
                                        }*/
                                        onToggled: setModuleAction(module, modelData, checked)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
