import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: control
    implicitWidth: 260
    implicitHeight: 300
    border.color: "#d1d1d1"
    property color accentColor: "#2196f3"
    property alias font: monthgrid.font
    property alias locale: monthgrid.locale
    property string dateFormat: "yyyy-MM-dd"
    property date selectedDate: new Date()
    signal clicked

    function currDateString(format = "") {
        if (format === "")
            format = dateFormat
        var currDate = new Date()
        return currDate.toLocaleString(Qt.locale(), format)
    }

    function selectDate(format = "") {
        if (format === "")
            format = dateFormat
        return selectedDate.toLocaleString(Qt.locale(), format)
    }

    //自定义按钮样式
    component CalendarButton: AbstractButton {
        id: btn
        implicitWidth: 30
        implicitHeight: 30
        contentItem: Text {
            font: control.font
            text: btn.text
            color: "black"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Item {}
    }

    Item {
        id: btnBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        implicitHeight: 32

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            CalendarButton {
                text: "<"
                onClicked: {
                    monthgrid.year -= 1
                }
            }
            Text {
                font: control.font
                color: "black"
                text: monthgrid.year
            }
            CalendarButton {
                text: ">"
                onClicked: {
                    monthgrid.year += 1
                }
            }
            Item {
                implicitWidth: 20
            }
            CalendarButton {
                text: "<"
                onClicked: {
                    if (monthgrid.month === 0) {
                        monthgrid.year -= 1
                        monthgrid.month = 11
                    } else {
                        monthgrid.month -= 1
                    }
                }
            }
            Text {
                font: control.font
                color: "black"
                text: monthgrid.month + 1
            }
            CalendarButton {
                text: ">"
                onClicked: {
                    if (monthgrid.month === 11) {
                        monthgrid.year += 1
                        monthgrid.month = 0
                    } else {
                        monthgrid.month += 1
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

    //星期1-7
    DayOfWeekRow {
        id: weekrow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: line.bottom
        anchors.margins: 6
        implicitHeight: 32
        font: control.font
    }
    //日期单元格
    MonthGrid {
        id: monthgrid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: weekrow.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 6
        spacing: 0
        delegate: Rectangle {
            color: "transparent"
            border.color: accentColor
            border.width: itemmouse.containsMouse ? 1 : 0
            radius: height / 2
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: height / 2
                color: model.today ? "orange" : control.selectedDate.valueOf(
                                         ) === model.date.valueOf(
                                         ) ? accentColor : "transparent"
            }
            Text {
                anchors.centerIn: parent
                text: model.day
                color: model.month === monthgrid.month ? "black" : "gray"
            }
            MouseArea {
                id: itemmouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }
        onClicked: date => {
                       control.selectedDate = date
                       control.clicked()
                   }
    }
}
