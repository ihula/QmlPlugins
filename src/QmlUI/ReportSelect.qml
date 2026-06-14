import QtQuick
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import "../HulaUI"
import QmlPlugins

HulaDialog {
    id: root
    width: 360
    height: 160
    property string reportNo: ""
    property var callbackOk: function () {}
    x: (mainForm.width - width) / 2
    y: (mainForm.height - height) / 2
    formTitle: qsTr("ReportSelect.Title") + Translater.change

    Label {
        id: lblReportName
        anchors.top: titleBar.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 24
        width: 80
        height: 40
        verticalAlignment: Text.AlignVCenter
        text: qsTr("ReportSelect.SelectReportTemplate") + Translater.change
    }

    ComboBox {
        id: cmbReportName
        anchors.left: lblReportName.left
        anchors.right: btnOk.left
        anchors.top: lblReportName.bottom
        implicitHeight: 32
        onDownChanged: {
            if (popup.visible)
                model = mainForm.getReportNames();
        }
    }

    RoundButton {
        id: btnOk
        anchors.top: cmbReportName.top
        anchors.topMargin: -4
        anchors.right: parent.right
        anchors.rightMargin: 12
        width: 74
        height: 40
        radius: 4
        Material.background: "white"
        Material.foreground: "#535353"
        text: qsTr("Ok") + Translater.change
        onClicked: {
            root.reportNo = String(cmbReportName.currentIndex + 1);
            if (callbackOk)
                callbackOk();
            root.close();
        }
    }
}
