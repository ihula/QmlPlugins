import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

HulaDialog {
    id: root
    width: 336
    height: 90 + lblText.contentHeight + buttonBar.height
    formTitle: qsTr("MessageBox.Confirm") + translater.change
    property alias textPixelSize: lblText.font.pixelSize
    property string messageText: ""
    property string buttonOkText: "MessageBox.Ok"
    property string buttonCancelText: ""
    property var callbackOnCancel: function () {}
    property var callbackOnOK: function () {}
    property color normalColor: "#00000000"
    property color hoveredColor: "#F5F5F5"
    property color pressedColor: "#DCDCDC"
    property bool autoClose: false
    backColor: "white"
    titleBar.visible: false

    TextArea {
        id: lblText
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 0
        anchors.bottomMargin: 10
        font.pixelSize: 18
        text: qsTr(messageText) + translater.change
        wrapMode: TextEdit.WordWrap
        horizontalAlignment: (lineCount > 1) ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        background: Item {
            anchors.fill: parent
            //color: "green"
        }
        readOnly: true
    }

    Row {
        id: buttonBar
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.bottomMargin: 8
        anchors.bottom: parent.bottom
        layoutDirection: Qt.RightToLeft
        height: 45
        spacing: 0
        RoundButton {
            id: btnCancel
            radius: 4
            flat: true
            font.pixelSize: 18
            Material.foreground: "#535353"
            text: qsTr(buttonCancelText) + translater.change
            height: parent.height
            width: 84
            visible: (text !== "")
            onClicked: {
                root.hide()
                if (callbackOnCancel) {
                    callbackOnCancel()
                }
            }
        }
        RoundButton {
            id: btnOk
            radius: 4
            flat: true
            font.pixelSize: 18
            Material.foreground: "#535353"
            Material.background: "#cfcfcf"
            property string title: qsTr(buttonOkText) + translater.change
            text: autoClose ? title + "(" + String(timer.sum) + ")" : title
            height: parent.height
            width: 84
            visible: (text !== "")
            onClicked: {
                root.hide()
                if (callbackOnOK) {
                    callbackOnOK()
                }
            }
        }
    }

    Item {
        id: backItem
        focus: true
        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Enter) {

                                //console.log("Enter key pressed")
                            } else if (event.key === Qt.Key_Return) {
                                btnOk.clicked()
                            }

                            // 打印按键的扫描码和文本字符
                            //console.log("Scan code: " + event.nativeScanCode)
                            //console.log("Text: " + event.text)
                        }
    }

    Timer {
        id: timer
        property int sum: 5
        interval: 1000
        repeat: true
        running: autoClose
        onTriggered: {
            if (root.clicked) {
                timer.stop()
                btnOk.text = btnOk.title
                timer.repeat = false
                return
            }

            sum--
            btnOk.text = btnOk.title + "(" + String(sum) + ")"
            if (sum == 0) {
                btnOk.clicked()
            }
        }
    }
}
