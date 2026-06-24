import QtQuick
import QtQuick.Controls.Material
import Qt.labs.qmlmodels
import QtQuick.Layouts
import QtQuick.Effects
import "../HulaUI"
import QmlPlugins

Dialog {
    id: root

    // 1. 属性声明 (Properties)
    property var defaultButton: null
    property alias titleText: titleBar
    property alias buttonOk: btnOk
    property alias buttonCancel: btnCancel
    property alias titleFontSize: titleBar.font.pixelSize
    property alias textPixelSize: lblText.font.pixelSize
    property string messageText: ""
    property string animTypes: "scale"
    property int duration: 200
    property int easingType: Easing.Bezier
    property bool autoDestroy: true
    property color backColor: "#F4F4F4"
    property string buttonOkText: "Ok"
    property string buttonCancelText: "Cancel"
    property var callbackOnCancel: function () {}
    property var callbackOnOK: function () {}
    property bool autoClose: false

    // 2. 信号声明 (Signals)
    signal showForm
    signal hideForm

    // 3. JavaScript 函数 (Functions)

    // 4. 常规对象属性赋值 (Object Properties)
    width: 336
    height: header.height + footer.height + contentHeight //+ 40
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
            color: "#555555"
            text: qsTr(title)
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

    contentItem: Label {
        id: lblText
        wrapMode: Text.WordWrap
        text: qsTr(messageText)
        font.pixelSize: 18
        horizontalAlignment: (lineCount > 1) ? Text.AlignLeft : Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        height: Math.max(60, implicitHeight)
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
            Material.foreground: "black"
            text: qsTr(buttonCancelText)
            height: 48
            width: 96
            visible: (text !== "")
            onClicked: {
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
            Material.foreground: "black"
            text: autoClose ? content + "(" + String(timer.sum) + ")" : content
            height: 48
            width: 96
            visible: (text !== "")
            onClicked: {
                if (callbackOnOK)
                    callbackOnOK();

                root.close();
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
    }

    // 监控按键事件
    Item {
        id: keyItem
        height: 0
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Enter) {
                // 小键盘上的回车
                btnOk.clicked();
            } else if (event.key === Qt.Key_Return) {
                btnOk.clicked();
            }

            // 打印按键的扫描码和文本字符
            //console.log("Scan code: " + event.nativeScanCode)
            //console.log("Text: " + event.text)
        }
    }

    // 辅助Item,用于转移 Enter, Exit 的 Transtion 中不使用的 PropertyAnimation
    Item {
        id: holdedItem
        height: 0
        width: 0
        visible: true
    }
}
