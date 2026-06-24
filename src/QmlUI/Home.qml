import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Fusion as Fusion
import QtQuick.Layouts
import "../HulaUI"
import QmlPlugins

Item {
    id: root
    property bool autoDestroy: false
    property var patientData: ({})
    property int patientId: 0
    property var tab: null
    property bool isVisible: visible
    property string model: "value"
    property bool canAccessed: false

    // loader加载组件时,组件不执行onVisibleChanged事件,通过此方法桥接
    onIsVisibleChanged: {
        if (visible) {
            Window.window.appendTopbarLeftItem(tabbar);

            init();
            return;
        }
        Window.window.removeTopbarLeftItem(tabbar);

        if (autoDestroy) {
            if (parent && parent instanceof Loader) {
                parent.active = false;
            }
            destroy();
        }
    }

    onWidthChanged: unifyEditorLabelWidth()

    function init() {
        clearEditor();
        unifyEditorLabelWidth();
    }

    Action {
        id: saveAction
        text: "保存"
        onTriggered: {
            root.canAccessed = true;
            console.log(root.model + " 保存成功！");
        }
    }

    TabBar {
        id: tabbar
        property int preIndex: 0
        font.pixelSize: 18
        TabButton {
            text: "图表显示"
            onClicked: console.log("clicked 1")
        }
        TabButton {
            text: "表格显示"
            onClicked: console.log("clicked 2")
        }
    }

    Rectangle {
        id: itemPatients
        radius: 8
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        width: 280
        color: Themer.workFormColor
        Label {
            id: lblSpecimenList
            anchors.left: parent.left
            anchors.top: parent.top
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            height: layBaseEditor.ctrlHeight
            anchors.margins: 8
            anchors.leftMargin: 18
            text: qsTr("Home.SpecimenList")
            font.pixelSize: layBaseEditor.lblFontSize
            font.bold: false
            Material.foreground: Themer.editorFontColor
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
            CheckBox {
                id: chkAll
                font.pixelSize: 16
                text: qsTr("Home.SelectAll")
                Material.background: "white"
                Material.foreground: "#535353"
                height: 46
                onClicked: {
                    if (checked)
                        chkMulti.checked = false;
                }
            }

            CheckBox {
                id: chkMulti
                font.pixelSize: 16
                text: qsTr("Home.MultiSelect")
                Material.background: "white"
                Material.foreground: "#535353"
                height: 46
                onClicked: {
                    if (checked)
                        chkAll.checked = false;
                }
            }
        }

        ListView {
            id: listview
            clip: true
            property color itemColor: Qt.alpha("#F4F4F4", Window.window.alpha)
            property color highColor: Qt.alpha(Themer.hoveredColor, Window.window.alpha)
            property bool selectAll: chkAll.checked
            property bool selectMulti: chkMulti.checked
            property int spaceing: 2
            anchors.top: btnListBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
            highlight: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: listview.spaceing
                    color: listview.highColor
                    radius: 6
                }
            }

            ScrollBar.vertical: Fusion.ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            model: ListModel {
                id: contactModel
                ListElement {
                    name: "张三"
                    status: "在线"
                }
                ListElement {
                    name: "李四"
                    status: "在线"
                }
                ListElement {
                    name: "王五"
                    status: "在线"
                }
                ListElement {
                    name: "菜狗"
                    status: "离线"
                }
                ListElement {
                    name: "老六"
                    status: "忙碌"
                }
                ListElement {
                    name: "张三"
                    status: "在线"
                }
                ListElement {
                    name: "李四"
                    status: "在线"
                }
                ListElement {
                    name: "王五"
                    status: "在线"
                }
                ListElement {
                    name: "菜狗"
                    status: "离线"
                }
                ListElement {
                    name: "老六"
                    status: "忙碌"
                }
                ListElement {
                    name: "张三"
                    status: "在线"
                }
                ListElement {
                    name: "李四"
                    status: "在线"
                }
                ListElement {
                    name: "王五"
                    status: "在线"
                }
                ListElement {
                    name: "菜狗"
                    status: "离线"
                }
                ListElement {
                    name: "老六"
                    status: "忙碌"
                }
            }

            delegate: ItemDelegate {
                id: item
                required property int index
                required property string name
                required property string status
                width: ListView.view.width
                height: 80
                property color backColor: ListView.isCurrentItem ? listview.highColor : listview.itemColor
                property color textColor: ListView.isCurrentItem ? "white" : "black"
                contentItem: Rectangle {
                    radius: 6
                    anchors.fill: parent
                    anchors.margins: listview.spaceing
                    color: item.backColor
                    CheckBox {
                        id: checkbox
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: listview.selectAll || listview.selectMulti
                        checked: listview.selectAll
                    }
                    Column {
                        anchors.fill: parent
                        anchors.margins: 4
                        anchors.leftMargin: checkbox.visible ? checkbox.width : 4
                        Text {
                            color: item.textColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: 'Name: ' + ((typeof item.name !== "undefined") ? item.name : "")
                            height: parent.height / 2
                            font.pixelSize: 16
                        }
                        Text {
                            color: item.textColor
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            text: "Status: " + ((typeof item.status !== "undefined") ? item.status : "")
                            height: parent.height / 2
                            font.pixelSize: 16
                        }
                    }
                }
                MouseArea {
                    enabled: !(listview.selectAll || listview.selectMulti)
                    anchors.fill: parent
                    onClicked: {
                        listview.currentIndex = index;
                    }
                }
            }
        }
    }

    Rectangle {
        id: rectInfo
        radius: 8
        anchors.left: itemPatients.right
        anchors.right: itemHint.left
        anchors.top: itemPatients.top
        anchors.bottom: itemPatients.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: (itemHint.width === 0) ? 0 : 8
        anchors.topMargin: 0
        color: Qt.alpha(Themer.workFormColor, Window.window.alpha)
        clip: true

        Label {
            id: lblSpecimenInfo
            anchors.left: parent.left
            anchors.top: parent.top
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            height: layBaseEditor.ctrlHeight
            anchors.margins: 8
            anchors.leftMargin: 18
            text: qsTr("Home.SpecimenInfo")
            font.pixelSize: layBaseEditor.lblFontSize
            font.bold: false
            Material.foreground: Themer.editorFontColor
        }

        Row {
            id: btnInfoBar
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            spacing: 8
            RoundButton {
                radius: 4
                font.pixelSize: layBaseEditor.txtFontSize
                text: qsTr("Home.Add")
                Material.background: "white"
                Material.foreground: "#535353"
                width: 106
                height: 46
                onClicked: {
                    if (!root.canAccessed)
                        return;
                    console.log("clicked");
                }
                action: saveAction
            }

            RoundButton {
                radius: 4
                font.pixelSize: layBaseEditor.txtFontSize
                text: qsTr("Home.Save")
                Material.background: "white"
                Material.foreground: "#535353"
                width: 106
                height: 46
                onClicked: {
                    if (savePatientInfo() !== 0)
                        return;
                    openCapture(root.patientData, true);
                    root.visible = false;
                }
            }
            RoundButton {
                radius: 4
                font.pixelSize: layBaseEditor.txtFontSize
                text: qsTr("Home.Delete")
                Material.background: "white"
                Material.foreground: "#535353"
                width: 106
                height: 46
                checkable: true
                onCheckedChanged: {
                    rectInfo.detailInfo = checked;
                }
            }
        }

        Rectangle {
            id: lineSpecimenInfo
            anchors.top: lblSpecimenInfo.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            color: Themer.lineColor
        }

        Flow {
            id: layBaseEditor
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: lineSpecimenInfo.bottom
            anchors.topMargin: 8
            height: 200
            flow: Flow.LeftToRight
            spacing: 8
            property int lblWidth: 88
            property int txtWidth: 138
            property int ctrlHeight: 36
            property int lblFontSize: 18
            property int txtFontSize: 16

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.SpecimenId")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }

                TextField {
                    id: edtSpecimenId
                    property string fieldName: "SpecimenId"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    text: ""
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    placeholderText: "标本编号"
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Name")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }

                TextField {
                    id: edtName
                    property string fieldName: "Name"
                    property bool hasEdited: false
                    property string oldText: {
                        if (!hasEdited)
                            oldText = text;
                    }
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    text: "ddd"
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: hasEdited ? Themer.editedFontColor : Themer.editorFontColor
                    onTextChanged: {
                        if (oldText === text) {
                            hasEdited = false;
                            return;
                        }

                        if (text !== "") {
                            hasEdited = true;
                        }
                    }
                }
            }

            Row {
                spacing: 2
                Label {
                    id: lblAge
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Age")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }

                TextField {
                    id: edtAgeY
                    property string fieldName: "AgeY"
                    property string txtY: qsTr("Home.AgeY")
                    property string txtM: qsTr("Home.AgeM")
                    property string txtD: qsTr("Home.AgeD")
                    property string ageD: (txtD.toUpperCase() === "D") ? ("\\" + txtD) : txtD
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    inputMask: "999" + txtY + "99" + txtM + "99" + ageD //"999y99m99\\d"
                    //onDisplayTextChanged: console.log(text)
                }
            }

            Row {
                spacing: 2
                Label {
                    id: lblSex
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Sex")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                    background: createMouse(this, cmbSex)
                }
                ComboBox {
                    id: cmbSex
                    //property int dictType: DictType.Sex
                    property string fieldName: "Sex"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    // onDownChanged: {
                    //     if (popup.visible)
                    //         model = dataDict.getValues(dictType)
                    // }
                    // model: dataDict.getValues(dictType)
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.OutpatientNo")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtOutpatientNo
                    property string fieldName: "OutpatientNo"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.MRN")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtMRN
                    property string fieldName: "MRN"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                }
            }

            Row {
                spacing: 2

                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Dept")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                    background: createMouse(this, cmbFromDept)
                }
                ComboBox {
                    id: cmbFromDept
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Dept"
                    // property int dictType: DictType.Dept
                    // onDownChanged: {
                    //     if (popup.visible)
                    //         model = dataDict.getValues(dictType)
                    // }
                    // model: dataDict.getValues(dictType)
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Doctor")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                    background: createMouse(this, cmbDoctor)
                }
                ComboBox {
                    id: cmbDoctor
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Doctor"
                    // property int dictType: DictType.Doctor
                    // onDownChanged: {
                    //     if (popup.visible)
                    //         model = dataDict.getValues(dictType)
                    // }
                    // model: dataDict.getValues(dictType)
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.InpatientNo")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtInpatientNo
                    property string fieldName: "InpatientNo"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Tester")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                ComboBox {
                    id: cmbTester
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Tester"
                    onDownChanged: {
                        if (popup.visible)
                            model = getUsers();
                    }
                    //model: getUsers()
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Reviewer")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                ComboBox {
                    id: cmbReviewer
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Reviewer"
                    onDownChanged: {
                        if (popup.visible)
                            model = getUsers();
                    }
                    //model: getUsers()
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Bed")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtBed
                    property string fieldName: "Bed"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.SpecimenType")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                    background: createMouse(this, cmbSpecimenType)
                }
                ComboBox {
                    id: cmbSpecimenType
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "SpecimenType"
                    // property int dictType: DictType.SpecimenType
                    // onDownChanged: {
                    //     if (popup.visible)
                    //         model = dataDict.getValues(dictType)
                    // }
                    // model: dataDict.getValues(dictType)
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.SpecimenQuality")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                    background: createMouse(this, cmbSpecimenQuality)
                }
                ComboBox {
                    id: cmbSpecimenQuality
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "SpecimenQuality"
                    // property int dictType: DictType.SpecimenQuality
                    // onDownChanged: {
                    //     if (popup.visible)
                    //         model = dataDict.getValues(dictType)
                    // }
                    // model: dataDict.getValues(dictType)
                }
            }

            Row {
                spacing: 2
                Label {
                    id: lblCollectionTime
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.CollectionTime")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                DateField {
                    id: cmbCollectionTime
                    property string lblTitle: lblCollectionTime.text
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    popupX: x - (popup.width - width)
                    popupY: height + y
                    property string fieldName: "CollectionTime"
                    property string weekDayNames: qsTr("WeekDayNames")
                    dayNames: weekDayNames.split(",")
                }
            }

            Row {
                spacing: 2
                Label {
                    id: lblReportDate
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.ReportDate")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                DateField {
                    id: cmbReportDate
                    property string lblTitle: lblReportDate.text
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    popupX: x - (popup.width - width)
                    popupY: height + y
                    property string fieldName: "ReportDate"
                    property string weekDayNames: qsTr("WeekDayNames")
                    dayNames: weekDayNames.split(",")
                    dateFormat: "yyyy-MM-dd"
                }
            }

            Row {
                spacing: 2
                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.Diagnosis")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                    background: createMouse(this, cmbDiagnosis)
                }
                ComboBox {
                    id: cmbDiagnosis
                    width: layBaseEditor.txtWidth * 3
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    currentIndex: -1
                    selectTextByMouse: true
                    editable: true
                    property string fieldName: "Diagnosis"
                    // property int dictType: DictType.Diagnosis
                    // onDownChanged: {
                    //     if (popup.visible)
                    //         model = dataDict.getValues(dictType)
                    // }
                    // model: dataDict.getValues(dictType)
                }

                Label {
                    height: layBaseEditor.ctrlHeight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: qsTr("Home.TestId")
                    font.pixelSize: layBaseEditor.lblFontSize
                    Material.foreground: Themer.editorFontColor
                }
                TextField {
                    id: edtTestId
                    property string fieldName: "TestId"
                    width: layBaseEditor.txtWidth
                    height: layBaseEditor.ctrlHeight
                    font.pixelSize: layBaseEditor.txtFontSize
                    Material.foreground: Themer.editorFontColor
                    readOnly: true
                }
            }

            HulaTextField {
                width: layBaseEditor.txtWidth
                height: layBaseEditor.ctrlHeight
                font.pixelSize: layBaseEditor.txtFontSize
            }
        }
    }

    Item {
        id: itemHint
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        width: 0
    }

    Component {
        id: comMouse

        Rectangle {
            color: "transparent"
            anchors.fill: parent
            property int dictType: 0
            MouseArea {
                anchors.fill: parent
                onClicked:
                //loadDictDialog(parent.dictType)
                {}
            }
        }
    }

    function createMouse(parentCtr, typeCtrl) {
        var mouseArea = comMouse.createObject(parentCtr);
        //mouseArea.dictType = typeCtrl.dictType
        return mouseArea;
    }

    function savePatientInfo() {
        if (edtTestId.text.trim() === "") {
            openDialogPrompt("Home.TestIdDontEmpty");
            return 1;
        }

        var ret = getPatientData();
        if (ret !== 0)
            return 1;

        var id = strToInt(root.patientData["Id"]);
        if (id === 0) {
            ret = patientInfo.appendPatient(root.patientData);
            if (ret === 0) {
                snackMessage("AppendInvalid");
                return 1;
            }
            root.patientData["Id"] = ret;
            snackMessage("AppendValid");
        } else {
            ret = patientInfo.updatePatient(root.patientData);
            if (ret !== 0) {
                snackMessage("UpdateInvalid");
                return 1;
            }
            snackMessage("UpdateValid");
        }
        root.patientId = strToInt(root.patientData["Id"]);
        root.patientData = patientInfo.findPatient(root.patientData["Id"]);
        // reportSelect.patientId = String(root.patientId)
        // reportSelect.open()
        return 0;
    }

    function unifyEditorLabelWidth() {
        var rowWidth = 0;
        var w = 0;
        var labels = [];
        var editors = [];
        for (var i = 0; i < layBaseEditor.children.length; i++) {
            let row = layBaseEditor.children[i];
            if (String(row).indexOf("Row") === -1)
                continue;
            for (var j = 0; j < row.children.length; j++) {
                let child = row.children[j];
                if (String(child).indexOf("Label") !== -1) {
                    labels.push(child);
                    if (child.width > w) {
                        w = child.width;
                        rowWidth = row.width;
                    }
                } else {
                    editors.push(child);
                }
            }
        }

        rowWidth = parseInt(rowWidth) + 12;
        let remain = parseInt(layBaseEditor.width % rowWidth);
        let cols = parseInt(layBaseEditor.width / rowWidth);
        //console.log(10, cols, remain, layBaseEditor.width, rowWidth)
        if (remain >= (rowWidth / 2)) {
            layBaseEditor.txtWidth = 138 - (rowWidth - remain) / (cols + 1);
            // for (i = 0; i < editors.length; i++) {
            //     editors[i].width = txtWidth
            // }
            //console.log(11, cols, remain, layBaseEditor.width, rowWidth)
        } else {
            layBaseEditor.txtWidth = 138 + (rowWidth - remain) / cols;
            // for (i = 0; i < editors.length; i++) {
            //     editors[i].width = txtWidth
            // }
            // console.log(12, cols, remain, layBaseEditor.width, rowWidth,
            //             layBaseEditor.txtWidth, txtWidth)
        }

        for (i = 0; i < labels.length; i++) {
            if (labels[i].width < w)
                labels[i].width = w;
        }
        layBaseEditor.forceLayout();
    }

    function clearEditor() {
        for (var i = 0; i < layBaseEditor.children.length; i++) {
            var child = layBaseEditor.children[i];
            if (typeof child.fieldName === 'undefined')
                continue;
            child.font.bold = false;
            if (String(child).indexOf("TextField") !== -1) {
                child.text = "";
            } else if (String(child).indexOf("DateField") !== -1) {
                child.editText = child.dateString();
            } else if (String(child).indexOf("ComboBox") !== -1) {
                child.editText = "";
            }
        }
        //edtTestId.text = patientInfo.getNextTestId()
        var imagePath = Configer.imagePath() + "/" + edtTestId.text;
    //patientInfo.deleteDir(imagePath)
    }

    function getPatientData() {
        for (var i = 0; i < layBaseEditor.children.length; i++) {
            var child = layBaseEditor.children[i];
            if (typeof child.fieldName === 'undefined')
                continue;
            if (String(child).indexOf("TextField") !== -1) {
                root.patientData[child.fieldName] = child.text.trim();
            } else if (String(child).indexOf("DateField") !== -1) {
                if (!isDateString(child.editText.trim())) {
                    var info = child.lblTitle + qsTr("Home.DateFormatError");
                    openDialogPrompt(info);
                    return 1;
                }
                root.patientData[child.fieldName] = child.editText.trim();
            } else if (String(child).indexOf("ComboBox") !== -1) {
                root.patientData[child.fieldName] = child.editText.trim();
            }
        }

        root.patientData["ReportDate"] = cmbFromDate.dateString();
        return 0;
    }

    function refreshPatientData(data) {
        clearEditor();

        root.patientData = data;
        for (var i = 0; i < layBaseEditor.children.length; i++) {
            var child = layBaseEditor.children[i];
            if (typeof child.fieldName === 'undefined')
                continue;
            if (String(child).indexOf("TextField") !== -1) {
                child.text = root.patientData[child.fieldName];
            } else if (String(child).indexOf("DateField") !== -1) {
                child.editText = root.patientData[child.fieldName];
            } else if (String(child).indexOf("ComboBox") !== -1) {
                child.editText = root.patientData[child.fieldName];
            }
        }
    }
}
