import QtQuick
import QtQuick.Controls.Material
import QtQuick.Dialogs
import Qt.labs.qmlmodels
import QtQuick.Layouts
import QmlPlugins

HulaDialog {
    id: root
    width: 400
    height: 410
    property int dictType: 0
    property var devs: []
    property var devsSizes: []
    title: qsTr("Preferences.Title")

    function getDevsSizes() {
        root.devs = [];
        root.devsSizes = [];
        var devNameSizes = camera.enumCameras();
        for (var i = 0; i < devNameSizes.length; i++) {
            var devSizes = devNameSizes[i];
            root.devs.push(devSizes[0]);
            var sizes = [];
            for (var j = 1; j < devSizes.length; j++) {
                sizes.push(devSizes[j]);
            }
            root.devsSizes.push(sizes);
        }
    }

    onShowForm: {
        cmbCamera.currentIndex = -1;
        cmbRate.currentIndex = 0;

        //getDevsSizes()
        cmbCamera.model = root.devs;
        var cameraName = Configer.cameraName();
        for (var i = 0; i < root.devs.length; i++) {
            if (cameraName === root.devs[i]) {
                cmbCamera.currentIndex = i;
                break;
            }
        }

        if (cmbCamera.currentIndex >= 0) {
            var size = Configer.cameraSize();
            var sizes = root.devsSizes[cmbCamera.currentIndex];
            cmbRate.model = sizes;
            for (i = 0; i < sizes.length; i++) {
                if (size === sizes[i]) {
                    cmbRate.currentIndex = i;
                    break;
                }
            }
        }

        cmbLang.currentIndex = -1;
        var currLang = Configer.language();
        var langList = Translater.languages;
        cmbLang.model = langList;
        for (i = 0; i < langList.length; i++) {
            if (currLang === langList[i]) {
                cmbLang.currentIndex = i;
                break;
            }
        }

        ckbUseWallPaper.checked = Configer.useWallPaper();
        ckbLiveWallPaper.checked = Configer.liveWallPaper();

        cmbReport.currentIndex = -1;
        //cmbReport.model = mainForm.getReportNames()

        var fontName = Configer.fontName();
        if (fontName !== "")
            edtFont.text = fontName;
    }

    // FontDialog {
    //     id: fontDialog
    //     title: qsTr("Preferences.SelectFont")
    //     currentFont: edtFont.font
    //     onAccepted: {
    //         edtFont.font.family = currentFont.family
    //         edtFont.text = currentFont.family
    //     }
    // }

    Loader {
        id: fontDialog
        anchors.fill: parent
        focus: true
        active: false
        source: "FontSelector.qml"
        onLoaded: {
            item.open();
        }
    }

    Connections {
        target: fontDialog.item
        function onSelected(font) {
            edtFont.text = font.family;
            edtFont.font.pixelSize = font.pixelSize;
            console.log(font.family, font.pixelSize);
        //Configer.setFontName(font.family)
        //Configer.setFontSize(font.pixelSize)
        }
    }

    RowLayout {
        id: barCamera
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblCamera
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.SelectCamera")
        }
        ComboBox {
            id: cmbCamera
            Layout.fillWidth: true
            implicitHeight: 36
            editable: false
            font.pixelSize: Themer.editorFontSize
            onCurrentTextChanged: {
                if (cmbCamera.currentText !== "") {
                    getDevsSizes();
                    var cameraName = Configer.cameraName();
                    var size = Configer.cameraSize();
                    var devSize = root.devsSizes[cmbCamera.currentIndex];
                    cmbRate.model = devSize;
                    for (var i = 0; i < devSize.length; i++) {
                        if (size === devSize[i]) {
                            cmbRate.currentIndex = i;
                            break;
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        id: barRate
        anchors.top: barCamera.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblRate
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.SelectCameraRate")
        }
        ComboBox {
            id: cmbRate
            Layout.fillWidth: true
            implicitHeight: 36
            editable: false
            font.pixelSize: Themer.editorFontSize
        }
    }

    RowLayout {
        id: barFont
        anchors.top: barRate.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblFont
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.SelectFont")
        }
        TextField {
            id: edtFont
            Layout.fillWidth: true
            implicitHeight: 36
            verticalAlignment: Text.AlignVCenter
            readOnly: true
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.DbClickSelectFont")
            MouseArea {
                anchors.fill: parent
                onDoubleClicked: {
                    fontDialog.active = true;
                }
            }
        }
    }

    RowLayout {
        id: barLang
        anchors.top: barFont.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblLang
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.SelectLang")
        }
        ComboBox {
            id: cmbLang
            Layout.fillWidth: true
            implicitHeight: 36
            editable: true
            font.pixelSize: Themer.editorFontSize
            onEditTextChanged: {
                if (cmbLang.currentText !== "") {
                    if (Translater.currentLang !== cmbLang.editText.trim())
                        Translater.setLanguage(cmbLang.editText);
                }
            }
        }
    }

    RowLayout {
        id: barReport
        anchors.top: barLang.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 6
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblReport
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.SelectReport")
        }
        ComboBox {
            id: cmbReport
            Layout.fillWidth: true
            implicitHeight: 36
            font.pixelSize: Themer.editorFontSize
        }
        RoundButton {
            id: btnDesign
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            implicitWidth: 74
            implicitHeight: 48
            Layout.fillHeight: true
            font.pixelSize: Themer.buttonFontSize
            text: qsTr("Preferences.DesignReport")
            onClicked: {
                reportPrint.designReport("0", "0", String(cmbReport.currentIndex + 1));
            }
        }
    }

    RowLayout {
        id: barWallPaper
        anchors.top: barReport.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 6
        implicitHeight: 40
        spacing: 18
        CheckBox {
            id: ckbUseWallPaper
            implicitHeight: 40
            width: 80
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.UseWallPaper")
        }

        CheckBox {
            id: ckbLiveWallPaper
            implicitHeight: 40
            width: 80
            font.pixelSize: Themer.editorFontSize
            text: qsTr("Preferences.LiveWallPaper")
        }
    }

    RowLayout {
        id: buttonBar
        anchors.top: barWallPaper.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        spacing: 8

        RoundButton {
            id: btnOk
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            implicitWidth: 96
            Layout.fillHeight: true
            text: qsTr("Preferences.Ok")
            font.pixelSize: Themer.buttonFontSize
            onClicked: {
                // Configer.setCameraName(cmbCamera.currentText);
                // Configer.setCameraSize(cmbRate.currentText);
                Configer.setLanguage(cmbLang.editText.trim());
                // Configer.setUseWallPaper(ckbUseWallPaper.checked);
                // Configer.setLiveWallPaper(ckbLiveWallPaper.checked);
                // var fontName = Configer.fontName();
                // if (edtFont.font.family !== fontName) {
                //     Configer.setFontName(edtFont.font.family);
                //     reportPrint.changFontName();
                // }
                root.hide();
            }
        }

        RoundButton {
            id: btnBack
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            implicitWidth: 96
            Layout.fillHeight: true
            font.pixelSize: Themer.buttonFontSize
            text: qsTr("Preferences.Cancel")
            onClicked: {
                root.hide();
            }
        }
    }
}
