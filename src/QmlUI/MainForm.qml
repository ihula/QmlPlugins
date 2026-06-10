import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.qmlmodels
import QmlPlugins 1.0
import "../HulaUI"

Window {
    id: mainForm
    property int formShowMode: Configer.mainFormShowMode()
    property double alpha: Configer.useWallPaper() ? (0xb0 / 255) : 1
    width: 1568
    height: 864
    title: qsTr("AppName") + translater.change
    flags: Qt.Window | Qt.FramelessWindowHint
    color: Themer.theme.backColor
    property string userName: ""
    property color borderColor: "#d1d1d1"
    property int floatTipSum: 0
    property int msgBoxSum: 0
    property QtObject dictForm: null
    property QtObject editTitleForm: null
    property int workForm: MainForm.WorkForm.None
    objectName: "MainForm"

    enum WorkForm {
        None,
        Home,
        Search,
        Statistic,
        Setting
    }

    QtObject {
        id: pageState
        property bool page1Loaded: false
        property bool page2Loaded: false
        property bool profileLoaded: false
    }

    function showForm() {
        leftRepeater.itemAt(0).clicked();
        leftRepeater.itemAt(0).checked = true;
        if (mainForm.formShowMode === 0) {
            mainForm.showNormal();
        } else if (mainForm.formShowMode === 1) {
            mainForm.showMaximized();
        } else {
            mainForm.showFullScreen();
        }
        onLogined();
    }

    onVisibleChanged: visible => {
        if (visible) {
            main.loaderSplash.source = "";
            main.loaderLogin.source = "";
        }
    }

    UserInfo {
        id: userInfo
    }

    ResizeBorder {
        enabled: visible
        anchors.fill: parent
        control: mainForm
    }

    Rectangle {
        anchors.fill: parent
        color: Themer.theme.workBackColor
        border.width: 1
        border.color: "#888888"

        Item {
            anchors.left: leftArea.right
            anchors.right: parent.right
            anchors.top: leftArea.top
            anchors.bottom: leftArea.bottom
            anchors.margins: 1

            TopBar {
                id: topBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                width: parent.width
                appName: mainForm.title
                height: 54
            }

            StackView {
                id: router
                anchors.margins: 8
                anchors.topMargin: topBar.height + 8
                anchors.fill: parent
            }
        }

        Rectangle {
            id: leftArea
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.margins: 1
            width: 180
            gradient: Themer.theme.viewGradient

            Rectangle {
                width: 1
                color: "#d4d4d4"
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }

            Column {
                anchors.fill: parent
                anchors.margins: 1
                spacing: 0

                Row {
                    id: itemLeftTopBar
                    height: topBar.height
                    spacing: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                    Image {
                        smooth: true
                        fillMode: Image.PreserveAspectFit
                        source: "file:" + "Images/logo.svg"
                        //width: 36
                        height: txtAppName.height
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        id: txtAppName
                        font.pixelSize: 20
                        color: Themer.theme.buttonBackground
                        text: qsTr("CompanyAbbrName") + translater.change
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                ButtonGroup {
                    id: btnWorkGroups
                    exclusive: true
                }

                Repeater {
                    id: leftRepeater
                    property var iconList: ["Images/test.svg", "Images/search.svg", "Images/statistic.svg", "Images/setting.svg", "Images/user.svg"]
                    property var pages: [loader1, loader2, loader3, loader4, loader5]
                    model: ["MainForm.Testing", "MainForm.Search", "MainForm.Statistics", "MainForm.Setting", "User"]
                    RoundButton {
                        id: btnTest
                        ButtonGroup.group: btnWorkGroups
                        anchors.left: parent.left
                        anchors.right: parent.right
                        display: AbstractButton.TextBesideIcon
                        text: qsTr(modelData) + translater.change
                        font.pixelSize: 18
                        icon.source: "file:" + leftRepeater.iconList[index]
                        icon.height: 36
                        icon.width: 36
                        flat: true
                        radius: 8
                        Material.foreground: "white"
                        height: 54
                        hoverEnabled: true
                        checkable: true
                        background: Rectangle {
                            anchors.fill: parent
                            color: parent.checked ? "#30ffffff" : (parent.hovered ? "#10000000" : "transparent")
                            radius: parent.radius
                        }

                        onClicked: {
                            leftRepeater.pages[index].active = true;
                            router.replace(leftRepeater.pages[index], StackView.PopTransition);
                        }
                    }
                }

                RoundButton {
                    id: btnAbout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    display: AbstractButton.TextBesideIcon
                    font.pixelSize: 18
                    text: qsTr("MainForm.About") + translater.change
                    icon.source: "file:" + "Images/about.svg"
                    radius: 8
                    Material.foreground: "white"
                    height: 54
                    icon.height: 36
                    icon.width: 36
                    flat: true
                    hoverEnabled: true
                    background: Rectangle {
                        anchors.fill: parent
                        color: parent.checked ? "#30ffffff" : (parent.hovered ? "#10000000" : "transparent")
                        radius: parent.radius
                    }
                    onClicked: openDialog("About.qml")
                }
            }
            Label {
                id: lblDate
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: lblTime.top
                font.pixelSize: 14
                color: "white"
                text: ""
            }
            Label {
                id: lblTime
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                font.pixelSize: 14
                color: "white"
                text: ""
            }
        }
    }

    Loader {
        id: loader1
        active: false
        source: "Home.qml"
    }

    Loader {
        id: loader2
        active: false
        source: "Page2.qml"
    }

    Loader {
        id: loader3
        active: false
        source: "Search.qml"
    }

    Loader {
        id: loader4
        active: false
        source: "Statistic.qml"
    }

    Loader {
        id: loader5
        active: false
        source: "UserManagerForm.qml"
    }

    Image {
        id: imgWallPaper
        visible: Configer.useWallPaper()
        anchors.fill: parent
        source: "file:" + "wallpaper/1.jpeg"
        fillMode: Image.Stretch
        opacity: 0.1
        z: 0
        PropertyAnimation on opacity {
            id: aniWallPaper
            from: 0
            to: 0.1
            duration: 1000
            running: Configer.useWallPaper() && Configer.liveWallPaper()
            onFinished: {
                timerWallPaper.start();
            }
        }
        Timer {
            id: timerWallPaper
            interval: 5
            property bool isIn: true
            property int index: 1
            property var imgList: []
            onTriggered: {
                stop();
                if (imgList.length === 0) {
                    var filter = [];
                    filter.push("*.jpeg");
                    filter.push("*.jpg");
                    filter.push("*.bmp");
                    filter.push("*.png");
                    imgList = Utils.getDirFiles("./wallpaper/", filter);
                    if (imgList.length === 0) {
                        aniWallPaper.stop();
                        aniWallPaper.running = false;
                        return;
                    }
                }

                isIn = !isIn;
                if (isIn) {
                    interval = 5000;
                    aniWallPaper.from = 0;
                    aniWallPaper.to = 0.1;
                    if (index === imgList.length)
                        index = 0;
                    imgWallPaper.source = "file:wallpaper/" + imgList[index];
                    index++;
                } else {
                    interval = 0;
                    aniWallPaper.from = 0.1;
                    aniWallPaper.to = 0;
                }
                aniWallPaper.start();
            }
        }
    }

    Connections {
        target: Configer
        function onChangedBool() {
            loadWallPaperParam();
        }
    }

    function loadWallPaperParam() {
        imgWallPaper.visible = Configer.useWallPaper();
        aniWallPaper.running = Configer.useWallPaper() && Configer.liveWallPaper();
        if (!Configer.liveWallPaper()) {
            timerWallPaper.stop();
            aniWallPaper.stop();
            imgWallPaper.opacity = aniWallPaper.to;
        } else {
            timerWallPaper.start();
        }
    }

    function openLogin(params = ({})) {
        var dlg = Qt.createComponent("Login.qml").createObject(mainForm);
        for (var key in params) {
            if (hasProperty(dlg, key)) {
                dlg[key] = params[key];
            }
        }
        dlg.showForm();
        dlg.onClosed.connect(() => {
            dlg.destroy();
        });
        dlg.onClosed.connect(onLogined);
    }

    function openDialog(qml, params = ({})) {
        var dlg = Qt.createComponent(qml).createObject(mainForm);
        for (var key in params) {
            if (hasProperty(dlg, key)) {
                dlg[key] = params[key];
            }
        }
        dlg.x = (mainForm.width - dlg.width) / 2;
        dlg.y = (mainForm.height - dlg.height) / 2;
        dlg.open();
        dlg.onClosed.connect(() => {
            dlg.destroy();
        });
        dlg.onClosed.connect(onLogined);
    }

    function onLogined() {
        mainForm.userName = Configer.userName();
    }

    function openDialogPrompt(text, callbackOnOK = null, title = "MessageBox.Confirm") {
        var msgBox = Qt.createComponent("../HulaUI/HulaMessageBox.qml").createObject(mainForm);
        msgBox.z = 100000;
        msgBox.x = (mainForm.width - msgBox.width) / 2;
        msgBox.y = (mainForm.height - msgBox.height) / 2;
        msgBox.formTitle = title;
        msgBox.messageText = text;
        msgBox.buttonOkText = "MessageBox.Ok";
        msgBox.callbackOnOK = callbackOnOK;
        msgBox.open();
        return msgBox;
    }

    function openDialogConfirm(text, callbackOnOK = null, callbackOnCancel = null, title = "MessageBox.Confirm") {
        var msgBox = Qt.createComponent("../HulaUI/HulaMessageBox.qml").createObject(mainForm);
        msgBox.z = 100000;
        msgBox.x = (mainForm.width - msgBox.width) / 2;
        msgBox.y = (mainForm.height - msgBox.height) / 2;
        msgBox.formTitle = title;
        msgBox.messageText = text;
        msgBox.buttonOkText = "MessageBox.Ok";
        msgBox.callbackOnOK = callbackOnOK;
        msgBox.buttonCancelText = "MessageBox.Cancel";
        msgBox.callbackOnCancel = callbackOnCancel;
        msgBox.open();
        return msgBox;
    }

    function appendTopbarLeftItem(item) {
        topBar.appendLeftItem(item);
    }

    function removeTopbarLeftItem(item) {
        topBar.removeLeftItem(item);
    }

    function hasProperty(obj, key) {
        return (key in obj);
    }

    function snackMessage(text) {
        var comp = Qt.createComponent("../HulaUI/HulaSnackbar.qml");
        if (comp.status === Component.Ready) {
            var obj = comp.createObject(mainForm);
            if (obj) {
                obj.openText(text);
            } else {
                console.log("Failed to create HulaSnackbar object");
            }
        } else if (comp.status === Component.Error) {
            console.log("HulaSnackbar component error:", comp.errorString());
        }
    }

    Timer {
        id: nowTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            displayCurrDatetime();
        }
    }

    function displayCurrDatetime() {
        var d = new Date();
        var years = d.getFullYear();
        var month = addZero(d.getMonth() + 1);
        var days = addZero(d.getDate());
        var hours = addZero(d.getHours());
        var minutes = addZero(d.getMinutes());
        var seconds = addZero(d.getSeconds());
        lblDate.text = years + "-" + month + "-" + days;
        lblTime.text = hours + ":" + minutes + ":" + seconds;
    }

    function addZero(temp) {
        if (temp < 10)
            return "0" + temp;
        else
            return temp;
    }

    function getUsers() {
        var users = [];
        var infos = userInfo.getDatas();
        for (var i = 0; i < infos.length; i++) {
            var name = infos[i]["Name"];
            if (name.indexOf("admin") > -1)
                continue;
            if (name.indexOf("Admin") > -1)
                continue;
            users.push(name);
        }
        return users;
    }

    function strToInt(str) {
        var ret = parseInt(str);
        if (ret.toString() === "NaN")
            ret = 0;
        return ret;
    }

    function isDateString(str) {
        // 使用正则表达式判断字符串是否符合日期格式
        const regex = /^\d{4}-\d{2}-\d{2}$/;
        return regex.test(str);
    }
}
