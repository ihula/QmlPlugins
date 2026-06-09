pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property color theme1Color: "#20B2AA"
    readonly property color theme2Color: "#5d5b67"
    readonly property color theme3Color: "#1296db"
    readonly property color theme4Color: "#2b7adb"
    readonly property color theme5Color: "#3b477f"
    readonly property color themeColor: "#2d6aea"
    readonly property color mainColor: "#2d6aea"
    readonly property color backColor: "#F0F1F5"
    property color workBackColor: "#F4F4F4"
    readonly property color normalColor: mainColor
    readonly property color hoveredColor: Qt.lighter(mainColor, 1.2)
    readonly property color pressedColor: Qt.darker(mainColor, 1.2)
    readonly property color gradientColor1: mainColor
    readonly property color gradientColor2: Qt.lighter(mainColor, 1.2)
    readonly property color titleFontColor: "white"

    property color workFormColor: "#ffffff"
    property color iconHoveredColor: "#2d6aea"
    property color editorFontColor: "#535353"
    property color lineColor: "#d8d8d8"
    property color buttonBackground: "white"
    property color buttonCheckedBackground: "#f1f1f1"
    property color viewColor: "#ebedf3"
    property color borderColor: "#f1f1f1"
    property color barColor: "#1296db"
    property color leftTitleColor: "white"
    property int editorFontSize: 18
    property int buttonFontSize: 18

    property Gradient titleBarGradient: Gradient {
        GradientStop {
            position: 0
            color: "white"
        }
        GradientStop {
            position: 0.5
            color: "#f4f4f4"
        }
        GradientStop {
            position: 1.0
            color: "white"
        }
    }

    property Gradient titleGradient: Gradient {
        GradientStop {
            position: 0.0
            color: gradientColor1
        }
        GradientStop {
            position: 1.0
            color: gradientColor2
        }
    }

    property Gradient viewGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0
            color: Qt.lighter(gradientColor2, 1.2)
        }
        GradientStop {
            position: 0.5
            color: gradientColor2
        }
        GradientStop {
            position: 0.6
            color: gradientColor2
        }
        GradientStop {
            position: 1.0
            color: Qt.lighter(gradientColor2, 1.2)
        }
    }
}