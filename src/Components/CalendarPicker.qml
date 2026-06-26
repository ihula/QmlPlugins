import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: control
    implicitWidth: 280
    implicitHeight: 320
    border.color: "#d1d1d1"
    property color hoverBorderColor: "#e91e63"
    property color textColor: "black"
    property color selectedTextColor: "white"
    property color selectedBackColor: "#e91e63"
    property alias font: monthgrid.font
    property alias locale: monthgrid.locale
    property string dateFormat: "yyyy-MM-dd"
    property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    property date selectedDate: new Date()
    signal clicked

    function dateString(format = "") {
        if (format === "")
            format = dateFormat;
        var currDate = new Date();
        return currDate.toLocaleString(Qt.locale(), format);
    }

    function date(format = "") {
        if (format === "")
            format = dateFormat;
        return selectedDate.toLocaleString(Qt.locale(), format);
    }

    component CalendarButton: AbstractButton {
        id: btn
        implicitWidth: 34
        implicitHeight: 34
        contentItem: Text {
            font: control.font
            text: btn.text
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: btn.pressed ? "#e0e0e0" : "transparent"
            radius: 4
        }
    }

    Item {
        id: btnBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        implicitHeight: 36

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            CalendarButton {
                text: "<"
                onClicked: monthgrid.year -= 1
            }
            Text {
                font: control.font
                color: textColor
                text: monthgrid.year
                Layout.alignment: Qt.AlignHCenter
            }
            CalendarButton {
                text: ">"
                onClicked: monthgrid.year += 1
            }

            Item {
                Layout.fillWidth: true
            }

            CalendarButton {
                text: "<"
                onClicked: {
                    if (monthgrid.month === 0) {
                        monthgrid.year -= 1;
                        monthgrid.month = 11;
                    } else {
                        monthgrid.month -= 1;
                    }
                }
            }
            Text {
                font: control.font
                color: textColor
                text: monthgrid.month + 1
                Layout.alignment: Qt.AlignHCenter
            }
            CalendarButton {
                text: ">"
                onClicked: {
                    if (monthgrid.month === 11) {
                        monthgrid.year += 1;
                        monthgrid.month = 0;
                    } else {
                        monthgrid.month += 1;
                    }
                }
            }
        }
    }

    Rectangle {
        id: line
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: btnBar.bottom
        color: "#d1d1d1"
        height: 1
    }

    Row {
        id: weekrow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: line.bottom
        anchors.margins: 6
        height: 32
        spacing: 0

        Repeater {
            model: control.dayNames
            delegate: Text {
                text: modelData
                font: control.font
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                width: parent.width / 7
                height: parent.height
            }
        }
    }

    MonthGrid {
        id: monthgrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: weekrow.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 6
        delegate: Rectangle {
            color: "transparent"
            border.color: itemmouse.containsMouse ? hoverBorderColor : "transparent"
            border.width: itemmouse.containsMouse ? 1 : 0
            width: height
            radius: width / 2
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: width / 2
                color: control.selectedDate.valueOf() === model.date.valueOf() ? selectedBackColor : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: model.day
                font: control.font
                color: {
                    if (control.selectedDate.valueOf() === model.date.valueOf()) {
                        return selectedTextColor;
                    } else {
                        return model.today ? selectedBackColor : (model.month === monthgrid.month ? textColor : "#999999");
                    }
                }
            }
            MouseArea {
                id: itemmouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }
        onClicked: date => {
            control.selectedDate = date;
            control.clicked();
        }
    }
}
