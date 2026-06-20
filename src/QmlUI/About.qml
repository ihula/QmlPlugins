import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QmlPlugins

HulaDialog {
    id: root
    width: 716
    height: 360
    title: qsTr("About.Title")
    footer.visible: false

    Item {
        anchors.fill: parent
        Image {
            id: imgLogo
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 16
            anchors.topMargin: 0
            width: 240
            source: "file:" + "Images/logo.svg"
            antialiasing: true
            fillMode: Image.PreserveAspectFit
        }

        Column {
            id: infoArea
            spacing: 8
            anchors.top: parent.top
            anchors.left: imgLogo.right
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 16
            anchors.leftMargin: 32
            anchors.topMargin: 0
            Text {
                id: txtSoftware
                text: qsTr("About.SoftName") + ": " + qsTr("AppName")
                font.pixelSize: 20
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: txtVer
                text: qsTr("About.VerName") + ": " + qsTr("About.Ver")

                font.pixelSize: 14
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: txtViewVer
                text: qsTr("About.ReleaseVerName") + ": " + qsTr("About.ReleaseVer")
                font.pixelSize: 14
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                Component.onCompleted: {
                    for (var i = text.length; i <= txtVer.text.length; i++)
                        text = text + " ";
                    text = text + " ";
                }
            }

            Text {
                id: txtCompany
                text: qsTr("About.Company")
                font.pixelSize: 14
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: txtCopyright
                text: qsTr("About.Copyright")
                font.pixelSize: 14
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }

            TextEdit {
                id: txtInfo
                leftPadding: 0
                wrapMode: Text.WordWrap
                width: parent.width
                readOnly: true
                text: qsTr("About.Declaration")
                font.pixelSize: 14
            }

            Text {
                id: txtWebsite
                text: qsTr("About.Website")
                font.pixelSize: 14
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
        }
        /*
        RoundButton {
            id: btnAdd
            radius: 4
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            text: qsTr("About.Close")
            onClicked: close()
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_A)

                //console.log("A key pressed")
                {} else if (event.key === Qt.Key_Enter) {
                    //console.log("Enter key pressed")
                    close();
                } else if (event.key === Qt.Key_Return) {
                    //console.log("Enter key pressed")
                    close();
                }

                // 打印按键的扫描码和文本字符
                //console.log("Scan code: " + event.nativeScanCode)
                //console.log("Text: " + event.text)
            }
        }*/
    }
}
