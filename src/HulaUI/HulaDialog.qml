import QtQuick
import QtQuick.Controls.Fusion
import Qt.labs.qmlmodels
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../HulaUI"

Dialog {
    id: root
    width: 480
    height: 320
    padding: 0
    topPadding: 0
    modal: Qt.ApplicationModal
    closePolicy: Popup.CloseOnEscape
    title: ""
    property var defaultButton: null
    property string formTitle: ""
    property alias titlePixelSize: titleBar.font.pixelSize
    property alias titleBar: titleBar
    property string animationType: 'size'
    property int duration: 200 //350
    property int easingType: Easing.Bezier //.OutBounce
    property bool titleUseGradient: false
    property bool autoDestroy: true
    property bool clicked: false
    property color backColor: "#F4F4F4"

    signal showForm
    signal hideForm

    //standardButtons: Dialog.Ok | Dialog.Cancel
    onVisibleChanged: {
        if (visible) {
            showForm()
            return
        }

        hideForm()
        if (autoDestroy) {
            if (parent && parent instanceof Loader) {
                root.parent.source = ""
            } else {
                destroy()
            }
        }
    }
    background: Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 8
        color: backColor
        border.width: 1
        border.color: backColor //"#d1d1d1"
    }

    RectangularGlow {
        id: effect
        anchors.fill: rectBack
        glowRadius: 20
        spread: 0
        color: "#80000000"
    }

    Rectangle {
        id: rectBack
        color: backColor
        anchors.fill: parent
        radius: 8
    }

    Label {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 0
        padding: 10
        font.pixelSize: 20
        visible: text.trim() !== ""
        color: "#555555"
        text: qsTr(formTitle) + translater.change
        verticalAlignment: Qt.AlignVCenter

        background: Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            radius: rectBack.radius
            color: "#cfcfcf"
            Rectangle {
                anchors.bottom: parent.bottom
                height: 8
                width: parent.width
                color: "#cfcfcf"
            }

            HulaButton {
                id: btnClose
                tipText: qsTr("Topbar.Quit") + translater.change
                iconImage: "Images/close.svg"
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
            }
        }

        MouseArea {
            property point clickPoint: "0, 0"
            anchors.fill: parent
            onDoubleClicked: root.hide()
            onClicked: mouse => {
                           var x2 = btnClose.x + btnClose.width
                           var y2 = btnClose.y + btnClose.height
                           if ((mouse.x >= btnClose.x) && (mouse.x <= x2)
                               && (mouse.y >= btnClose.y) && (mouse.y <= y2))
                           root.hide()
                       }
            onPressed: mouse => {
                           clickPoint = Qt.point(mouse.x, mouse.y)
                       }
            onPositionChanged: function (mouse) {
                var offset = Qt.point(mouse.x - clickPoint.x,
                                      mouse.y - clickPoint.y)
                root.x = root.x + offset.x
                root.y = root.y + offset.y
            }
        }
    }

    // 动画
    PropertyAnimation {
        id: animFadeIn
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'opacity'
        from: 0
        to: 1
    }
    PropertyAnimation {
        id: animFadeOut
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'opacity'
        from: 1
        to: 0
    }
    PropertyAnimation {
        id: animWidthIncrease
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'width'
        from: 0
        to: root.width
    }
    PropertyAnimation {
        id: animWidthDecrease
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'width'
        from: root.width
        to: 0
    }
    PropertyAnimation {
        id: animHeightIncrease
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'height'
        from: 0
        to: root.height
    }
    PropertyAnimation {
        id: animHeightDecrease
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'height'
        from: root.height
        to: 0
    }
    PropertyAnimation {
        id: animBig
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'scale'
        from: 0.2
        to: 1
    }
    PropertyAnimation {
        id: animSmall
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'scale'
        from: 1
        to: 0.2
    }
    PropertyAnimation {
        id: animInRight
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'x'
        from: -root.width
        to: root.x
    }
    PropertyAnimation {
        id: animInLeft
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'x'
        from: getRoot(root).width
        to: root.x
    }
    PropertyAnimation {
        id: animInUp
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'y'
        from: getRoot(root).height
        to: root.y
    }
    PropertyAnimation {
        id: animInDown
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'y'
        from: -root.height
        to: root.y
    }
    PropertyAnimation {
        id: animOutRight
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'x'
        from: root.x
        to: getRoot(root).width
    }
    PropertyAnimation {
        id: animOutLeft
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'x'
        from: root.x
        to: -root.width
    }
    PropertyAnimation {
        id: animOutUp
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'y'
        from: root.y
        to: -root.height
    }
    PropertyAnimation {
        id: animOutDown
        target: root
        duration: root.duration
        easing.type: root.easingType
        property: 'y'
        from: root.y
        to: getRoot(root).height
    }

    // 动画结束后调用的脚本
    Connections {
        id: connector
        target: animInDown
        function onStopped() {
            close()
        }
    }

    function getRoot(item) {
        return (item.parent !== null) ? getRoot(item.parent) : item
    }

    function show() {
        switch (animationType) {
        case "fade":
            animFadeIn.start()
            break
        case "focus":
            animFocusIn.start()
            break
        case "width":
            animWidthIncrease.start()
            break
        case "height":
            animHeightIncrease.start()
            break
        case "size":
            animBig.start()
            break
        case "flyDown":
            animInDown.start()
            break
        case "flyUp":
            animInUp.start()
            break
        case "flyLeft":
            animInLeft.start()
            break
        case "flyRight":
            animInRight.start()
            break
        default:
            this.visible = true
        }
    }

    function hide() {
        switch (animationType) {
        case "fade":
            connector.target = animFadeOut
            animFadeOut.start()
            break
        case "width":
            connector.target = animWidthDecrease
            animWidthDecrease.start()
            break
        case "height":
            connector.target = animHeightDecrease
            animHeightDecrease.start()
            break
        case "size":
            connector.target = animSmall
            animSmall.start()
            break
        case "flyDown":
            connector.target = animOutUp
            animOutUp.start()
            break
        case "flyUp":
            connector.target = animOutDown
            animOutDown.start()
            break
        case "flyLeft":
            connector.target = animOutRight
            animOutRight.start()
            break
        case "flyRight":
            connector.target = animOutLeft
            animOutLeft.start()
            break
        default:
            close()
        }
    }

    function getOkButton(parentItem) {
        parentItem = parentItem || root
        for (var i = 0; i < parentItem.contentChildren.length; i++) {
            var child = parentItem.contentChildren[i]
            if (typeof child.isDefaultButton !== 'undefined') {
                return child.text
            }
            var result = getOkButton(child)
            if (result) return result
        }
        return ""
    }
}
