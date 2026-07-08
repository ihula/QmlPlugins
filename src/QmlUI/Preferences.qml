import QtQuick
import QtQuick.Controls.Material
import QtQuick.Dialogs
import Qt.labs.qmlmodels
import QtQuick.Layouts
import HulaPlugins
import "../Components"

Item {
    id: root
    property bool isVisible: visible

    anchors.fill: parent

    function init() {
        cmbLang.currentIndex = -1;
        var modeList = [];
        modeList.push(qsTr("Preferences.NormalMode"));
        modeList.push(qsTr("Preferences.MaxMode"));
        modeList.push(qsTr("Preferences.FullScreenMode"));
        cmbFormMode.model = modeList;

        cmbLang.currentIndex = -1;
        var currLang = Configer.language();
        var langList = Translater.languages;
        cmbLang.model = langList;
        for (var i = 0; i < langList.length; i++) {
            if (currLang === langList[i]) {
                cmbLang.currentIndex = i;
                break;
            }
        }

        ckbUseWallPaper.checked = Configer.useWallPaper();
        ckbLiveWallPaper.checked = Configer.liveWallPaper();

        cmbReport.currentIndex = -1;

        var fontName = Configer.fontName();
        if (fontName !== "")
            edtFont.text = fontName;
        sedtFont.value = Configer.fontSize();
    }

    Component.onCompleted: init()

    onIsVisibleChanged: {}

    FontDialog {
        id: fontDialog
        title: qsTr("Preferences.SelectFont")
        currentFont: edtFont.font
        onAccepted: {
            edtFont.font = currentFont;
            edtFont.text = currentFont.family;
            sedtFont.value = currentFont.pixelSize;
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: 0
        clip: true
        ScrollBar.vertical: CustomScrollBar {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        }

        ColumnLayout {
            id: barSetting
            width: scrollView.availableWidth
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: barRate.implicitHeight + 20
                color: Themer.workFormColor
                radius: 8

                ColumnLayout {
                    id: barRate
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 4

                    Label {
                        id: lblFont
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize
                        font.weight: Font.Medium
                        text: qsTr("Preferences.SelectFont")
                    }

                    Label {
                        id: lblFontDelta
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize - 2
                        text: qsTr("Preferences.SelectFontSpec")
                    }

                    TextField {
                        id: edtFont
                        // Layout.fillWidth: true
                        // 让宽度跟随内容自适应
                        implicitWidth: contentWidth + leftPadding + rightPadding
                        // 建议设置一个最小宽度，防止没有内容时输入框缩得太小
                        Layout.minimumWidth: 200
                        // 建议设置一个最大宽度，防止文本过长时撑破父级布局
                        Layout.maximumWidth: parent.width - 80
                        verticalAlignment: Text.AlignVCenter
                        Layout.preferredHeight: contentHeight + topPadding + bottomPadding
                        readOnly: true
                        font.pixelSize: Themer.editorFontSize
                        text: qsTr("Preferences.DbClickSelectFont")
                        MouseArea {
                            anchors.fill: parent
                            onDoubleClicked: {
                                fontDialog.open();
                            }
                        }
                    }

                    SpinBox {
                        id: sedtFont
                        Layout.preferredHeight: Themer.editorHeight
                        onValueChanged: {
                            edtFont.font.pixelSize = value;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: langLayout.implicitHeight + 20
                color: Themer.workFormColor
                radius: 8
                ColumnLayout {
                    id: langLayout
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 4

                    Label {
                        id: lblLang
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize
                        font.weight: Font.Medium
                        text: qsTr("Preferences.SelectLang")
                    }

                    Label {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize - 2
                        text: qsTr("Preferences.SelectLangSpec")
                    }

                    ComboBox {
                        id: cmbLang
                        //Layout.fillWidth: true
                        implicitContentWidthPolicy: ComboBox.WidestText
                        Layout.preferredHeight: Themer.editorHeight
                        editable: false
                        font.pixelSize: Themer.editorFontSize
                        onEditTextChanged: {
                            if (cmbLang.currentText !== "") {
                                if (Translater.currentLang !== cmbLang.editText.trim())
                                    Translater.setLanguage(cmbLang.editText);
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: reportLayout.implicitHeight + 20
                color: Themer.workFormColor
                radius: 8

                ColumnLayout {
                    id: reportLayout
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 4

                    Label {
                        id: lblReport
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize
                        font.weight: Font.Medium
                        text: qsTr("Preferences.SelectReport")
                    }

                    Label {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize - 2
                        text: qsTr("Preferences.SelectReportSpec")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ComboBox {
                            id: cmbReport
                            //Layout.fillWidth: true
                            implicitContentWidthPolicy: ComboBox.WidestText
                            Layout.preferredHeight: Themer.editorHeight
                            font.pixelSize: Themer.editorFontSize
                        }

                        RoundButton {
                            id: btnDesign
                            radius: 4
                            Material.background: "white"
                            Material.foreground: "#535353"
                            Layout.preferredWidth: Themer.buttonWidth
                            Layout.preferredHeight: Themer.buttonHeight
                            font.pixelSize: Themer.buttonFontSize
                            text: qsTr("Preferences.DesignReport")
                            onClicked: {
                                reportPrint.designReport("0", "0", String(cmbReport.currentIndex + 1));
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: langLayout.implicitHeight + 20
                color: Themer.workFormColor
                radius: 8
                ColumnLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 4

                    Label {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize
                        font.weight: Font.Medium
                        text: qsTr("Preferences.FormMode")
                    }

                    Label {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize - 2
                        text: qsTr("Preferences.FormModeSpec")
                    }

                    ComboBox {
                        id: cmbFormMode
                        //Layout.fillWidth: true
                        // 根据列表中最宽的一项来调整宽度
                        implicitContentWidthPolicy: ComboBox.WidestText
                        Layout.preferredHeight: Themer.editorHeight
                        editable: false
                        font.pixelSize: Themer.editorFontSize
                        onEditTextChanged: {
                            if (cmbLang.currentText !== "") {
                                if (Translater.currentLang !== cmbLang.editText.trim())
                                    Translater.setLanguage(cmbLang.editText);
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: wallpaperLayout.implicitHeight + 20
                color: Themer.workFormColor
                radius: 8

                ColumnLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 4

                    Label {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize
                        font.weight: Font.Medium
                        text: qsTr("Preferences.Splash")
                    }

                    CheckBox {
                        id: ckbDisplaySplash
                        Layout.preferredHeight: Themer.editorHeight
                        Layout.fillWidth: true
                        font.pixelSize: Themer.editorFontSize
                        text: qsTr("Preferences.DisplaySplash")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: wallpaperLayout.implicitHeight + 20
                color: Themer.workFormColor
                radius: 8

                ColumnLayout {
                    id: wallpaperLayout
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 4

                    Label {
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Themer.editorFontSize
                        font.weight: Font.Medium
                        text: qsTr("Preferences.WallPaper")
                    }

                    CheckBox {
                        id: ckbUseWallPaper
                        Layout.preferredHeight: Themer.editorHeight
                        Layout.fillWidth: true
                        font.pixelSize: Themer.editorFontSize
                        text: qsTr("Preferences.UseWallPaper")
                    }

                    CheckBox {
                        id: ckbLiveWallPaper
                        Layout.fillWidth: true
                        Layout.preferredHeight: Themer.editorHeight
                        font.pixelSize: Themer.editorFontSize
                        text: qsTr("Preferences.LiveWallPaper")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.topMargin: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: 10
                    spacing: 10

                    RoundButton {
                        id: btnOk
                        radius: 4
                        Material.background: "white"
                        Material.foreground: "#535353"
                        Layout.preferredWidth: Themer.buttonWidth
                        Layout.preferredHeight: Themer.buttonHeight
                        text: qsTr("Preferences.Save")
                        font.pixelSize: Themer.buttonFontSize
                        onClicked: {
                            Configer.setLanguage(cmbLang.editText.trim());
                            Configer.setUseWallPaper(ckbUseWallPaper.checked);
                            Configer.setLiveWallPaper(ckbLiveWallPaper.checked);
                            var fontName = Configer.fontName();
                            if (edtFont.font.family !== fontName) {
                                Configer.setFontName(edtFont.font.family);
                                reportPrint.changFontName();
                            }
                        }
                    }

                    RoundButton {
                        id: btnBack
                        radius: 4
                        Material.background: "white"
                        Material.foreground: "#535353"
                        Layout.preferredWidth: Themer.buttonWidth
                        Layout.preferredHeight: Themer.buttonHeight
                        font.pixelSize: Themer.buttonFontSize
                        text: qsTr("Preferences.Cancel")
                        onClicked: {
                            init();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
