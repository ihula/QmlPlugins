import QtQuick

Item {
    id: headerItem
    property alias text: txt.text
    //signal widthChanged()

    width: 150
    height: 40

    Rectangle {
        anchors.fill: parent
        color: "#303133"
    }
    Text {
        id: txt
        anchors.centerIn: parent
        color: "white"
        font.bold: true
        font.pixelSize: 14
    }

    // 拖动线
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: "transparent"
        //cursorShape: Qt.SizeHorCursor

        MouseArea {
            anchors.fill: parent
            drag.target: headerItem
            drag.axis: Drag.XAxis
            //onPositionChanged: headerItem.widthChanged()
        }
    }
}
