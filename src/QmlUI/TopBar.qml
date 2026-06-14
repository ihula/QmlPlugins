import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QmlPlugins
import "../HulaUI"

Rectangle {
    id: titleBar
    height: 56
    color: "#ffffffff"
    clip: true
    state: "Released"
    property bool mainFormMixed: false
    property color pressedColor: "#2e6b89"
    property color releasedColor: "#12687C"
    property alias appName: txtAppName.text
    gradient: Themer.theme.titleBarGradient

    // move windows
    MouseArea {
        //此处是为了增加了一点颜色动画
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        property point clickPos: "0,0"
        onReleased: titleBar.state = "Released"
        onPressed: function (mouse) {
            titleBar.state = "Pressed";
            clickPos = Qt.point(mouse.x, mouse.y);
        }
        onPositionChanged: function (mouse) {
            var offset = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y);
            mainForm.x = mainForm.x + offset.x;
            mainForm.y = mainForm.y + offset.y;
        }
        onDoubleClicked: function (mouse) {
            restore();
        }
    }

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
        color: "#4F6371"
        font.pixelSize: 20
        font.bold: false
        text: qsTr("AppName") + Translater.change
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
            color: Themer.theme.lineColor
            width: 1
        }
    }

    HulaButton {
        id: btnPowerOff
        visible: true
        tipText: qsTr("Topbar.PowerOff") + Translater.change
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
            mainForm.openDialogConfirm("Topbar.ConfirmPowerOff", funcPowerOff);
        }
    }

    HulaButton {
        id: btnClose
        tipText: qsTr("Topbar.Quit") + Translater.change
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
            mainForm.openDialogConfirm("Topbar.ConfirmQuit", funcQuit);
        }
    }

    HulaButton {
        id: btnRestore
        tipText: qsTr("Topbar.Restore") + Translater.change
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
        tipText: qsTr("Topbar.Minimal") + Translater.change
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
            mainForm.showMinimized();
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
        icon.color: hovered ? (Themer.theme.iconHoveredColor) : "transparent"

        HulaToolTip {
            text: qsTr("Topbar.Preferences") + Translater.change
        }

        onClicked: mainForm.openDialog("Preferences.qml")
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
        icon.color: breathed ? "#E31C75" : (hovered ? (Themer.theme.iconHoveredColor) : "transparent")

        HulaToolTip {
            text: qsTr("MessageCenter.Title") + Translater.change
        }

        Component.onCompleted: {
            if (MessageCenter.hasNewInfo()) {
                startBreath();
            }
        }

        onClicked: {
            stopBreath();
            mainForm.openDialog("MessageCenterForm.qml");
        }
    }

    RoundButton {
        id: btnUser
        property string caption: (mainForm.userName !== "") ? mainForm.userName : qsTr("Topbar.Unlogin") + Translater.change
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
        icon.color: /*hovered ? Themer.theme.iconHoveredColor :*/ "transparent"
        background: Item {
            anchors.fill: parent
        }

        onClicked: menuUser.popup()

        Menu {
            id: menuUser
            font.pixelSize: 18
            MenuItem {
                text: qsTr("Topbar.Relogin") + Translater.change
                onTriggered: {
                    mainForm.openLogin({
                        "reLogin": true
                    });
                }
            }

            MenuItem {
                text: qsTr("User.Title") + Translater.change
                onTriggered: {
                    mainForm.openDialog("UserInfoForm.qml");
                }
            }
        }
    }

    //标题栏颜色动效
    states: [
        State {
            name: "Pressed"
            PropertyChanges {
                target: titleBar
                opacity: 0.8
            }
        },
        State {
            name: "Released"
            PropertyChanges {
                target: titleBar
                opacity: 1.0
            }
        }
    ]
    transitions: [
        Transition {
            PropertyAnimation {
                property: "opacity"
                to: 1.0
                duration: 200
            }
        },
        Transition {
            PropertyAnimation {
                property: "opacity"
                to: 0.9
                duration: 200
            }
        }
    ]

    PropertyAnimation {
        id: aniOpacity
        property: "opacity"
        from: 1
        to: 0.5
        duration: 1000
        easing.type: Easing.InOutQuad
    }

    function restore() {
        if (mainForm.visibility === Window.FullScreen || mainForm.visibility === Window.Maximized) {
            if (mainForm.formShowMode !== 0)
                if (!mainFormMixed) {
                    mainFormMixed = true;
                    mainForm.showMinimized();
                }
            mainForm.showNormal();
        } else if (mainForm.formShowMode === 2)
            mainForm.showFullScreen();
        else
            mainForm.showMaximized();
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
        } else if (msg.promptType === Enums.PromptType.Confirmation) {
            var confirmBox = openDialogPrompt(msg.text, null, "Information");
            confirmBox.autoClose = true;
        } else if (msg.promptType === Enums.PromptType.Log) {
            startBreath();
        }
    }

    function appendLeftItem(item) {
        item.parent = leftBar;
    }

    function removeLeftItem(item) {
        item.destroy();
    }
}
