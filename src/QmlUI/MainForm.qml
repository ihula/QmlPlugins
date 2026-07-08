import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt.labs.qmlmodels
import QtQuick.Effects
import QtQml
import HulaPlugins 1.0
import "../Components"

Window {
    id: mainForm
    objectName: "mainForm"
    property int formShowMode: Configer.mainFormShowMode()
    property double alpha: Configer.useWallPaper() ? (0xb0 / 255) : 1
    property string userName: UserInfo.userName

    signal showing
    signal closeing
    signal showed

    width: 1568//1920
    height: 864//1080
    title: qsTr("AppName")
    flags: Qt.Window | Qt.FramelessWindowHint
    opacity: 0
    // 窗口背景,防止 startSystemMove 时窗体有残影
    color: "transparent"

    function showForm() {
        leftRepeater.itemAt(0).clicked();
        leftRepeater.itemAt(0).checked = true;
        if (mainForm.formShowMode === 0) {
            mainForm.x = (Screen.width - mainForm.width) / 2;
            mainForm.y = (Screen.height - mainForm.height) / 2;
            mainForm.showNormal();
        } else if (mainForm.formShowMode === 1) {
            mainForm.showMaximized();
        } else {
            mainForm.showFullScreen();
        }
        fadeInAni.start();
    }

    function getMonthDays(year, month) {
        // month: 0-11 (0=一月, 11=十二月)
        return new Date(year, month, 0).getDate();
    }

    // 获取当前年月的天数
    function getCurrentMonthDays() {
        var now = new Date();
        return getMonthDays(now.getFullYear(), now.getMonth() + 1, 0);
    }

    onVisibleChanged: {
        if (visible) {
            showForm();
            showing();
        }
    }

    Connections {
        target: UserInfo
        function onLogined(account, userName) {
            mainForm.userName = userName;
        }
    }

    Loader {
        anchors.fill: parent
        active: true
        source: (OS_TYPE !== "macos") ? "../Components/ItemResizer.qml" : "../Components/ResizeBorder.qml"
        onLoaded: {
            item.control = mainForm;
            item.titlebar = topBar;
            item.isFullscreen = (formShowMode === 2);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Themer.workBackColor
        border.width: 1
        border.color: "#888888"
        layer.enabled: true

        Item {
            anchors.left: leftArea.right
            anchors.right: parent.right
            anchors.top: leftArea.top
            anchors.bottom: leftArea.bottom
            anchors.rightMargin: 1

            TopBar {
                id: topBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                width: parent.width
                appName: Window.window.title
                height: 72
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
            gradient: Themer.viewGradient

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
                        height: txtAppName.height
                        anchors.verticalCenter: parent.verticalCenter
                        // layer.enabled: true
                        // layer.effect: MultiEffect {
                        //     colorization: 1.0       // 着色强度 (0.0 - 1.0)
                        //     colorizationColor: "#00A5FF" // 目标颜色
                        // }
                    }

                    Label {
                        id: txtAppName
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        color: Themer.fontLightColor
                        text: qsTr("CompanyAbbrName")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                ButtonGroup {
                    id: btnWorkGroups
                    exclusive: true
                }

                Repeater {
                    id: leftRepeater
                    property int currentIndex: -1
                    property var iconList: ["Images/console.svg", "Images/test.svg", "Images/search.svg", "Images/statistic.svg", "Images/setting.svg", "Images/about.svg"]
                    property var pages: [loaderConsole, loaderChartCard, loaderSearch, loaderStatistics, loaderSetting]
                    model: ["MainForm.Console", "MainForm.Specimen", "MainForm.Search", "MainForm.Statistics", "MainForm.Setting", "MainForm.About"]

                    delegate: RoundButton {
                        id: btnTest
                        ButtonGroup.group: btnWorkGroups
                        anchors.left: parent.left
                        anchors.right: parent.right
                        display: AbstractButton.TextBesideIcon
                        text: qsTr(modelData)
                        font.pixelSize: 18
                        icon.source: "file:" + leftRepeater.iconList[index]
                        icon.height: 36
                        icon.width: 36
                        flat: true
                        radius: 8
                        Material.foreground: "white"
                        height: 54
                        hoverEnabled: true
                        checkable: (index !== leftRepeater.pages.length)
                        contentItem: Row {
                            anchors.fill: parent
                            anchors.leftMargin: 32
                            spacing: 4
                            Image {
                                id: btnIcon
                                antialiasing: true
                                smooth: true
                                mipmap: true  // 针对图片元素开启多级纹理过滤
                                anchors.verticalCenter: parent.verticalCenter
                                source: btnTest.icon.source
                                width: btnText.height
                                height: btnText.height
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    antialiasing: true
                                    smooth: true
                                    source: btnIcon
                                    brightness: 1.0
                                    colorization: 1.0
                                    colorizationColor: "white"
                                }
                            }

                            Text {
                                id: btnText
                                color: "white"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                text: btnTest.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            color: parent.checked ? "#30ffffff" : (parent.hovered ? "#10000000" : "transparent")
                            radius: parent.radius
                        }

                        onClicked: {
                            if (index === leftRepeater.pages.length) {
                                openDialog("About.qml");
                                return;
                            }

                            if (leftRepeater.currentIndex === index)
                                return;

                            leftRepeater.currentIndex = index;
                            if (index === 1) {
                                topBar.appendLeftItem(tabbar);

                                if (tabbar.currentIndex === 1) {
                                    loaderSpecimen.active = true;
                                    router.replace(loaderSpecimen);
                                    return;
                                }
                            } else {
                                topBar.removeLeftItem(tabbar);
                            }

                            leftRepeater.pages[index].active = true;
                            router.replace(leftRepeater.pages[index]);
                        }
                    }
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

    TabBar {
        id: tabbar
        visible: false
        font.pixelSize: 18
        TabButton {
            text: "图表显示"
            onClicked: {
                loaderChartCard.active = true;
                router.replace(loaderChartCard);
            }
        }
        TabButton {
            text: "表格显示"
            onClicked: {
                loaderSpecimen.active = true;
                router.replace(loaderSpecimen);
            }
        }
    }

    Loader {
        id: loaderConsole
        active: false
        source: "Console.qml"
    }

    Loader {
        id: loaderSpecimen
        active: false
        source: "PatientForm.qml"
    }

    Loader {
        id: loaderSearch
        active: false
        source: "Search.qml"
    }

    Loader {
        id: loaderStatistics
        active: false
        source: "Page0.qml" //"Statistic.qml"
    }

    Loader {
        id: loaderSetting
        active: false
        source: "Setting.qml"
    }

    Loader {
        id: loaderChartCard
        active: false
        source: "ChartCard.qml"
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
        function onWallPaperUpdated() {
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
        if (dlg) {
            for (var key in params) {
                if (hasProperty(dlg, key)) {
                    dlg[key] = params[key];
                }
            }
            dlg.show();
        } else {
            let msg = {};
            msg["text"] = "Failed to create Login object";
            msg["statusCode"] = Enums.StatusCode.NotImplemented;
            msg["promptType"] = Enums.PromptType.Error;
            MessageCenter.handleQmlMessage(msg);
            console.log("Failed to create Login object");
        }
    }

    function openDialog(qml, params = ({})) {
        var component = Qt.createComponent(qml);
        if (component.status === Component.Ready) {
            var dlg = component.createObject(mainForm);
            for (var key in params) {
                if (hasProperty(dlg, key)) {
                    dlg[key] = params[key];
                }
            }
            dlg.open();
            dlg.onClosed.connect(() => {
                dlg.destroy();
            });
        } else if (component.status === Component.Error) {
            console.error("加载 Qml 失败:", component.errorString());
            let msg = {};
            msg["text"] = "加载 Qml 失败:" + component.errorString();
            msg["statusCode"] = Enums.StatusCode.NotImplemented;
            msg["promptType"] = Enums.PromptType.Error;
            MessageCenter.handleQmlMessage(msg);
        }
    }

    function openDialogPrompt(text, callbackOnOk = null, title = "MessageBox.Confirm") {
        var msgBox = hulaDialogComp.createObject(mainForm);
        if (msgBox) {
            msgBox.title = title;
            msgBox.messageText = text;
            msgBox.buttonOkText = "MessageBox.Ok";
            msgBox.callbackOnOk = callbackOnOk;
            msgBox.open();
            return msgBox;
        } else {
            let msg = {};
            msg["text"] = "Failed to create HulaDialog object";
            msg["statusCode"] = Enums.StatusCode.NotImplemented;
            msg["promptType"] = Enums.PromptType.Error;
            MessageCenter.handleQmlMessage(msg);
            console.log("Failed to create HulaDialog object");
        }
    }

    function openDialogConfirm(text, callbackOnOk = null, callbackOnCancel = null, title = "MessageBox.Confirm") {
        var msgBox = hulaDialogComp.createObject(mainForm);
        if (msgBox) {
            msgBox.title = title;
            msgBox.messageText = text;
            msgBox.buttonOkText = "MessageBox.Ok";
            msgBox.callbackOnOk = callbackOnOk;
            msgBox.buttonCancelText = "MessageBox.Cancel";
            msgBox.callbackOnCancel = callbackOnCancel;
            msgBox.open();
            return msgBox;
        } else {
            let msg = {};
            msg["text"] = "Failed to create HulaDialog object";
            msg["statusCode"] = Enums.StatusCode.NotImplemented;
            msg["promptType"] = Enums.PromptType.Error;
            MessageCenter.handleQmlMessage(msg);
            console.log("Failed to create HulaDialog object");
        }
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
        var obj = snackbarComp.createObject(mainForm);
        if (obj) {
            obj.openText(text);
        } else {
            let msg = {};
            msg["text"] = "Failed to create HulaDialog object";
            msg["statusCode"] = Enums.StatusCode.NotImplemented;
            msg["promptType"] = Enums.PromptType.Error;
            MessageCenter.handleQmlMessage(msg);
            console.log("Failed to create HulaSnackbar object");
        }
    }

    Component {
        id: hulaDialogComp
        HulaDialog {}
    }

    Component {
        id: snackbarComp
        HulaSnackbar {}
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

    function strToInt(str) {
        var ret = parseInt(str);
        if (ret.toString() === "NaN")
            ret = 0;
        return ret;
    }

    function isDateString(str) {
        const regex = /^\d{4}-\d{2}-\d{2}$/;
        return regex.test(str);
    }

    PropertyAnimation {
        id: fadeInAni
        target: mainForm
        property: "opacity"
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.InOutQuad
        onFinished: mainForm.showed()
    }
}
