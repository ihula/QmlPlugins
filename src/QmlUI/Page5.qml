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

    DataDict {
        id: dataDict
    }

    function loadData() {
    // tableview.model.clear();
    // var dictTypes = [DictType.Sex, DictType.Dept, DictType.Doctor, DictType.SpecimenQuality, DictType.SpecimenType, DictType.Diagnosis];
    // for (let t = 0; t < dictTypes.length; t++) {
    //     var datas = dataDict.getDatas(dictTypes[t]);
    //     for (let i = 0; i < datas.length; i++) {
    //         tableview.model.appendRow(datas[i]);
    //     }
    // }
    }

    function openDataDictDialog(dictData) {
        var component = Qt.createComponent("DataDictForm.qml");
        if (component.status === Component.Ready) {
            var dlg = component.createObject(Window.window);
            if (dictData) {
                dlg.dictType = dictData.Type;
            }
            dlg.onAccepted.connect(function () {
                loadData();
            });
            dlg.open();
        } else if (component.status === Component.Error) {
            console.error("加载 DataDictForm 失败:", component.errorString());
            snackMessage("加载 DataDictForm 失败:", component.errorString());
        }
    }

    function deleteDataDict(dictId) {
        var funcDelete = function () {
            var ret = dataDict.deleteData(String(dictId));
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

    Settings {
        property string account: UserInfo.userAccount
        location: "file:" + CUSTOM_PATH + (account ? account + ".ini" : "Custom.ini")
        category: "DataDict"
        property alias column0Width: tableview.column0Width
        property alias column1Width: tableview.column1Width
        property alias column2Width: tableview.column2Width
        property alias column3Width: tableview.column3Width
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
                id: edtSearchName
                width: 160
                height: Themer.editorHeight
                placeholderText: qsTr("DataDict.Search")
                font.pixelSize: Themer.buttonFontSize
                anchors.verticalCenter: parent.verticalCenter
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
                onClicked: {}
            }

            RoundButton {
                id: btnReset
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: "#535353"
                Material.foreground: "white"
                text: qsTr("User.Reset")
                radius: 4
                onClicked: {}
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
                onClicked: openDataDictDialog(null)
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
                    var data = tableview.model.getRow(tableview.currentRow);
                    openDataDictDialog(data);
                }
            }

            RoundButton {
                id: btnDelete
                width: Themer.buttonWidth
                implicitHeight: Themer.buttonHeight
                font.pixelSize: Themer.buttonFontSize
                Material.background: "#D93025"
                Material.foreground: "white"
                Layout.alignment: Qt.AlignVCenter
                text: qsTr("User.Delete")
                radius: 4
                onClicked: {
                    var data = tableview.model.getRow(tableview.currentRow);
                    if (data) {
                        deleteDataDict(data.Id);
                    }
                }
            }
        }
    }

    HulaTableHeader {
        id: tableheader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: searchBar.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        color: Themer.workFormColor
        radius: 8
        itemBorderColor: Themer.lineColor
        border.color: Qt.alpha(Themer.borderGrayColor, 0.2)
        view: tableview

        TableViewEx {
            id: tableview
            headerTitles: ["Id", "DataDict.Type", "DataDict.Value", "DataDict.CreateTime"]
            property int column0Width: 0
            property int column1Width: 150
            property int column2Width: 300
            property int column3Width: 200

            anchors.fill: parent
            anchors.leftMargin: tableheader.border.width
            anchors.topMargin: tableheader.horHeaderHeight + tableheader.border.width

            model: TableModel {
                TableModelColumn {
                    display: "Id"
                }
                TableModelColumn {
                    display: "Type"
                }
                TableModelColumn {
                    display: "Value"
                }
                TableModelColumn {
                    display: "CreateTime"
                }
            }
        }
    }
}
