import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Fusion as Fusion
import QtQuick.Layouts
import "../Components"
import HulaPlugins

Item {
    id: root

    component ChartBox: Rectangle {
        property string name: ""
        property color chartColor: "#00FFFF"

        width: (parent.width - 4 * 7) / 8
        height: 70

        color: name !== "" ? "#E8E8E8" : "transparent"
        border.width: name !== "" ? 1 : 0
        border.color: "#CCCCCC"
        radius: 2

        Item {
            anchors.fill: parent
            anchors.margins: 1

            Rectangle {
                visible: name !== ""
                anchors.fill: parent
                color: "black"
            }

            Canvas {
                anchors.fill: parent
                visible: name !== ""

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.beginPath();
                    ctx.strokeStyle = chartColor;
                    ctx.lineWidth = 1.5;

                    var points = [0, 40, 80, 60, 90, 30, 70, 50, 85, 20, 0];
                    var maxY = 100;
                    var stepX = width / (points.length - 1);

                    for (var j = 0; j < points.length; j++) {
                        var x = j * stepX;
                        var y = height - (points[j] / maxY) * height;
                        if (j === 0) {
                            ctx.moveTo(x, y);
                        } else {
                            ctx.lineTo(x, y);
                        }
                    }
                    ctx.stroke();
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 2
                font.pixelSize: 9
                color: Themer.editorFontColor
                text: name
                visible: name !== ""
            }

            MouseArea {
                anchors.fill: parent
                visible: name !== ""
                onClicked: {
                    listview.currentIndex = index;
                }
            }
        }
    }

    Rectangle {
        id: itemPatients
        radius: 8
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 4
        width: 280
        color: Themer.workFormColor

        Label {
            id: lblSpecimenList
            anchors.left: parent.left
            anchors.top: parent.top
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            height: 36
            anchors.margins: 8
            anchors.leftMargin: 18
            text: qsTr("Specimen.SpecimenList")
            font.pixelSize: 18
            font.bold: false
            Material.foreground: Themer.editorFontColor
        }

        Rectangle {
            id: lineSpecimenList
            anchors.top: lblSpecimenList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            anchors.topMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            color: Themer.lineColor
        }

        ListView {
            id: listview
            clip: true
            property color itemColor: Qt.alpha("#F4F4F4", Window.window.alpha)
            property color highColor: Qt.alpha(Themer.hoveredColor, Window.window.alpha)
            anchors.top: lineSpecimenList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8
            highlight: Item {
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: listview.highColor
                    radius: 6
                }
            }

            ScrollBar.vertical: Fusion.ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            model: ListModel {
                ListElement {
                    name: "NORMAL CTL 1"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "NORMAL CTL 2"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "NORMAL CTL 3"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "NORMAL CTL 4"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "259"
                    status: "已检测"
                    color: "#9B59B6"
                }
                ListElement {
                    name: "263"
                    status: "已检测"
                    color: "#9B59B6"
                }
                ListElement {
                    name: "254"
                    status: "已检测"
                    color: "#9B59B6"
                }
                ListElement {
                    name: "257"
                    status: "已检测"
                    color: "#9B59B6"
                }
                ListElement {
                    name: "256"
                    status: "已检测"
                    color: "#9B59B6"
                }
                ListElement {
                    name: "258"
                    status: "已检测"
                    color: "#9B59B6"
                }
                ListElement {
                    name: "PATHO CTL 1"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "PATHO CTL 2"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "PATHO CTL 3"
                    status: "已检测"
                    color: "#00FFFF"
                }
                ListElement {
                    name: "PATHO CTL 4"
                    status: "已检测"
                    color: "#00FFFF"
                }
            }

            delegate: ItemDelegate {
                id: item
                required property int index
                required property string name
                required property string status
                required property string color
                width: ListView.view.width
                height: 60
                property color backColor: ListView.isCurrentItem ? listview.highColor : listview.itemColor
                property color textColor: ListView.isCurrentItem ? "white" : "black"
                contentItem: Rectangle {
                    radius: 6
                    anchors.fill: parent
                    anchors.margins: 2
                    color: item.backColor
                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2
                        Text {
                            color: item.textColor
                            text: item.name
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Text {
                            color: item.textColor
                            text: item.status
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: rectCharts
        radius: 8
        anchors.left: itemPatients.right
        anchors.right: parent.right
        anchors.top: itemPatients.top
        anchors.bottom: itemPatients.bottom
        anchors.leftMargin: 8
        anchors.topMargin: 0
        color: Themer.workFormColor
        clip: true

        Label {
            id: lblChartView
            anchors.left: parent.left
            anchors.top: parent.top
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            height: 36
            anchors.margins: 8
            anchors.leftMargin: 18
            text: qsTr("Chart.ChartView")
            font.pixelSize: 18
            font.bold: false
            Material.foreground: Themer.editorFontColor
        }

        Rectangle {
            id: lineChartView
            anchors.top: lblChartView.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            anchors.topMargin: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            color: Themer.lineColor
        }

        ScrollView {
            anchors.top: lineChartView.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            clip: true

            ScrollBar.vertical: Fusion.ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 8
                    implicitHeight: 30
                    radius: 4
                    color: "#e0e0e0"

                    Rectangle {
                        implicitWidth: 8
                        implicitHeight: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 6
                        color: "#999999"
                    }
                }
            }

            Item {
                width: parent.width

                Column {
                    spacing: 4
                    width: parent.width

                    Row {
                        spacing: 4
                        width: parent.width

                        ChartBox {
                            name: "NORMAL CTL 1"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 2"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 3"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 4"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 5"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 6"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 7"
                            chartColor: "#00FFFF"
                        }
                        ChartBox {
                            name: "NORMAL CTL 8"
                            chartColor: "#00FFFF"
                        }
                    }

                    Row {
                        spacing: 4
                        width: parent.width

                        ChartBox {
                            name: "259"
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: "263"
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: "254"
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: "88023557"
                            chartColor: "#9B59B6"
                        }
                    }

                    Row {
                        spacing: 4
                        width: parent.width

                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: ""
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: "262"
                            chartColor: "#9B59B6"
                        }
                        ChartBox {
                            name: "105"
                            chartColor: "#9B59B6"
                        }
                    }
                }
            }
        }
    }
}
