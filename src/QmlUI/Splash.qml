import QtQuick
import QtQuick.Window
import QtQuick.Controls.Material
import QtQuick.Shapes
import QmlPlugins 1.0

Window {
    id: root
    property int formShowMode: Configer.splashFormShowMode()
    modality: Qt.ApplicationModal
    flags: Qt.Window | Qt.FramelessWindowHint//Qt.SplashScreen
    width: 1568
    height: 864
    property bool useLogin: Configer.enableLogin()
    property bool nextFormLoaded: false
    property bool isRender: false
    property var imageList: []

    onVisibleChanged: {
        if (visible) {
            main.loaderLogin.active = useLogin;
            main.loaderMain.active = true;
        } else {
            if (useLogin)
                main.loaderLogin.item.showForm();
            else
                main.loaderMain.item.showForm();
        }
    }

    Binding {
        target: root
        property: "nextFormLoaded"
        value: true
        when: main.loaderMain.item
    }

    onNextFormLoadedChanged: {
        if (root.nextFormLoaded) {
            ani.pause();
            ani.duration = 300;
            ani.restart();
        }
    }

    function showForm() {
        if (root.formShowMode === 1) {
            root.maximumWidth = Screen.desktopAvailableWidth;
            root.maximumHeight = Screen.desktopAvailableHeight;
        }
        ani.start();
        if (formShowMode === 0)
            root.show();
        else if (formShowMode === 1)
            root.showMaximized();
        else
            root.showFullScreen();
    }

    Image {
        id: rect
        anchors.fill: parent
        anchors.margins: 0
        clip: true
        source: "file:Images/splash.png"
    }

    Row {
        id: barLogo
        anchors.centerIn: parent
        spacing: 16
        Image {
            id: imgLogo
            height: 100
            smooth: true
            fillMode: Image.PreserveAspectFit
            source: "file:" + "Images/logo.svg"
        }

        Text {
            id: txtAppName
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 28
            font.bold: false
            text: qsTr("CompanyName") + translater.change
        }
    }
    Text {
        anchors.top: barLogo.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        font.bold: false
        font.pixelSize: 18
        text: qsTr("Splash.Slogan") + translater.change
    }

    ProgressBar {
        id: progressBar
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 136
        from: 1
        to: 100
        value: 1
        height: 20
        width: barLogo.width
        background: Rectangle {
            color: "transparent"
            radius: 12
            border.color: "lightblue"
            border.width: 1
        }

        contentItem: Rectangle {
            width: progressBar.visualPosition * parent.width
            height: parent.height
            radius: 12
            clip: true
            antialiasing: true
            gradient: LinearGradient {
                x1: 0
                x2: width
                y1: 0
                y2: height
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "#0561FF"
                }
                GradientStop {
                    position: 0.5
                    color: "#1FB4FF"
                }
                GradientStop {
                    position: 1.0
                    color: "#2CE5E5"
                }
            }
        }
    }

    NumberAnimation {
        id: ani
        target: progressBar
        property: "value"
        duration: 5000
        from: 0
        to: 99
        running: true
        easing.type: Easing.Linear
        onFinished: {
            close();
        }
    }
}
