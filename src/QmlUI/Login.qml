import QtQuick
import QtQuick.Window
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import HulaPlugins

Window {
    id: root
    property int formShowMode: Configer.loginFormShowMode()
    property bool reLogin: false
    property bool unfoundUserId: false

    signal showing
    signal closeing
    signal closed

    function showForm() {
        fadeInAni.start();
        if (formShowMode === 0) {
            root.x = (Screen.width - root.width) / 2;
            root.y = (Screen.height - root.height) / 2;
            root.show();
        } else if (formShowMode === 1) {
            root.maximumWidth = Screen.desktopAvailableWidth;
            root.maximumHeight = Screen.desktopAvailableHeight;
            root.showMaximized();
        } else {
            root.showFullScreen();
        }
    }

    function unloadMainForm() {
        btnLogin.enabled = false;
    }

    function loadedMainForm() {
        btnLogin.enabled = true;
    }

    title: qsTr("Login.Title")
    flags: Qt.Window | Qt.FramelessWindowHint
    width: 1568
    height: 864
    opacity: 0

    // 拦截关闭请求
    onClosing: close => {
        if (root.opacity > 0) {
            // 阻止窗口立即关闭
            close.accepted = false;
            // 启动退出动画
            fadeOutAni.start();
        } else {
            closed();
        }
    }

    onVisibleChanged: {
        if (visible) {
            showForm();
            edtUserId.text = "";
            edtUserName.text = "";
            edtUserPwd.text = "";
            showing();
        }
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
        implicitHeight: 540
        anchors.centerIn: parent
        radius: 12
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0 // 阴影模糊度
            shadowHorizontalOffset: 0   // 水平偏移（0 表示居中）
            shadowVerticalOffset: 0     // 垂直偏移（4px，产生悬浮感）
            shadowColor: "#40000000"    // 阴影颜色（带透明度的黑色）
            shadowScale: (parent.width + 16) / parent.width
        }
        Rectangle {
            id: barLeft
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 664
            clip: true
            color: Themer.loginLeftBackColor
            radius: 12
            topRightRadius: 0
            bottomRightRadius: 0
            Column {
                spacing: 16
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: imgLogo
                    height: 128
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillMode: Image.PreserveAspectFit
                    source: "file:Images/logo.svg"
                    smooth: true
                }
                Label {
                    font.pixelSize: 18
                    text: qsTr("Vision")
                    color: barLeft.color.hslLightness < 0.5 ? "white" : "black"
                }
            }
        }

        Rectangle {
            anchors.left: barLeft.right
            anchors.leftMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            Label {
                id: lblTitle
                anchors.top: parent.top
                anchors.topMargin: 100
                //anchors.horizontalCenterOffset: 12
                //anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 18
                font.weight: 500
                text: qsTr("AppName")
            }
            Label {
                id: lblCompanyAbbrName
                anchors.top: lblTitle.bottom
                anchors.topMargin: 12
                //anchors.horizontalCenterOffset: 12
                //anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 12
                font.weight: 300
                text: qsTr("CompanyAbbrName")
            }
            Item {
                anchors.top: lblCompanyAbbrName.bottom
                anchors.topMargin: 60
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 64
                width: 270
                //anchors.horizontalCenterOffset: 12
                // anchors.horizontalCenter: parent.horizontalCenter
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
                    placeholderText: qsTr("Login.UserId")
                    focus: true
                    text: UserInfo.userAccount
                    onTextChanged: {
                        lblHint.text = "";
                        if (text.trim() === "") {
                            edtUserName.text = "";
                            return;
                        }

                        edtUserName.text = UserInfo.findUserName(text.trim());
                        if (edtUserName.text === "") {
                            lblHint.text = qsTr("Login.UnfoundId");
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
                    placeholderText: qsTr("Login.UserName")
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
                        radius: 8
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
                    leftPadding: imgPwd.width + 24
                    echoMode: TextInput.Password
                    font.pixelSize: 18
                    placeholderText: qsTr("Login.UserPassword")
                    Keys.enabled: true
                    //Keys.onReturnPressed: btnLogin.focus = true
                    Keys.onDownPressed: btnLogin.focus = true
                    Keys.onUpPressed: edtUserId.focus = true
                    onTextChanged: lblHint.text = ""
                    onAccepted: {
                        btnLogin.clicked();
                    }
                    background: Rectangle {
                        anchors.fill: parent
                        color: "#f8f8f8"
                        radius: 8
                        Image {
                            id: imgPwd
                            anchors.top: parent.top
                            anchors.topMargin: 12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            fillMode: Image.PreserveAspectFit
                            source: "file:Images/password.svg"
                        }
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
                        Material.background: "white"
                        //Material.background: "transparent"
                        font.pixelSize: 18
                        Keys.enabled: true
                        Keys.onDownPressed: edtUserName.focus = true
                        Keys.onUpPressed: btnLogin.focus = true
                        radius: 12
                        text: qsTr("Login.Cancel")
                        onClicked: {
                            if (UserInfo.userAccount !== "") {
                                root.close();
                            } else {
                                Qt.quit();
                            }
                        }
                    }
                    RoundButton {
                        id: btnLogin
                        height: parent.height
                        width: parent.width / 5 * 3 - 12
                        Material.background: "#0075EF"
                        Material.foreground: "white"
                        font.pixelSize: 18
                        text: qsTr("Login.Login")
                        Keys.enabled: true
                        Keys.onDownPressed: edtUserId.focus = true
                        Keys.onUpPressed: btnCancel.focus = true
                        Keys.onReturnPressed: btnLogin.clicked()
                        radius: 12
                        onClicked: {
                            if (!UserInfo.login(edtUserId.text.trim(), edtUserPwd.text.trim())) {
                                lblHint.text = qsTr("Login.PasswordError");
                                return;
                            }

                            root.closeing();
                            root.close();
                        }
                    }
                }
            }
        }
    }

    // 进入动画
    PropertyAnimation {
        id: fadeInAni
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.InOutQuad
    }

    // 退出动画
    PropertyAnimation {
        id: fadeOutAni
        target: root
        property: "opacity"
        from: 1
        to: 0
        duration: 500
        easing.type: Easing.InOutQuad
        onFinished: {
            root.close();
        }
    }
}
