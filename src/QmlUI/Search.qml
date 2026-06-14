import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.qmlmodels
import QtQuick.Dialogs
import "../HulaUI"
import QmlPlugins

Rectangle {
    id: root
    color: "transparent"
    property bool autoDestroy: false
    property QtObject ownerLoader: null
    property string formTitle: qsTr("Search.SampleSearch") + translater.change
    property var patientData: ({})

    enum FieldType {
        String,
        Int,
        Double,
        Bool,
        DateTime
    }

    DataDict {
        id: dataDict
    }

    Patients {
        id: patients
    }

    onVisibleChanged: {
        if (visible) {
            init();
            return;
        }
        if (autoDestroy) {
            if (ownerLoader !== null) {
                ownerLoader.source = "";
            } else {
                destroy();
            }
        }
    }

    function init() {
        clearEditor();
        searchPatients();
        loadExportInfo();
    }

    FileDialog {
        id: fileDialog
        property bool exporting: false
        fileMode: FileDialog.SaveFile
        title: qsTr("Search.SelectFileSavePath") + translater.change
        property string filterName: qsTr("Search.FileType") + translater.change
        nameFilters: [filterName + " (*.bak)"]
        onAccepted: {
            if (exporting) {
                fileMode = FileDialog.SaveFile;
                exportXlsx();
            } else if (fileMode === FileDialog.SaveFile) {
                backupDb();
            } else if (fileMode === FileDialog.OpenFile) {
                recoverDb();
            }
        }
        visible: false
    }

    Rectangle {
        id: rectInfo
        radius: 8
        anchors.fill: parent
        anchors.margins: 0
        color: Themer.theme.workFormColor // Qt.alpha(Themer.theme.workFormColor, mainForm.alpha)
        border.width: 1
        border.color: Themer.theme.lineColor

        Item {
            id: leftBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 18
            width: 300
            clip: true

            Label {
                id: lblLeftTitle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                font.pixelSize: 14
                font.bold: true
                text: qsTr("Search.Filter") + translater.change
                background: Rectangle {
                    height: 1
                    color: Themer.theme.lineColor
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -4
                }
            }

            GridLayout {
                id: layBaseEditor
                anchors.top: lblLeftTitle.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                height: 480
                columns: 2
                rowSpacing: 0
                //columnSpacing: 56
                property int lblWidth: 88
                property int lblHeight: 36
                property int txtWidth: 158
                property int txtHeight: 32
                property int lblFontSize: 14
                property int txtFontSize: 14

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.TestId") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                TextField {
                    id: edtTestId
                    property string fieldName: "TestId="
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    text: ""
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.Name") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                TextField {
                    id: edtName
                    property string fieldName: "Name="
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    text: ""
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.Sex") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    background: createMouse(this, cmbSex)
                }
                ComboBox {
                    id: cmbSex
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Sex="
                    property int dictType: DataDict.Sex
                    onDownChanged: {
                        if (popup.visible)
                            model = dataDict.getValues(dictType);
                    }
                    model: dataDict.getValues(dictType)
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.Age") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }

                Row {
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    TextField {
                        id: edtAgeY
                        property string fieldName: "AgeY="
                        width: 30
                        leftPadding: 4
                        rightPadding: 4
                        height: layBaseEditor.txtHeight
                        font.pixelSize: layBaseEditor.txtFontSize
                        Material.foreground: Themer.theme.editorFontColor
                    }
                    Label {
                        id: lblAgeY
                        height: layBaseEditor.txtHeight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: qsTr("Home.AgeY") + translater.change
                        font.pixelSize: layBaseEditor.lblFontSize
                        Material.foreground: Themer.theme.editorFontColor
                    }
                    TextField {
                        id: edtAgeM
                        property string fieldName: "AgeM="
                        width: 30
                        leftPadding: 4
                        rightPadding: 4
                        height: layBaseEditor.txtHeight
                        font.pixelSize: layBaseEditor.txtFontSize
                        Material.foreground: Themer.theme.editorFontColor
                    }
                    Label {
                        id: lblAgeM
                        height: layBaseEditor.txtHeight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: qsTr("Home.AgeM") + translater.change
                        font.pixelSize: layBaseEditor.lblFontSize
                        Material.foreground: Themer.theme.editorFontColor
                    }
                    TextField {
                        id: edtAgeD
                        property string fieldName: "AgeD="
                        width: 30
                        leftPadding: 4
                        rightPadding: 4
                        implicitHeight: layBaseEditor.txtHeight
                        font.pixelSize: layBaseEditor.txtFontSize
                        Material.foreground: Themer.theme.editorFontColor
                    }
                    Label {
                        id: lblAgeD
                        height: layBaseEditor.txtHeight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: qsTr("Home.AgeD") + translater.change
                        font.pixelSize: layBaseEditor.lblFontSize
                        Material.foreground: Themer.theme.editorFontColor
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.MRN") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                TextField {
                    id: edtMedicalRecordNo
                    property string fieldName: "MRN="
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.Dept") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    background: createMouse(this, cmbFromDept)
                }
                ComboBox {
                    id: cmbFromDept
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Dept="
                    property int dictType: DataDict.Dept
                    onDownChanged: {
                        if (popup.visible)
                            model = dataDict.getValues(dictType);
                    }
                    model: dataDict.getValues(dictType)
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.Doctor") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    background: createMouse(this, cmbDoctor)
                }
                ComboBox {
                    id: cmbDoctor
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Doctor="
                    property int dictType: DataDict.Doctor
                    onDownChanged: {
                        if (popup.visible)
                            model = dataDict.getValues(dictType);
                    }
                    model: dataDict.getValues(dictType)
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.Tester") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                ComboBox {
                    id: cmbTester
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Tester="
                    onDownChanged: {
                        if (popup.visible)
                            model = getUsers();
                    }
                    model: getUsers()
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.SpecimenType") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    background: createMouse(this, cmbSpecimenType)
                }
                ComboBox {
                    id: cmbSpecimenType
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "SpecimenType="
                    property int dictType: DataDict.SpecimenType
                    onDownChanged: {
                        if (popup.visible)
                            model = dataDict.getValues(dictType);
                    }
                    model: dataDict.getValues(dictType)
                }
                Label {
                    id: lblDateFrom
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Search.FromDate") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                DateField {
                    id: cmbDateFrom
                    property string lblTitle: lblDateFrom.text
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    editText: ""
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    popupX: x - (popup.width - width) + 8
                    popupY: y - popup.height
                    property string fieldName: "ReceivedTime>="
                }
                Label {
                    id: lblDateTo
                    Layout.fillWidth: true
                    Layout.preferredHeight: layBaseEditor.lblHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Search.ToDate") + translater.change
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.theme.editorFontColor
                }
                DateField {
                    id: edtDateTo
                    property string lblTitle: lblDateTo.text
                    Layout.preferredWidth: layBaseEditor.txtWidth
                    Layout.preferredHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.theme.editorFontColor
                    popupX: x - (popup.width - width) + 8
                    popupY: y - popup.height
                    property string fieldName: "ReceivedTime<="
                }
            }

            GridLayout {
                id: layButtons
                anchors.top: layBaseEditor.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                height: 154
                columns: 2
                rowSpacing: 0
                columnSpacing: 0
                property int btnWidth: 136
                property int btnHeight: 48
                property int btnFontSize: layBaseEditor.lblFontSize

                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.OpenReport") + translater.change
                    Material.background: "white"
                    Material.foreground: "#535353"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    onClicked: loadReport()
                }
                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.StartSearch") + translater.change
                    Material.background: "#0075FF"
                    Material.foreground: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    onClicked: searchPatients()
                }
                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.DbBackup") + translater.change
                    Material.background: "white"
                    Material.foreground: "#535353"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    onClicked: {
                        fileDialog.exporting = false;
                        fileDialog.currentFile = "";
                        fileDialog.fileMode = FileDialog.SaveFile;
                        fileDialog.nameFilters = [qsTr("Search.FileType") + " (*.bak)"];
                        fileDialog.open();
                    }
                }
                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.DbRecovery") + translater.change
                    Material.background: "white"
                    Material.foreground: "#535353"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    onClicked: {
                        fileDialog.exporting = false;
                        fileDialog.currentFile = "";
                        fileDialog.fileMode = FileDialog.OpenFile;
                        fileDialog.nameFilters = [qsTr("Search.FileType") + " (*.bak)"];
                        fileDialog.open();
                    }
                }
                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.ImportExcel") + translater.change
                    Material.background: "white"
                    Material.foreground: "#535353"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    onClicked: {
                        if (tableview.rows === 0) {
                            snackMessage("Search.NullExportData");
                            return;
                        }

                        layExport.visible = true;
                    }
                }
                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.Delete") + translater.change
                    Material.background: checked ? (Themer.theme.buttonCheckedBackground) : (Themer.theme.buttonBackground)
                    Material.foreground: "#535353"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    checkable: true
                    onClicked: {
                        if (tableview.verHeaderWidth === 0) {
                            tableview.verHeaderWidth = 30;
                        } else {
                            deleteData();
                            tableview.verHeaderWidth = 0;
                        }
                    }
                }

                RoundButton {
                    radius: 4
                    font.pixelSize: layButtons.btnFontSize
                    text: qsTr("Search.Close") + translater.change
                    Material.background: "white"
                    Material.foreground: "#535353"
                    Layout.fillWidth: true
                    Layout.preferredHeight: layButtons.btnHeight
                    onClicked: {
                        root.visible = false;
                    }
                }
            }

            Label {
                id: lblRecordNum
                anchors.top: layButtons.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 48
                property string info: qsTr("Search.RecordNum") + translater.change
                text: info.replace("%1", 0).replace("%2", 0)
            }
        }

        Rectangle {
            id: middleLine
            width: 1
            color: Themer.theme.lineColor
            anchors.left: leftBar.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
        }

        Item {
            id: rightBar
            anchors.top: parent.top
            anchors.left: middleLine.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 18
            width: 210

            Label {
                id: lblRightTitle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.bold: true
                text: qsTr("Search.SearchResult") + translater.change
                background: Rectangle {
                    height: 1
                    color: Themer.theme.lineColor
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -4
                }
            }

            HulaTableView {
                id: tableview
                anchors.left: parent.left
                anchors.right: layExport.visible ? layExport.left : parent.right
                anchors.top: lblRightTitle.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 1
                anchors.rightMargin: layExport.visible ? 8 : 0
                anchors.topMargin: 20
                anchors.bottomMargin: 12
                alternatingRows: true
                rowHeight: 40
                color: "transparent"
                headerColor: "white"
                headerGradient: Themer.theme.titleBarGradient
                editTriggers: TableView.NoEditTriggers
                columnBorderWidth: 0
                rowBorderWidth: 1
                border.width: 1
                verHeaderWidth: 0
                useCheckBox: true

                //selectionMode: TableView.ExtendedSelection
                //model: TableModel {}
                columnsWidth: [0, 120, 120, 120, 80, 80]
                headerTitles: ["Id", "Home.TestId", "Home.Name", "Home.Sex", "Home.Age", "Home.MRN"]
                property var fieldNames: ["Id", "TestId", "Name", "Sex", "Age", "MRN"]
                model: TableModel {
                    TableModelColumn {
                        display: tableview.fieldNames[0]
                    }
                    TableModelColumn {
                        display: tableview.fieldNames[1]
                    }
                    TableModelColumn {
                        display: tableview.fieldNames[2]
                    }
                    TableModelColumn {
                        display: tableview.fieldNames[3]
                    }
                    TableModelColumn {
                        display: tableview.fieldNames[4]
                    }
                    TableModelColumn {
                        display: tableview.fieldNames[5]
                    }
                }

                onCurrentRowChanged: {
                    lblRecordNum.text = lblRecordNum.info.replace("%1", currentRow + 1).replace("%2", rows);
                    getPatientData();
                }
                onCellDoubleClicked: loadReport()
            }

            Item {
                id: layExport
                anchors.right: parent.right
                anchors.top: tableview.top
                anchors.bottom: parent.bottom
                width: 340
                clip: true
                visible: false
                Label {
                    id: lblExport
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    text: qsTr("Search.SelectExportInfo") + translater.change
                }
                Flow {
                    id: layExportInfo
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: lblExport.bottom
                    anchors.bottom: layExportBottom.top
                    clip: true
                    flow: Flow.TopToBottom
                    property var fields: []
                }
                Row {
                    id: layExportBottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: layButtons.btnHeight + 8
                    clip: true
                    RoundButton {
                        radius: 4
                        font.pixelSize: layButtons.btnFontSize
                        text: qsTr("Search.StartExport") + translater.change
                        Material.background: "white"
                        Material.foreground: "#535353"
                        implicitWidth: layButtons.btnWidth
                        implicitHeight: layButtons.btnHeight
                        onClicked: {
                            layExportInfo.fields = [];
                            var childs = layExportInfo.children;
                            for (var i = 0; i < childs.length; i++) {
                                var child = childs[i];
                                if (typeof child.fieldName === 'undefined')
                                    continue;
                                if (String(child).indexOf("CheckBox") === -1)
                                    continue;
                                if (child.checked) {
                                    layExportInfo.fields.push(child.fieldName);
                                    child.checked = false;
                                }
                            }
                            if (layExportInfo.fields.length === 0) {
                                snackMessage("Search.NullExportField");
                                return;
                            }

                            layExport.visible = false;
                            fileDialog.currentFile = "";
                            fileDialog.exporting = true;
                            fileDialog.fileMode = FileDialog.SaveFile;
                            fileDialog.nameFilters = ["Execl (*.xlsx)"];
                            fileDialog.open();
                        }
                    }

                    RoundButton {
                        radius: 4
                        font.pixelSize: layButtons.btnFontSize
                        text: qsTr("Search.SelectAll") + translater.change
                        Material.background: "white"
                        Material.foreground: "#535353"
                        implicitWidth: layButtons.btnWidth
                        implicitHeight: layButtons.btnHeight
                        onClicked: {
                            var childs = layExportInfo.children;
                            for (var i = 0; i < childs.length; i++) {
                                var child = childs[i];
                                if (typeof child.fieldName === 'undefined')
                                    continue;
                                if (String(child).indexOf("CheckBox") !== -1) {
                                    child.checked = true;
                                }
                            }
                        }
                    }

                    RoundButton {
                        radius: 4
                        font.pixelSize: layButtons.btnFontSize
                        text: qsTr("Search.HideSelectExportInfo") + translater.change
                        Material.background: "white"
                        Material.foreground: "#535353"
                        implicitWidth: layButtons.btnWidth
                        implicitHeight: layButtons.btnHeight
                        onClicked: {
                            layExport.visible = false;
                            var childs = layExportInfo.children;
                            for (var i = 0; i < childs.length; i++) {
                                var child = childs[i];
                                if (typeof child.fieldName === 'undefined')
                                    continue;
                                if (String(child).indexOf("CheckBox") === -1)
                                    continue;
                                if (child.checked) {
                                    child.checked = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function loadExportInfo() {// for (var i = 1; i < tableview.fieldNames.length; i++) {
    //     let obj = comCheckBox.createObject(layExportInfo)
    //     obj.text = qsTr(tableview.headerTitles[i])
    //     obj.fieldName = tableview.fieldNames[i]
    // }
    }

    Component {
        id: comCheckBox
        CheckBox {
            implicitHeight: 30
            property string fieldName: ""
        }
    }

    Component {
        id: comMouse

        Rectangle {
            anchors.left: parent.left
            width: parent.implicitWidth
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            property int dictType: 0
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    loadDictDialog(parent.dictType);
                }
            }
        }
    }

    function createMouse(parentCtr, typeCtrl) {
        var mouseArea = comMouse.createObject(parentCtr);
        mouseArea.dictType = typeCtrl.dictType;
        return mouseArea;
    }

    function searchPatients() {
        var data = {};
        for (var i = 0; i < layBaseEditor.children.length; i++) {
            var child = layBaseEditor.children[i];
            if (typeof child.fieldName === 'undefined')
                continue;
            var value = "";
            if (String(child).indexOf("TextField") !== -1) {
                value = child.text.trim();
                if (value !== "")
                    data[child.fieldName] = value;
            } else if (String(child).indexOf("DateField") !== -1) {
                if (!isDateString(child.editText.trim())) {
                    var info = child.lblTitle + qsTr("Search.DateFormatError");
                    openDialogPrompt(info);
                    return;
                }
                value = child.editText.trim();
                if (value !== "")
                    data[child.fieldName] = value;
            } else if (String(child).indexOf("ComboBox") !== -1) {
                value = child.editText.trim();
                if (value !== "")
                    data[child.fieldName] = value;
            }
            if (typeof child.fieldType !== 'undefined')
                data[child.fieldName + "-Type"] = child.fieldType;
        }
        // var datas = patients.findPatients(data);
        var datas = patients.searchDatas(data);
        viewDatas(datas);
        snackMessage("Search.SearchFinished");
    }

    function viewDatas(datas) {
        tableview.model.clear();
        for (var i = 0; i < datas.length; ++i) {
            tableview.model.appendRow(datas[i]);
        }
        lblRecordNum.text = lblRecordNum.info.replace("%1", 0).replace("%2", datas.length);
    }

    function exportXlsx() {
        var datas = [];
        for (var i = 0; i < tableview.model.rowCount; i++) {
            datas.push(tableview.model.getRow(i));
        }
        var filePath = fileDialog.currentFile.toString().replace("file:///", "");
        filePath = filePath.replace("file:", "");
        var ret = patients.exportXlsx(filePath, datas, layExportInfo.fields);
        if (ret === 0) {
            snackMessage("Search.ExportXlsxValid");
            return;
        }
        snackMessage("Search.ExportXlsxInvalid");
    }

    function deleteData() {
        var indexArr = [];
        var testIdArr = [];
        var pidArr = [];
        for (var i = 0; i < tableview.rows; i++) {
            if (tableview.checkBoxAt(i).checked) {
                tableview.checkBoxAt(i).checked = false;
                let data = tableview.model.getRow(i);
                pidArr.push(String(data["Id"]));
                testIdArr.push(data["TestId"]);
                indexArr.push(i);
            }
        }
        tableview.uncheckAll();
        if (indexArr.length === 0) {
            snackMessage("NullRow");
            return;
        }
        var funcDelete = function () {
            let pids = pidArr.join(",");
            var ret = patients.deletePatients(pids);

            if (ret !== 0) {
                snackMessage("DeleteInvalid");
                return;
            }

            let imagePath = configer.imagePath();
            for (var i = indexArr.length - 1; i >= 0; i--) {
                tableview.model.removeRow(indexArr[i], 1);
                patients.deleteDir(imagePath + "/" + testIdArr[i]);
            }
            snackMessage("DeleteValid");
        };

        openDialogConfirm("ConfirmDelete", funcDelete);
    }

    function clearEditor() {
        for (var i = 0; i < layBaseEditor.children.length; i++) {
            var child = layBaseEditor.children[i];
            if (typeof child.fieldName === 'undefined')
                continue;
            if (String(child).indexOf("TextField") !== -1) {
                child.text = "";
            } else if (String(child).indexOf("DateField") !== -1) {
                child.editText = child.currDateString();
            } else if (String(child).indexOf("ComboBox") !== -1) {
                child.editText = "";
            }
        }
    }

    function getPatientData() {
        if (tableview.currentRow < 0)
            return {};
        root.patientData = tableview.model.getRow(tableview.currentRow);
        return root.patientData;
    }

    function refreshPatientData(data) {
        if (tableview.currentRow < 0)
            return;
        root.patientData = data;
        tableview.model.setRow(tableview.currentRow, root.patientData);
    }

    function loadReport() {
        if (tableview.currentRow < 0) {
            snackMessage("NullRow");
            return;
        }

        root.patientData = tableview.model.getRow(tableview.currentRow);
        openReport(root.patientData["ReportNo"], root.patientData);
    }

    function backupDb() {
        var filePath = fileDialog.currentFile.toString().replace("file:///", "");
        filePath = filePath.replace("file:", "");
        // var datas = []
        // for (var i = 0; i < tableview.model.rowCount; i++) {
        //     datas.push(tableview.model.getRow(i))
        // }
        // var ret = patients.backupDb(filePath, datas)
        var ret = hdbm.backupDb(filePath);
        if (!ret)
            snackMessage("Search.BackupDbValid");
        else
            snackMessage("Search.BackupDbInvalid");
    }

    function recoverDb() {
        var filePath = fileDialog.currentFile.toString().replace("file:///", "");
        filePath = filePath.replace("file:", "");
        //var ret = patients.recoverDb(filePath)
        var ret = hdbm.recoverDb(filePath);
        if (ret === 0) {
            searchPatients();
            snackMessage("Search.RecoverDbValid");
        } else {
            snackMessage("Search.RecoverDbInvalid");
        }
    }
}
