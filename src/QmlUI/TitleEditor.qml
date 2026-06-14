import QtQuick
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import QtQuick.Dialogs
import "../HulaUI"
import DataDict 1.0

HulaDialog {
    id: root
    width: 540
    height: 200
    property int dictType: 0
    property string lblTitle: (dictType === DictType.ReportName) ? "TitleEditor.ReportName" : "TitleEditor.ReportHospitalName"
    formTitle: qsTr("TitleEditor.Title") + Translater.change
    property alias editText: edtInfo.text
    property alias fontSize: edtSize.text
    property string fontColor: ""
    property bool edited: false

    // 基础颜色对话框
    ColorDialog {
        id: colorDialog
        title: qsTr("TitleEditor.SelectFontColor") + Translater.change
        selectedColor: fontColor
        onAccepted: {
            fontColor = String(selectedColor)
        }
    }

    RowLayout {
        id: edtBar
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblInfo
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            text: qsTr(lblTitle) + Translater.change
        }
        TextField {
            id: edtInfo
            Layout.fillWidth: true
            implicitHeight: 32
            text: ""
        }
    }

    RowLayout {
        id: edtFontSizeBar
        anchors.top: edtBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        implicitHeight: 40
        spacing: 18
        Label {
            id: lblSize
            height: 40
            width: 80
            verticalAlignment: Text.AlignVCenter
            text: qsTr("TitleEditor.EditFontSize") + Translater.change
        }
        TextField {
            id: edtSize
            Layout.fillWidth: true
            implicitHeight: 32
            text: ""
            inputMethodHints: Qt.ImhDigitsOnly
            onTextEdited: {
                if (!text.match(/^[0-9]*$/)) {
                    text = text.replace(/[^0-9]/g, '')
                }
            }
        }

        RoundButton {
            id: btnOk
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            implicitWidth: 84
            implicitHeight: 40
            text: qsTr("TitleEditor.Ok") + Translater.change
            onClicked: {
                var size = parseInt(edtSize.text.trim())
                if (size > 24) {
                    openDialogPrompt("TitleEditor.FontSizeOver")
                    return
                }

                edited = true
                root.close()
            }
        }
    }

    RowLayout {
        id: buttonBar
        anchors.top: edtFontSizeBar.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 12
        spacing: 8

        RoundButton {
            id: btnFontColor
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            width: 120
            Layout.fillHeight: true
            text: qsTr("TitleEditor.EditFontColor") + Translater.change
            onClicked: {
                colorDialog.open()
            }
        }

        RoundButton {
            id: btnBack
            radius: 4
            Material.background: "white"
            Material.foreground: "#535353"
            implicitWidth: 84
            Layout.fillHeight: true
            text: qsTr("TitleEditor.Back") + Translater.change
            onClicked: {
                edited = false
                root.close()
            }
        }
    }
}
