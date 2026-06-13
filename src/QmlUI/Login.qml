import QtQuick
import QtQuick.Window
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QmlPlugins 1.0


Window {
    id: root
    property int formShowMode: Configer.loginFormShowMode()
    title: qsTr("Login.Title") + translater.change
    modality: Qt.ApplicationModal
    flags: Qt.Window | Qt.FramelessWindowHint
    width: 1568
    height: 864
    property bool nextFormLoaded: false
    property bool reLogin: false
    property bool unfoundUserId: false
    signal closed

    function showForm() {
        if (root.formShowMode === 1) {
            root.maximumWidth = Screen.desktopAvailableWidth
            root.maximumHeight = Screen.desktopAvailableHeight
        }
        if (formShowMode === 0)
            root.show()
        else if (formShowMode === 1)
            root.showMaximized()
        else
            root.showFullScreen()
    }

    onVisibleChanged: {
        if (visible) {
            loaderSplash.source = ""
            edtUserId.text = ""
            edtUserName.text = ""
            edtUserPwd.text = ""
            main.loaderMain.active = true
        } else {
            closed()
        }
    }

    Binding {
        target: root
        property: "nextFormLoaded"
        value: true
        when: main.loaderMain.item
    }

    UserInfo {
        id: userInfo
    }

    Rectangle {
        color: "white"
        anchors.fill: parent
    }

    Image {
        id: bakImg
        anchors.fill: parent
        anchors.margins: 0
        clip: true
        source: "file:Images/splash.png"
    }

    Rectangle {
        implicitWidth: 1024
        implicitHeight: 680
        anchors.centerIn: parent
        radius: 24
        RectangularGlow {
            id: effect
            anchors.fill: rectBack
            glowRadius: 20
            spread: 0
            color: "#80000000"
        }

        Rectangle {
            id: rectBack
            color: "white"
            anchors.fill: parent
            radius: 24
        }
        Rectangle {
            id: barLeft
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 664
            clip: true
            color: "transparent"
            radius: 24
            Image {
                id: leftImg
                clip: true
                anchors.fill: parent
                source: "file:Splash/1.jpg"
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        height: leftImg.height
                        width: leftImg.width
                        Rectangle {
                            anchors.centerIn: parent
                            height: leftImg.height
                            width: leftImg.width
                            radius: 24
                        }
                    }
                }
            }
        }
        Rectangle {
            anchors.left: barLeft.right
            anchors.leftMargin: -24
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            Label {
                id: lblTitle
                anchors.top: parent.top
                anchors.topMargin: 130
                anchors.horizontalCenterOffset: 12
                anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 22
                font.bold: true
                text: qsTr("AppName") + translater.change
            }
            Item {
                anchors.top: lblTitle.bottom
                anchors.topMargin: 110
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 110
                width: 270
                anchors.horizontalCenterOffset: 12
                anchors.horizontalCenter: parent.horizontalCenter
                TextField {
                    id: edtUserId
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: imgUserId.width + 24
                    font.pixelSize: 18
                    placeholderText: qsTr("Login.UserId") + translater.change
                    focus: true
                    text: reLogin ? "" : Configer.userAccount()
                    onTextChanged: {
                        lblHint.text = ""
                        unfoundUserId = false
                        if (text.trim() === "") {
                            edtUserName.text = ""
                            return
                        }

                        edtUserName.text = userInfo.getUserName(text.trim())
                        if (edtUserName.text === "") {
                            lblHint.text = qsTr("Login.UnfoundId")
                            unfoundUserId = true
                        }
                    }
                    Keys.enabled: true
                    Keys.onReturnPressed: edtUserPwd.focus = true
                    Keys.onDownPressed: edtUserPwd.focus = true
                    Image {
                        id: imgUserId
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        fillMode: Image.PreserveAspectFit
                        source: "file:Images/userid.svg"
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 24
                        color: "#f8f8f8"
                    }
                }

                TextField {
                    id: edtUserName
                    anchors.top: edtUserId.bottom
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: imgUserName.width + 24
                    readOnly: true
                    font.pixelSize: 18
                    placeholderText: qsTr("Login.UserName") + translater.change
                    Keys.enabled: true
                    Keys.onReturnPressed: edtUserPwd.focus = true
                    Keys.onDownPressed: edtUserPwd.focus = true
                    Keys.onUpPressed: edtUserId.focus = true
                    Image {
                        id: imgUserName
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        fillMode: Image.PreserveAspectFit
                        source: "file:Images/username.svg"
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 24
                        color: "#f8f8f8"
                    }
                }

                TextField {
                    id: edtUserPwd
                    anchors.top: edtUserName.bottom
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: imgUserPwd.width + 24
                    echoMode: TextInput.Password
                    font.pixelSize: 18
                    placeholderText: qsTr("Login.UserPassword") + translater.change
                    Keys.enabled: true
                    //Keys.onReturnPressed: btnLogin.focus = true
                    Keys.onDownPressed: btnLogin.focus = true
                    Keys.onUpPressed: edtUserId.focus = true
                    onTextChanged: lblHint.text = ""
                    onAccepted: {
                        btnLogin.clicked()
                    }
                    Image {
                        id: imgUserPwd
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        fillMode: Image.PreserveAspectFit
                        source: "file:Images/password.svg"
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        radius: 24
                        color: "#f8f8f8"
                    }
                }

                Label {
                    id: lblHint
                    anchors.top: edtUserPwd.bottom
                    anchors.topMargin: 6
                    anchors.left: parent.left
                    anchors.right: parent.right
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    color: "peru"
                    visible: text !== ""
                }

                Row {
                    anchors.top: edtUserPwd.bottom
                    anchors.topMargin: 56
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 56
                    spacing: 24
                    RoundButton {
                        id: btnCancel
                        height: parent.height
                        width: parent.width / 5 * 2 - 12
                        Material.foreground: "#707070"
                        Material.background: "transparent"
                        font.pixelSize: 18
                        Keys.enabled: true
                        Keys.onDownPressed: edtUserName.focus = true
                        Keys.onUpPressed: btnLogin.focus = true
                        text: qsTr("Login.Cancel") + translater.change
                        onClicked: {
                            if (reLogin) {
                                root.close()
                            } else {
                                Qt.quit()
                            }
                        }
                    }
                    RoundButton {
                        id: btnLogin
                        enabled: root.nextFormLoaded
                        height: parent.height
                        width: parent.width / 5 * 3 - 12
                        Material.background: "#0075EF"
                        Material.foreground: "white"
                        font.pixelSize: 18
                        text: qsTr("Login.Login") + translater.change
                        Keys.enabled: true
                        Keys.onDownPressed: edtUserId.focus = true
                        Keys.onUpPressed: btnCancel.focus = true
                        Keys.onReturnPressed: btnLogin.clicked()
                        onClicked: {
                            if (unfoundUserId)
                                return

                            if (!userInfo.login(edtUserId.text.trim(),
                                                edtUserPwd.text.trim())) {
                                lblHint.text = qsTr("Login.PasswordError")
                                return
                            }

                            if (!reLogin)
                                main.loaderMain.item.showForm()

                            root.close()
                        }
                    }
                }
            }
        }
    }
}
