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
    property string formTitle: qsTr("Search.SampleSearch")
    property var patientData: ({})
    property bool isVisible: visible

    DataDict {
        id: dataDict
    }

    onIsVisibleChanged: {
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
    }

    Connections {
        target: loaderReport.item
        function onDataUpdated(patientData) {
            refreshPatientData(patientData);
        }
    }

    FileDialog {
        id: fileDialog
        property bool exporting: false
        fileMode: FileDialog.SaveFile
        title: qsTr("Search.SelectFileSavePath")
        property string filterName: qsTr("Search.FileType")
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
        id: leftBar
        radius: 8
        color: Themer.workFormColor
        border.width: 1
        border.color: Themer.lineColor
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 300
        clip: true

        Label {
            id: lblLeftTitle
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            leftPadding: 8
            height: 36
            font.pixelSize: 14
            font.bold: true
            text: qsTr("Search.Filter")
            background: Rectangle {
                height: 1
                color: Themer.lineColor
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                //anchors.bottomMargin: -4
            }
        }

        GridLayout {
            id: layBaseEditor
            anchors.top: lblLeftTitle.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            height: 480
            columns: 2
            rowSpacing: 0
            property int lblWidth: 88
            property int lblHeight: 36
            property int txtWidth: 158
            property int txtHeight: 32
            property int lblFontSize: 11
            property int txtFontSize: 11

            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: layBaseEditor.lblHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Home.TestId")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
            }
            TextField {
                id: edtTestId
                property string fieldName: "TestId="
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                text: ""
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: layBaseEditor.lblHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Home.Name")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
            }
            TextField {
                id: edtName
                property string fieldName: "Name="
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                text: ""
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: layBaseEditor.lblHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Home.Sex")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
                background: createMouse(this, cmbSex)
            }
            ComboBox {
                id: cmbSex
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
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
                text: qsTr("Home.Age")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
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
                    Material.foreground: Themer.editorFontColor
                }
                Label {
                    id: lblAgeY
                    height: layBaseEditor.txtHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.AgeY")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtAgeM
                    property string fieldName: "AgeM="
                    width: 30
                    leftPadding: 4
                    rightPadding: 4
                    height: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                }
                Label {
                    id: lblAgeM
                    height: layBaseEditor.txtHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.AgeM")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtAgeD
                    property string fieldName: "AgeD="
                    width: 30
                    leftPadding: 4
                    rightPadding: 4
                    implicitHeight: layBaseEditor.txtHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                }
                Label {
                    id: lblAgeD
                    height: layBaseEditor.txtHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: qsTr("Home.AgeD")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: layBaseEditor.lblHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Home.MRN")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
            }
            TextField {
                id: edtMedicalRecordNo
                property string fieldName: "MRN="
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredHeight: layBaseEditor.lblHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                text: qsTr("Home.Dept")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
                background: createMouse(this, cmbFromDept)
            }
            ComboBox {
                id: cmbFromDept
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
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
                text: qsTr("Home.Doctor")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
                background: createMouse(this, cmbDoctor)
            }
            ComboBox {
                id: cmbDoctor
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
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
                text: qsTr("Home.Tester")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
            }
            ComboBox {
                id: cmbTester
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
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
                text: qsTr("Home.SpecimenType")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
                background: createMouse(this, cmbSpecimenType)
            }
            ComboBox {
                id: cmbSpecimenType
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
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
                text: qsTr("Search.FromDate")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
            }
            DateField {
                id: cmbDateFrom
                property string lblTitle: lblDateFrom.text
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                editText: ""
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
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
                text: qsTr("Search.ToDate")
                font.pixelSize: layBaseEditor.lblFontSize
                Material.foreground: Themer.editorFontColor
            }
            DateField {
                id: edtDateTo
                property string lblTitle: lblDateTo.text
                Layout.preferredWidth: layBaseEditor.txtWidth
                Layout.preferredHeight: layBaseEditor.txtHeight
                font.pixelSize: layBaseEditor.txtFontSize
                Material.foreground: Themer.editorFontColor
                popupX: x - (popup.width - width) + 8
                popupY: y - popup.height
                property string fieldName: "ReceivedTime<="
            }
        }

        GridLayout {
            id: layButtons
            anchors.top: layBaseEditor.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
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
                text: qsTr("Search.OpenReport")
                Material.background: "white"
                Material.foreground: "#535353"
                Layout.fillWidth: true
                Layout.preferredHeight: layButtons.btnHeight
                onClicked: {
                    chooser.choices.column = 0;
                    chooser.choices.delegate = c2;
                }
            }
            RoundButton {
                radius: 4
                font.pixelSize: layButtons.btnFontSize
                text: qsTr("Search.StartSearch")
                Material.background: "#0075FF"
                Material.foreground: "white"
                Layout.fillWidth: true
                Layout.preferredHeight: layButtons.btnHeight
                onClicked: searchPatients()
            }
            RoundButton {
                radius: 4
                font.pixelSize: layButtons.btnFontSize
                text: qsTr("Search.DbBackup")
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
                text: qsTr("Search.DbRecovery")
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
                text: qsTr("Search.ImportExcel")
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
                text: qsTr("Search.Delete")
                Material.background: checked ? (Themer.buttonCheckedBackground) : (Themer.buttonBackground)
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
                text: qsTr("Search.Close")
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
            property string info: qsTr("Search.RecordNum")
            text: info.replace("%1", 0).replace("%2", 0)
        }
    }

    Rectangle {
        id: rightBar
        radius: 8
        color: Themer.workFormColor
        border.width: 1
        border.color: Themer.lineColor
        anchors.top: parent.top
        anchors.left: leftBar.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8

        Label {
            id: lblRightTitle
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            leftPadding: 8
            height: 36
            font.pixelSize: 14
            font.bold: true
            text: qsTr("Search.SearchResult")
            background: Rectangle {
                height: 1
                color: Themer.lineColor
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }

        TableView {
            id: tableview
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: lblRightTitle.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 2
            anchors.rightMargin: 0
            anchors.topMargin: 0
            anchors.bottomMargin: 8
            rowSpacing: -1
            columnSpacing: -1
            clip: true

            property color itemBorderColor: "#DCDCDC"
            property color highlightColor: "#0075FF"
            property color rowColor: "white"
            property color alternatingRow: Qt.darker("white", 1.1)
            property color headerColor: "#F5F5F5"
            //列宽
            property variant columnsWidth: [0, 100, 100, 100, 100, 100, 100]
            property variant headerTitles: ["Id", "TestId", "ReceiptDate", "Name", "Sex", "Age", "MRN"]

            selectionBehavior: TableView.SelectRows
            selectionModel: ItemSelectionModel {}

            alternatingRows: true
            editTriggers: TableView.DoubleTapped

            property var fieldNames: ["Id", "TestId", "ReceivedTime", "Name", "Sex", "Age", "MRN"]
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
                TableModelColumn {
                    display: tableview.fieldNames[6]
                }
            }

            delegate: chooser

            /*
            delegate: TableViewDelegate {
                implicitWidth: 100
                implicitHeight: 60

                onDoubleClicked: console.log("double")
                contentItem: Rectangle {
                    anchors.fill: parent
                    color: (row === tableview.currentRow) ? tableview.highlightColor : (tableview.alternatingRows && row % 2 !== 0) ? tableview.alternatingRow : tableview.rowColor
                    Text {
                        id: txt
                        anchors.fill: parent
                        anchors.margins: 2
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        //获取单元格对应的值
                        text: (typeof model.display !== "undefined") ? model.display : ""
                        elide: Text.ElideRight
                    }
                }
            }
            */
            DelegateChooser {
                id: chooser

                DelegateChoice {
                    column: 0
                    delegate: CheckDelegate {
                        implicitHeight: 40
                        checked: model.display
                        onToggled: model.display = checked
                        onClicked: console.log("onClicked", row)
                        onDoubleClicked: console.log("onDoubleClicked", row)
                        background: Rectangle {
                            anchors.fill: parent
                            border.color: "gray"
                            border.width: 1
                            color: (row === tableview.currentRow) ? tableview.highlightColor : (tableview.alternatingRows && row % 2 !== 0) ? tableview.alternatingRow : tableview.rowColor
                        }
                    }
                }

                DelegateChoice {
                    column: 1
                    delegate: SpinBox {
                        implicitHeight: 40
                        value: model.display
                        onValueModified: model.display = value
                        background: Rectangle {
                            anchors.fill: parent
                            border.color: "gray"
                            border.width: 1
                            color: (row === tableview.currentRow) ? tableview.highlightColor : (tableview.alternatingRows && row % 2 !== 0) ? tableview.alternatingRow : tableview.rowColor
                        }
                    }
                }
                DelegateChoice {
                    delegate: comCell
                }
            }

            Component {
                id: comCell
                TableViewDelegate {
                    implicitWidth: 100
                    implicitHeight: 40
                    clip: true
                    contentItem: Rectangle {
                        anchors.fill: parent
                        border.color: "gray"
                        border.width: 1
                        clip: true
                        color: (row === tableview.currentRow) ? tableview.highlightColor : (tableview.alternatingRows && row % 2 !== 0) ? tableview.alternatingRow : tableview.rowColor
                        TextField {
                            anchors.fill: parent
                            text: model.display
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            selectByMouse: true
                            onAccepted: model.display = text
                            background: Item {
                                anchors.fill: parent
                            }
                            onPressed: mouse => {
                                mouse.accepted = false;
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: mouse => {
                                mouse.accepted = false;
                            }
                        }
                    }
                    onClicked: console.log("onClicked", row)
                    onDoubleClicked: console.log("onDoubleClicked", row)
                }
            }
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
        var datas = patientInfo.findPatients(data);
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
        var ret = patientInfo.exportXlsx(filePath, datas, layExportInfo.fields);
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
            var ret = patientInfo.deletePatients(pids);

            if (ret !== 0) {
                snackMessage("DeleteInvalid");
                return;
            }

            let imagePath = configer.imagePath();
            for (var i = indexArr.length - 1; i >= 0; i--) {
                tableview.model.removeRow(indexArr[i], 1);
                patientInfo.deleteDir(imagePath + "/" + testIdArr[i]);
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
        // var ret = patientInfo.backupDb(filePath, datas)
        var ret = hdbm.backupDb(filePath);
        if (!ret)
            snackMessage("Search.BackupDbValid");
        else
            snackMessage("Search.BackupDbInvalid");
    }

    function recoverDb() {
        var filePath = fileDialog.currentFile.toString().replace("file:///", "");
        filePath = filePath.replace("file:", "");
        //var ret = patientInfo.recoverDb(filePath)
        var ret = hdbm.recoverDb(filePath);
        if (ret === 0) {
            searchPatients();
            snackMessage("Search.RecoverDbValid");
        } else {
            snackMessage("Search.RecoverDbInvalid");
        }
    }
}
