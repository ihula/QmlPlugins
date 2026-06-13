import QtQuick 2.12
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

//import Qt.labs.calendar 1.0

//日历样式自定义
//龚建波 2021-1-7
Calendar {
    id: control

    implicitHeight: 280
    implicitWidth: 280

    //普通色块背景
    property color normalBgColor: mainWindow.backgroundColor //"#FFFFFF"
    //选中项背景
    property color selectBgColor: "#305FDE"
    //超出月份背景
    property color outBgColor: normalBgColor
    //不可选背景（最大最小范围外）
    property color disableBgColor: "#F0F0F0"
    //网格颜色
    property color gridColor: "#00000000" //"#E5E5E5"
    //标题文本颜色
    property color darkTextColor: "#242526"
    //日期文本颜色
    property color lightTextColor: "#555658"
    //超出月份文本颜色
    property color outTextColor: "#999999"
    //不可选文本（最大最小范围外）
    property color disableTextColor: "#BBBBBB"

    style: CalendarStyle {
        gridColor: control.gridColor
        gridVisible: false

        background: Rectangle {
            id: background
            anchors.fill: parent
            color: control.normalBgColor
        }

        //标题年月
        navigationBar: Item {
            height: control.height / 8
            Canvas {
                id: prevYear
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                width: parent.height / 2
                height: width
                property bool mousePressed: false
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (prevYear.mousePressed) {
                        ctx.lineWidth = 2
                        ctx.strokeStyle = control.selectBgColor
                    } else {
                        ctx.lineWidth = 1
                        ctx.strokeStyle = control.darkTextColor
                    }
                    ctx.moveTo(0, height * 3 / 4)
                    ctx.lineTo(width / 2, height / 4)
                    ctx.lineTo(width, height * 3 / 4)
                    //ctx.closePath()
                    ctx.stroke()
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        control.showPreviousYear()
                    }
                    onPressed: {
                        prevYear.mousePressed = true
                        prevYear.requestPaint()
                    }
                    onReleased: {
                        prevYear.mousePressed = false
                        prevYear.requestPaint()
                    }
                }
            }
            Canvas {
                id: nextYear
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: prevYear.right
                anchors.leftMargin: 10
                width: parent.height / 2
                height: width
                property bool mousePressed: false
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (nextYear.mousePressed) {
                        ctx.lineWidth = 2
                        ctx.strokeStyle = control.selectBgColor
                    } else {
                        ctx.lineWidth = 1
                        ctx.strokeStyle = control.darkTextColor
                    }
                    ctx.beginPath()
                    ctx.moveTo(0, height / 4)
                    ctx.lineTo(width / 2, height * 3 / 4)
                    ctx.lineTo(width, height / 4)
                    //ctx.closePath()
                    ctx.stroke()
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        control.showNextYear()
                    }
                    onPressed: {
                        nextYear.mousePressed = true
                        nextYear.requestPaint()
                    }
                    onReleased: {
                        nextYear.mousePressed = false
                        nextYear.requestPaint()
                    }
                }
            }
            Label {
                id: labelYear
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: nextYear.right
                anchors.leftMargin: 15
                //text: control.selectedDate.getFullYear()+qsTr('年')
                text: control.visibleYear + qsTr('年')
                //elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: 12
                font.family: "Microsoft YaHei"
                color: control.darkTextColor
            }

            Canvas {
                id: nextMonth
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                width: parent.height / 2
                height: width
                property bool mousePressed: false
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (nextMonth.mousePressed) {
                        ctx.lineWidth = 2
                        ctx.strokeStyle = control.selectBgColor
                    } else {
                        ctx.lineWidth = 1
                        ctx.strokeStyle = control.darkTextColor
                    }
                    ctx.beginPath()
                    ctx.moveTo(0, height / 4)
                    ctx.lineTo(width / 2, height * 3 / 4)
                    ctx.lineTo(width, height / 4)
                    //ctx.closePath()
                    ctx.stroke()
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        control.showNextMonth()
                    }
                    onPressed: {
                        nextMonth.mousePressed = true
                        nextMonth.requestPaint()
                    }
                    onReleased: {
                        nextMonth.mousePressed = false
                        nextMonth.requestPaint()
                    }
                }
            }
            Canvas {
                id: prevMonth
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: nextMonth.left
                anchors.rightMargin: 10
                width: parent.height / 2
                height: width
                property bool mousePressed: false
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    if (prevMonth.mousePressed) {
                        ctx.lineWidth = 2
                        ctx.strokeStyle = control.selectBgColor
                    } else {
                        ctx.lineWidth = 1
                        ctx.strokeStyle = control.darkTextColor
                    }
                    ctx.beginPath()
                    ctx.moveTo(0, height * 3 / 4)
                    ctx.lineTo(width / 2, height / 4)
                    ctx.lineTo(width, height * 3 / 4)
                    //ctx.closePath()
                    ctx.stroke()
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        control.showPreviousMonth()
                    }
                    onPressed: {
                        prevMonth.mousePressed = true
                        prevMonth.requestPaint()
                    }
                    onReleased: {
                        prevMonth.mousePressed = false
                        prevMonth.requestPaint()
                    }
                }
            }
            Label {
                id: labelMonth
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: prevMonth.left
                anchors.rightMargin: 15
                //注意Date原本的月份是0开始
                text: (control.visibleMonth + 1) + qsTr('月')
                //elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                font.pixelSize: 12
                font.family: "Microsoft YaHei"
                color: control.darkTextColor
            }

            Rectangle {
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
                color: control.gridColor
            }
        }
        //星期
        dayOfWeekDelegate: Item {
            //color: "transparent"
            height: control.height / 8
            Label {
                text: control.__locale.dayName(styleData.dayOfWeek,
                                               control.dayOfWeekFormat)
                anchors.centerIn: parent
                color: control.darkTextColor
                font.pixelSize: 12
                font.family: "Microsoft YaHei"
            }
        }
        dayDelegate: Rectangle {
            //color: "#00000000"
            //选中-当月未选中-其他
            color: (styleData.selected ? control.selectBgColor : styleData.valid ? styleData.visibleMonth ? control.normalBgColor : control.outBgColor : control.disableBgColor)
            Label {
                text: styleData.date.getDate()
                anchors.centerIn: parent
                font.pixelSize: 10
                font.family: "Microsoft YaHei"
                color: (styleData.selected ? control.normalBgColor : styleData.valid ? styleData.visibleMonth ? control.lightTextColor : control.outTextColor : control.disableTextColor)
            }
        }
    }
}
