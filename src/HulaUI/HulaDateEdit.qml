import QtQuick 2.9
import QtQuick.Controls 1.2 as Ctrl1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls 2.5
import QtGraphicalEffects 1.15
import "../HulaUI/"

HulaTextField {
    id: root
    property string dateValue
    property bool useTime: false
    property bool editable: true

    Popup {
        id: popView
        margins: 0
        padding: 0
        implicitHeight: 280
        implicitWidth: 280
        y: underlineY


        /*
        background: Rectangle {
            color: mainWindow.backgroundColor
        }*/
        RectangularGlow {
            id: effect
            anchors.fill: rect
            glowRadius: 20
            spread: 0
            color: "#80000000"
        }

        Rectangle {
            id: rect
            color: mainWindow.backgroundColor //"white"
            anchors.fill: parent
            radius: 0
        }

        HulaCalendar {
            id: calendar
            anchors.fill: parent
            activeFocusOnTab: true

            onReleased: {
                text = date.toLocaleString(Qt.locale(), "yyyy-MM-dd")
                if (useTime)
                    text = text + new Date().toLocaleTimeString(Qt.locale(),
                                                                " hh:mm:ss")

                dateValue = text
                popView.close()
            }
        }
    }

    ToolButton {
        id: downBtn
        visible: editable
        flat: false
        height: 30
        width: 30
        hoverEnabled: true
        display: AbstractButton.TextOnly
        background: Rectangle {
            color: downBtn.hovered ? "#55FFFFFF" : "transparent"
        }

        anchors.right: parent.right
        anchors.rightMargin: 0
        y: input.y - 4
        font.family: root.input.font.family
        font.pixelSize: root.input.font.pixelSize + 2

        text: "▼"
        contentItem: Text {
            text: downBtn.text
            font: downBtn.font
            opacity: downBtn.down ? 0.6 : 1.0
            color: downBtn.enabled ? "#555658" : "ligthgray"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        onPressed: {
            popView.open()
        }
    }

    MouseArea {
        id: view
        clip: true
        hoverEnabled: enabled
        visible: !editable
        anchors.fill: parent
        onClicked: {
            popView.open()
        }
    }

    onDateValueChanged: {
        text = dateValue
        calendar.selectedDate = dateValue
    }
}
