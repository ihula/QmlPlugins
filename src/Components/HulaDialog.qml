import QtQuick
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import QtQuick.Effects
import "../Components"
import HulaPlugins

Dialog {
    id: root

    // 1. 属性声明 (Properties)
    property var defaultButton: null
    property alias titleText: titleBar
    property alias buttonOk: btnOk
    property alias buttonCancel: btnCancel
    property alias titleFontSize: titleBar.font.pixelSize
    property int textPixelSize: 18
    property string messageText: ""
    property string animTypes: "scale"
    property int duration: 200
    property int easingType: Easing.Bezier
    property bool autoDestroy: true
    property color backColor: "#F4F4F4"
    property string buttonOkText: "Ok"
    property string buttonCancelText: "Cancel"
    property var callbackOnCancel: function () {}
    property var callbackOnOk: function () {}
    property bool autoClose: false

    // 2. 信号声明 (Signals)
    signal showForm
    signal hideForm

    // 4. 常规对象属性赋值 (Object Properties)
    width: 336
    height: header.height + footer.height + contentHeight + topPadding + bottomPadding + 10
    spacing: 0
    topPadding: 0
    modal: Qt.ApplicationModal
    closePolicy: Popup.CloseOnEscape
    x: (Overlay.overlay.width - width) / 2
    y: (Overlay.overlay.height - height) / 2
    //anchors.centerIn: Overlay.overlay

    enter: EnterTransition {
        animTypes: root.animTypes
        duration: root.duration
        target: root
        holder: holdedItem
    }

    exit: ExitTransition {
        animTypes: root.animTypes
        duration: root.duration
        target: root
        holder: holdedItem
    }

    // 5. 信号处理器 (Signal Handlers)
    onVisibleChanged: {
        if (visible) {
            showForm();
            return;
        }

        hideForm();
        if (autoDestroy) {
            if (parent && parent instanceof Loader) {
                parent.source = "";
            }
        }
    }

    // 6. 子对象 (Child Objects)
    // 辅助Item,用于转移 Enter, Exit 的 Transtion 中不使用的 PropertyAnimation
    Item {
        id: holdedItem
        height: 0
        width: 0
        visible: false
    }

    background: Rectangle {
        id: back
        color: backColor
        radius: 8
    }

    header: Item {
        implicitHeight: 54
        visible: (title.trim() !== "")
        Text {
            id: titleBar
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 12
            font.pixelSize: 20
            color: "#535353"
            text: qsTr(title)
            font.weight: Font.Medium
            verticalAlignment: Qt.AlignVCenter
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
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.close()
        }

        MouseArea {
            property point clickPoint: "0, 0"
            anchors.fill: parent
            onDoubleClicked: root.close()
            onClicked: mouse => {
                var x2 = btnClose.x + btnClose.width;
                var y2 = btnClose.y + btnClose.height;
                if ((mouse.x >= btnClose.x) && (mouse.x <= x2) && (mouse.y >= btnClose.y) && (mouse.y <= y2))
                    root.close();
            }
            onPressed: mouse => {
                clickPoint = Qt.point(mouse.x, mouse.y);
            }
            onPositionChanged: mouse => {
                var offset = Qt.point(mouse.x - clickPoint.x, mouse.y - clickPoint.y);
                root.x = root.x + offset.x;
                root.y = root.y + offset.y;
            }
        }
    }

    // 默认内容项：仅用于消息/确认弹窗（openDialogPrompt / openDialogConfirm）。
    // 需要自定义内容时，在实例里直接覆写 contentItem 即可（不再受 Label 约束）。
    contentItem: Label {
        wrapMode: Text.WordWrap
        text: qsTr(messageText)
        font.pixelSize: root.textPixelSize
        color: "#535353"
        horizontalAlignment: (lineCount > 1) ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    footer: Row {
        id: buttonBar
        layoutDirection: Qt.RightToLeft
        rightPadding: 16
        height: 54
        spacing: 0
        RoundButton {
            id: btnCancel
            radius: 4
            font.pixelSize: 18
            Material.background: "white"
            Material.foreground: "#535353"
            text: qsTr(buttonCancelText)
            height: 48
            width: 96
            visible: (text !== "")
            onClicked: {
                canceled();
                if (callbackOnCancel)
                    callbackOnCancel();
                root.close();
            }
        }

        RoundButton {
            id: btnOk
            property string content: qsTr(buttonOkText)
            radius: 4
            font.pixelSize: 18
            Material.background: "white"
            Material.foreground: "#535353"
            text: autoClose ? content + "(" + String(timer.sum) + ")" : content
            height: 48
            width: 96
            visible: (text !== "")
            onClicked: {
                if (callbackOnOk) {
                    var ret = callbackOnOk();
                    if ((ret === undefined) || (ret === 0)) {
                        accepted();
                        root.close();
                    }
                } else {
                    accepted();
                    root.close();
                }
            }
        }
    }

    // 自动关闭倒计时
    Timer {
        id: timer
        property int sum: 5
        interval: 1000
        repeat: true
        running: autoClose
        onTriggered: {
            if (root.clicked) {
                timer.stop();
                btnOk.text = btnOk.content;
                timer.repeat = false;
                return;
            }

            sum--;
            btnOk.text = btnOk.content + "(" + String(sum) + ")";
            if (sum == 0) {
                btnOk.clicked();
            }
        }
        onRunningChanged: {
            if (!running)
                btnOk.text = btnOk.content;
        }
    }

    TapHandler {
        onTapped: {
            if (timer.running) {
                timer.stop();
            }
        }
    }

    // 监控按键事件
    Item {
        id: keyItem
        height: 0
        focus: true
        Keys.onReturnPressed: {
            btnOk.clicked();
        }
    }
}
