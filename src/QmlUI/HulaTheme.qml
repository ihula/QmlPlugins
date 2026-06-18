pragma Singleton

import QtQuick

QtObject {
    id: theme
    objectName: "theme"

    property color theme1Color: "#20B2AA"
    property color theme2Color: "#5d5b67"
    property color theme3Color: "#1296db"
    property color theme4Color: "#2b7adb"
    property color theme5Color: "#3b477f"
    property color themeColor: "#2643d2"
    property color mainColor: theme5Color
    property color backColor: "white"
    property color workBackColor: "#F4F4F4"
    property color normalColor: mainColor
    property color hoveredColor: Qt.lighter(mainColor, 1.4)
    property color pressedColor: Qt.darker(mainColor, 1.2)
    property color gradientColor1: mainColor
    property color gradientColor2: Qt.lighter(mainColor, 1.5)
    property color titleFontColor: "white"

    property color workFormColor: "#ffffff"
    property color iconHoveredColor: "#2b7adb"
    property color editorFontColor: "#535353"
    property color editedFontColor: "#e91e63"
    property color lineColor: "#d8d8d8"
    property color buttonBackground: "white"
    property color buttonCheckedBackground: "#f1f1f1"
    property color buttonTextColor: "white"
    property color buttonColor: "#436fF6"
    property color viewColor: "#ebedf3"
    property color borderColor: "#f1f1f1"
    property color borderGrayColor: "gray"
    property color barColor: "#1296db"
    property color leftTitleColor: "white"
    property color warnColor: "#f67b3e"//Qt.rgba(246, 123, 62,0)
    property int editorFontSize: 18
    property int editorHeight: 36
    property int buttonFontSize: 18
    property int buttonHeight: 48
    property int buttonWidth: 120

    property Gradient buttonGradient: Gradient {
        GradientStop {
            position: 0.0
            color: "#3b477f"
        }
        GradientStop {
            position: 1.0
            color: "#5a6bb8"
        }
    }

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
