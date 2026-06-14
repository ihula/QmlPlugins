import QtQuick
import QtQuick.Controls
import QmlPlugins

Popup {
    id: snackbar
    property string text
    property int duration: 5000
    property bool autoDestroy: true
    property int deltaY: 0
    closePolicy: Popup.NoAutoClose

    function openText(text) {
        snackbar.text = text;
        open();
        numAnim.start();
        timer.start();
    }

    x: 10
    y: parent.height - 200 - deltaY * 48

    NumberAnimation on y {
        id: numAnim
        to: parent.height - snackbar.height - 12
        duration: snackbar.duration - 500
        easing.type: Easing.OutQuad
        running: false
    }

    background: Rectangle {
        color: "#cc323232"
        radius: 4
    }

    height: snackText.implicitHeight + 24
    width: Math.min(snackText.implicitWidth + 36, 288)
    opacity: opened ? 1 : 0
    MouseArea {
        property point clickPos: "0,0"
        anchors.fill: parent
        hoverEnabled: true
        onPressed: mouse => {
            clickPos = Qt.point(mouse.x, mouse.y);
        }

        onEntered: {
            if (numAnim.running)
                numAnim.pause();
            timer.stop();
        }

        onExited: {
            numAnim.resume();
            timer.restart();
        }

        onPositionChanged: mouse => {
            if (mouse.buttons === Qt.LeftButton) {
                //鼠标偏移量delta
                var deltax = mouse.x - clickPos.x;
                var deltay = mouse.y - clickPos.y;
                snackbar.x = snackbar.x + deltax;
                snackbar.y = snackbar.y + deltay;
            }
        }
    }

    Timer {
        id: timer
        interval: snackbar.duration
        onTriggered: {
            close();
            if (autoDestroy)
                snackbar.destroy(2000);
        }
    }

    Text {
        id: snackText
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: (lineCount > 1) ? Text.AlignLeft : Text.AlignHCenter
        text: qsTr(snackbar.text) + Translater.change
        wrapMode: Text.Wrap
        color: "white"
        anchors.fill: parent
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 300
        }
    }
}
