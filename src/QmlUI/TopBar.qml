import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Shapes
import HulaPlugins
import "../Components"

Rectangle {
    id: titleBar
    height: 56
    color: "#ffffffff"
    property bool mainFormMixed: false
    property color pressedColor: "#2e6b89"
    property color releasedColor: "#12687C"
    property alias appName: txtAppName.text
    gradient: Themer.titleBarGradient

    Rectangle {
        height: 1
        color: "#d4d4d4"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }

    Connections {
        target: MessageCenter
        function onMessageEmitted(msg) {
            showInfo(msg);
        }
    }

    Text {
        id: txtAppName
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 12
        color: Themer.fontDarkColor
        font.pixelSize: 20
        font.weight: Font.Medium
        text: qsTr("AppName")
    }

    Row {
        id: leftBar
        anchors.left: txtAppName.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        spacing: 1
        visible: children.length > 1 ? true : false
        Rectangle {
            id: line1
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Themer.lineColor
            width: 1
        }
    }

    HulaButton {
        id: btnPowerOff
        visible: true
        tipText: qsTr("Topbar.PowerOff")
        iconImage: "Images/shutdown.svg"
        colorHovered: "red"
        width: 48
        height: 32
        iconHeight: 24
        iconWidth: 24
        anchors {
            right: parent.right
            leftMargin: 1
            rightMargin: 4
            verticalCenter: parent.verticalCenter
        }
        onClicked: {
            var funcPowerOff = function () {
                Qt.exit(100);
            };
            Window.window.openDialogConfirm("Topbar.ConfirmPowerOff", funcPowerOff);
        }
    }

    HulaButton {
        id: btnClose
        tipText: qsTr("Topbar.Quit")
        iconImage: "Images/close.svg"
        colorHovered: "red"
        width: 48
        height: 32
        iconHeight: 24
        iconWidth: 24
        anchors {
            right: btnPowerOff.visible ? btnPowerOff.left : parent.right
            leftMargin: 1
            rightMargin: 1
            verticalCenter: parent.verticalCenter
        }
        onClicked: {
            var funcQuit = function () {
                Qt.quit();
            };
            Window.window.openDialogConfirm("Topbar.ConfirmQuit", funcQuit);
        }
    }

    HulaButton {
        id: btnRestore
        tipText: qsTr("Topbar.Restore")
        iconImage: "Images/restore.svg"
        colorHovered: "#e6e6e6"
        width: 48
        height: 32
        iconHeight: 16
        iconWidth: 16
        anchors {
            right: btnClose.left
            leftMargin: 1
            rightMargin: 1
            verticalCenter: parent.verticalCenter
        }
        onClicked: {
            restore();
        }
    }

    HulaButton {
        id: btnMin
        tipText: qsTr("Topbar.Minimal")
        iconImage: "Images/min.svg"
        colorHovered: "#e6e6e6"
        width: 48
        height: 32
        iconHeight: height
        iconWidth: 24
        anchors {
            right: btnRestore.left
            leftMargin: 1
            rightMargin: 1
            verticalCenter: parent.verticalCenter
        }
        onClicked: {
            Window.window.showMinimized();
        }
    }

    RoundButton {
        id: btnPreferences
        anchors.right: btnMin.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        display: AbstractButton.IconOnly
        icon.source: "file:" + "Images/preferences.svg"
        icon.height: 32
        icon.width: 32
        height: 54
        flat: true
        hoverEnabled: true
        icon.color: hovered ? (Themer.iconHoveredColor) : "transparent"

        HulaToolTip {
            text: qsTr("Topbar.Preferences")
        }

        onClicked: Window.window.openDialog("Preferences.qml")
    }

    RoundButton {
        id: btnInfo
        property bool breathed: false
        anchors.right: btnPreferences.left
        anchors.verticalCenter: parent.verticalCenter
        display: AbstractButton.IconOnly
        icon.source: "file:" + "Images/warn.svg"
        icon.height: 32
        icon.width: 32
        height: 54
        flat: true
        hoverEnabled: true
        icon.color: breathed ? "#E31C75" : (hovered ? (Themer.iconHoveredColor) : "transparent")

        HulaToolTip {
            text: qsTr("MessageCenter.Title")
        }

        Component.onCompleted: {
            if (MessageCenter.hasNewInfo()) {
                startBreath();
            }
        }

        onClicked: {
            stopBreath();
            Window.window.openDialog("MessageCenterForm.qml");
        }
    }

    RoundButton {
        id: btnUser
        property string caption: (Window.window.userName !== "") ? Window.window.userName : qsTr("Topbar.Unlogin")
        anchors.right: btnInfo.visible ? btnInfo.left : btnSetting.left
        anchors.verticalCenter: parent.verticalCenter
        display: AbstractButton.TextBesideIcon
        font.pixelSize: 18
        text: caption //▼
        icon.source: "file:" + "Images/user.svg"
        icon.height: 32
        icon.width: 32
        height: 64
        radius: 8
        flat: true
        highlighted: hovered
        hoverEnabled: true
        icon.color: "transparent"
        background: Item {
            anchors.fill: parent
        }

        onClicked: menuUser.popup()

        Menu {
            id: menuUser
            font.pixelSize: 18
            MenuItem {
                text: qsTr("Topbar.Relogin")
                onTriggered: {
                    Window.window.openLogin({
                        "reLogin": true
                    });
                }
            }

            MenuItem {
                text: qsTr("User.Title")
                onTriggered: {
                    Window.window.openDialog("UserInfoForm.qml");
                }
            }
        }
    }

    function restore() {
        if ((Window.window.visibility === Window.FullScreen) || (Window.window.visibility === Window.Maximized)) {
            Window.window.showNormal();
        } else {
            if (Window.window.formShowMode === 2)
                Window.window.showFullScreen();
            else
                Window.window.showMaximized();
        }
    }

    SequentialAnimation {
        id: seqanimation
        running: false
        loops: Animation.Infinite
        NumberAnimation {
            target: btnInfo
            property: "opacity"
            duration: 2000
            to: 0.3
            easing.type: Easing.InOutQuad
        }

        NumberAnimation {
            target: btnInfo
            property: "opacity"
            duration: 2000
            to: 1.0
            easing.type: Easing.InOutQuad
        }
    }

    function startBreath() {
        btnInfo.breathed = true;
        if (seqanimation.paused) {
            seqanimation.resume();
        } else {
            seqanimation.start();
        }
    }

    function pauseBreath() {
        btnInfo.opacity = 0.7;
        if (seqanimation.running) {
            seqanimation.pause();
        }
    }

    function lastStateBreath() {
        if (seqanimation.paused) {
            startBreath();
        } else {
            stopBreath();
        }
    }

    function stopBreath() {
        seqanimation.stop();
        btnInfo.breathed = false;
        btnInfo.opacity = 1.0;
    }

    function showInfo(msg) {
        if (msg.promptType === Enums.PromptType.Toast) {
            snackMessage(msg.text);
        } else if (msg.promptType === Enums.PromptType.Error) {
            startBreath();
            var msgBox = openDialogPrompt(msg.text, null, "Error");
            msgBox.autoClose = true;
            msgBox.buttonCancelText = "";
        } else if (msg.promptType === Enums.PromptType.Confirmation) {
            var confirmBox = openDialogPrompt(msg.text, null, "Information");
            confirmBox.autoClose = true;
            msgBox.buttonCancelText = "";
        } else if (msg.promptType === Enums.PromptType.Log) {
            startBreath();
        }
    }

    function appendLeftItem(item) {
        item.parent = leftBar;
        item.visible = true;
    }

    function removeLeftItem(item) {
        item.visible = false;
    }

    // 颜色加深遮罩层（默认完全透明）
    Rectangle {
        id: darkenOverlay
        anchors.fill: parent
        color: "black"     // 使用黑色遮罩来实现颜色加深
        opacity: 0.0       // 默认不加深
        radius: titleBar.radius // 保持与底层相同的圆角
    }

    TapHandler {
        id: tapHandler
    }

    // 状态机：按下时让遮罩层显现（颜色加深）
    states: [
        State {
            name: "pressedState"
            when: tapHandler.pressed
            PropertyChanges {
                target: darkenOverlay // 注意：这里 target 改为了遮罩层
                opacity: 0.2          // 20% 的黑色遮罩，实现自然的加深效果
            }
        }
    ]

    // 过渡动画：平滑切换加深效果
    transitions: Transition {
        NumberAnimation {
            properties: "opacity"
            duration: 200
        }
    }
}
