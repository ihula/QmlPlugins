import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCharts
import "../Components"
import HulaPlugins

Item {
    id: root

    component ReagentCard: Rectangle {
        height: 82
        radius: 12
        color: cardColor

        property string title: ""
        property string value: ""
        property int progress: 0
        property color cardColor: "#6C5CE7"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Text {
                text: title
                font.pixelSize: 14
                color: "white"
            }

            Text {
                text: value
                font.pixelSize: 24
                font.bold: true
                color: "white"
            }

            Rectangle {
                height: 4
                Layout.fillWidth: true
                radius: 2
                color: Qt.darker(cardColor, 1.2)

                Rectangle {
                    height: parent.height
                    width: (progress / 100) * parent.width
                    radius: 2
                    color: "white"
                }
            }
        }
    }

    // 灯泡寿命
    component Histogram: RowLayout {
        id: gram
        property string title: ""
        property double totalTimes: 100
        property double usedTimes: 98
        property double remainTimes: totalTimes - usedTimes
        property double needWashTimes: 10
        property double continuedUsedTimes: 0
        property double perWidth: itemTotal.width / totalTimes
        property alias barContinued: itemContinued
        property alias barNeedWash: itemNeedWash
        Layout.fillWidth: true
        spacing: 4

        Text {
            text: qsTr(gram.title)
            font.pixelSize: 14
            color: "#666"
            Layout.preferredWidth: 32
        }

        Rectangle {
            id: itemTotal
            height: 16
            Layout.fillWidth: true
            radius: 4
            color: Qt.darker("#E17055", 1.2)

            Rectangle {
                id: itemRemain
                height: parent.height
                width: gram.remainTimes * gram.perWidth
                radius: 4
                topRightRadius: gram.totalTimes > gram.remainTimes ? 0 : 4
                bottomRightRadius: topRightRadius
                color: "#00B894"
            }

            Rectangle {
                id: itemContinued
                anchors.right: itemTotal.right
                height: parent.height
                width: gram.continuedUsedTimes * gram.perWidth
                radius: 4
                topLeftRadius: 0
                bottomLeftRadius: 0
                color: "#80FDCB6E"
                // 过期还在使用:((gram.remainTimes < 0) && (gram.continuedUsedTimes > 0))
                // 需要清洗,且剩下的次超过要清洗的次数:((needWashTimes > 0) && (gram.remainTimes > gram.needWashTimes))
                visible: ((needWashTimes > 0) && (gram.remainTimes > gram.needWashTimes)) || ((gram.remainTimes < 0) && (gram.continuedUsedTimes > 0)) ? true : false
            }

            Rectangle {
                id: itemNeedWash
                anchors.right: itemTotal.right
                anchors.rightMargin: gram.needWashTimes * gram.perWidth
                height: parent.height
                width: 2
                radius: 0
                color: "#80FDCB6E"
                visible: itemContinued.visible
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: String(gram.remainTimes) + " T"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: "white"
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // 第一排卡片
        RowLayout {
            id: cardsRow1
            Layout.fillWidth: true
            spacing: 12

            // 1. 仪器状态
            Rectangle {
                id: statusCard
                property bool isOnline: true
                color: isOnline ? "#00B894" : "#E17055"
                Layout.fillWidth: true
                height: 82
                radius: 12

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Text {
                        text: qsTr("仪器状态")
                        font.pixelSize: 14
                        color: "white"
                    }

                    Row {
                        spacing: 6

                        Text {
                            property bool isOnline: false
                            text: isOnline ? qsTr("联机") : qsTr("未联机")
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }
                        Rectangle {
                            property bool isOnline: false
                            width: 8
                            height: 8
                            radius: 4
                            color: isOnline ? "#00FF88" : "#FF6B6B"
                        }
                    }

                    Row {
                        spacing: 12
                        Text {
                            text: "温度: 25°C"
                            font.pixelSize: 16
                            color: "white"
                        }

                        Text {
                            text: "高压: 220V"
                            font.pixelSize: 16
                            color: "white"
                        }
                    }
                }
            }

            // 2. 当日检测数
            Rectangle {
                Layout.fillWidth: true
                height: 82
                radius: 12
                color: "#6C5CE7"

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    Text {
                        text: qsTr("当日检测数")
                        font.pixelSize: 16
                        color: "white"
                    }

                    Text {
                        text: "已测：" + "128 T"
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                    }
                    Text {
                        text: "待测：" + "108 T"
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                    }
                }
            }

            // 3. 清洗液余量
            ReagentCard {
                Layout.fillWidth: true
                title: qsTr("清洗液余量")
                value: "78%"
                progress: 78
                cardColor: "#0984E3"
            }

            // 4. 溶血素余量
            ReagentCard {
                Layout.fillWidth: true
                title: qsTr("溶血素余量")
                value: "45%"
                progress: 45
                cardColor: "#747cb2"
            }

            // 5. 缓冲液余量
            ReagentCard {
                Layout.fillWidth: true
                title: qsTr("缓冲液余量")
                value: "62%"
                progress: 62
                cardColor: "#6D9B7B"
            }

            // 6. 其它试剂余量
            ReagentCard {
                Layout.fillWidth: true
                title: qsTr("其它试剂余量")
                value: "33%"
                progress: 33
                cardColor: "#A88F00"
            }
        }

        // 第二部分：柱状图 + 右侧垂直卡片
        RowLayout {
            id: secondSection
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            Layout.maximumHeight: 300
            spacing: 12

            // 样本数柱状图
            ChartView {
                id: chartSpec
                // 获取标题栏高度（通过 plotArea.y 间接获取）
                property int titleBarHeight: plotArea.y
                property color abnormalColor: "#E17055"
                property color totalColor: "#00B894"
                property var week: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
                property var year: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

                Layout.margins: -8
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "样本检测数"
                legend.visible: false
                antialiasing: true
                backgroundRoundness: 12
                animationOptions: ChartView.AllAnimations

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 30
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    spacing: 4

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        color: chartSpec.totalColor
                    }

                    Text {
                        id: textTotal
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Console.Total")
                        color: Themer.fontDarkColor
                        font.pixelSize: 18
                    }

                    Item {
                        width: 16
                        height: 12
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        color: chartSpec.abnormalColor
                    }

                    Text {
                        id: textAbnormal
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Console.Abnormal")
                        color: Themer.fontDarkColor
                        font.pixelSize: 18
                    }
                }

                Rectangle {
                    id: btnBar
                    color: "#e8e2d4"
                    radius: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 30
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    height: innerLayout.implicitHeight + 4
                    width: innerLayout.implicitWidth + 4

                    RowLayout {
                        id: innerLayout
                        anchors.centerIn: parent
                        spacing: -10

                        Repeater {
                            id: reptBtn
                            model: 3
                            property var btnText: ["周", "月", "年"]

                            RoundButton {
                                text: qsTr(reptBtn.btnText[index])
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 48
                                Material.foreground: hovered ? Themer.buttonColor : "black"
                                Material.background: checked ? "white" : "transparent"
                                checkable: true
                                checked: index === 0
                                flat: !checked
                                radius: 6
                                autoExclusive: true
                                onClicked: {
                                    if (index === 0) {
                                        stackBS.axisX.categories = chartSpec.week;
                                    } else if (index === 1) {
                                        let days = Window.window.getCurrentMonthDays();
                                        let month = [];
                                        for (let i = 0; i < days; i++)
                                            month.push(String(i + 1));
                                        stackBS.axisX.categories = month;
                                    } else if (index === 2) {
                                        stackBS.axisX.categories = chartSpec.year;
                                    }
                                }
                            }
                        }
                    }
                }

                StackedBarSeries {
                    id: stackBS
                    axisX: BarCategoryAxis {
                        gridVisible: false
                        categories: chartSpec.week
                    }
                    axisY: ValueAxis {
                        gridVisible: false
                    }
                    BarSet {
                        id: bar1
                        values: [2, 2, 3, 4, 5, 6]
                        color: chartSpec.abnormalColor
                    }
                    BarSet {
                        id: bar2
                        values: [5, 1, 2, 4, 1, 7]
                        color: chartSpec.totalColor
                    }
                }
            }

            // 右侧：灯泡寿命 + 毛细管寿命柱状图
            Rectangle {
                width: 300
                height: 300
                radius: 8
                color: Themer.workFormColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Text {
                        text: qsTr("配件状态")
                        font.pixelSize: 16
                        font.bold: true
                        color: "#333"
                    }

                    Repeater {
                        id: reptGram
                        property var totalTimesList: [100, 100, 100, 100, 100, 100, 100, 100, 100]
                        property var usedTimesList: [9, 196, 40, 83, 50, 45, 34, 90, 90]
                        property var needWashTimesList: [0, 10, 10, 10, 10, 10, 10, 10, 10]
                        property var continuedUsedTimesList: [0, 5, 4, 10, 5, 14, 9, 5, 5]
                        property var names: ["灯泡", "CH1", "CH2", "CH3", "CH4", "CH5", "CH6", "CH7", "CH8"]
                        model: names.length

                        Histogram {
                            title: reptGram.names[index]
                            totalTimes: reptGram.totalTimesList[index]
                            usedTimes: reptGram.usedTimesList[index]
                            needWashTimes: reptGram.needWashTimesList[index]
                            continuedUsedTimes: reptGram.continuedUsedTimesList[index]
                        }
                    }
                }
            }
        }

        // 样本区（占据剩余高度）
        Rectangle {
            id: sampleArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 16

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                // 标题行（包含标题、检测按钮和控制按钮）
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    height: 40

                    Text {
                        text: qsTr("检测仪")
                        font.pixelSize: 16
                        font.bold: true
                        color: "#333"
                    }

                    Text {
                        text: qsTr("请将程序和样本放入检测仪内")
                        font.pixelSize: 12
                        color: "#999"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 48
                        height: 36
                        radius: 6
                        color: "#E8F5F3"

                        Text {
                            anchors.centerIn: parent
                            text: "🗑"
                            font.pixelSize: 16
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 36
                        radius: 6
                        color: "#6C5CE7"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "▶"
                                font.pixelSize: 14
                                color: "white"
                            }
                            Text {
                                text: qsTr("检测")
                                font.pixelSize: 14
                                font.bold: true
                                color: "white"
                            }
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 32
                        radius: 6
                        color: "#f1f1f1"

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("复位")
                            font.pixelSize: 13
                            color: "#666"
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 32
                        radius: 6
                        color: "#f1f1f1"

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("清洗")
                            font.pixelSize: 13
                            color: "#666"
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 32
                        radius: 6
                        color: "#FDCB6E"

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("暂停")
                            font.pixelSize: 13
                            color: "#666"
                        }
                    }

                    Rectangle {
                        width: 72
                        height: 32
                        radius: 6
                        color: "#E17055"

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("停止")
                            font.pixelSize: 13
                            color: "white"
                        }
                    }
                }

                // 样本位区域（占据剩余高度）
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.bottomMargin: 16
                    spacing: 18

                    Repeater {
                        model: 8

                        Rectangle {
                            id: sampleSlot
                            width: 120
                            Layout.fillHeight: true
                            radius: 6
                            color: index === 0 ? "#6C5CE7" : (index < 4 ? "#F5F3FF" : "#f8f8f8")
                            border.width: index < 4 ? 1 : 0
                            border.color: "#D4D0E8"

                            Rectangle {
                                width: 28
                                height: 8
                                radius: 4
                                color: index === 0 ? "#8E85D9" : "#D4D0E8"
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: 4
                            }

                            Column {
                                anchors.fill: parent
                                anchors.topMargin: 20
                                anchors.bottomMargin: 20
                                anchors.leftMargin: 6
                                anchors.rightMargin: 6
                                spacing: 3

                                Text {
                                    visible: index === 0
                                    text: "张三三"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "white"
                                }
                                Text {
                                    visible: index === 0
                                    text: "身高: 175"
                                    font.pixelSize: 8
                                    color: "#DDD"
                                }
                                Text {
                                    visible: index === 0
                                    text: "体重: 140"
                                    font.pixelSize: 8
                                    color: "#DDD"
                                }
                                Text {
                                    visible: index === 0
                                    text: "民族: 汉"
                                    font.pixelSize: 8
                                    color: "#DDD"
                                }
                                Text {
                                    visible: index === 0
                                    text: "备注:"
                                    font.pixelSize: 8
                                    color: "#DDD"
                                }
                                Rectangle {
                                    visible: index === 0
                                    height: 6
                                    width: parent.width
                                    radius: 3
                                    color: "#4A40A0"

                                    Rectangle {
                                        height: parent.height
                                        width: 0.6 * parent.width
                                        radius: 3
                                        color: "#8E85D9"
                                    }
                                }
                                Text {
                                    visible: index === 0
                                    text: "02:23"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    visible: index > 0 && index < 4
                                    text: "张三三"
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: "#6C5CE7"
                                }
                                Text {
                                    visible: index > 0 && index < 4
                                    text: "HBV"
                                    font.pixelSize: 9
                                    color: "#999"
                                }
                                Rectangle {
                                    visible: index > 0 && index < 4
                                    height: 30
                                    width: parent.width
                                    radius: 15
                                    color: "#E8E8FF"

                                    Rectangle {
                                        width: 10
                                        height: 18
                                        radius: 5
                                        color: "#FFC97D"
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: "#6C5CE7"
                                        anchors.right: parent.right
                                        anchors.rightMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: "white"
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: index >= 4
                                    height: 30
                                    width: parent.width
                                    radius: 15
                                    color: "#E8E8E8"
                                }

                                Text {
                                    text: ["II", "III", "IV", "V", "VI", "VII", "VIII", "IX"][index]
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: index === 0 ? "white" : (index < 4 ? "#6C5CE7" : "#BBB")
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 8
                                radius: 4
                                color: index === 0 ? "#8E85D9" : "#D4D0E8"
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 4
                            }
                        }
                    }
                }
            }
        }
    }
}
