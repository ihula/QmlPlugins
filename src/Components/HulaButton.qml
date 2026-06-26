import QtQuick
import QtQuick.Controls.Fusion

Button {
    id: root
    property int tag: 0
    property alias tipText: toolTip.text
    property alias iconText: lblText.text
    property string textColor: "white"
    property string iconImage: ""
    property bool iconHovered: false
    property int iconHeight: 32
    property int iconWidth: 32
    property bool useState: false
    property int radius: 0
    property color colorNormal: "transparent"
    property color colorHovered: "#50FFFFFF"
    property color colorPressed: "#80FFFFFF"
    property color colorDisabled: "#d1d1d1"
    property string strTag: ""
    hoverEnabled: true
    topPadding: 0
    states: [
        State {
            name: "checked"
            PropertyChanges {
                target: rectBackground
                color: colorPressed
            }
        },
        State {
            name: "unchecked"
            PropertyChanges {
                target: rectBackground
                color: root.hovered ? colorHovered : colorNormal
            }
        }
    ]

    state: useState ? "unchecked" : ""

    background: Rectangle {
        id: rectBackground
        width: parent.width
        height: parent.height
        color: root.pressed ? colorPressed : (root.hovered ? colorHovered : colorNormal)
        radius: root.radius
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Image {
                id: imgIcon
                fillMode: Image.PreserveAspectFit
                smooth: true
                width: iconWidth
                height: iconHeight
                source: (root.iconImage === "") ? "" : "file:" + root.iconImage
                opacity: (root.hovered && root.iconHovered) ? 0.6 : 1.0
            }

            Label {
                id: lblText
                visible: text !== ""
                font.pixelSize: root.font.pixelSize
                color: textColor
            }
        }
    }

    HulaToolTip {
        id: toolTip
    }

    onClicked: {
        if (!useState)
            return;
        state = (state === "checked") ? "unchecked" : "checked";
    }
}
