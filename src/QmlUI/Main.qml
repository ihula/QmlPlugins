import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QmlPlugins 1.0

QtObject {
    id: main
    property bool useSplash: Configer.enableSplash()
    property bool useLogin: Configer.enableLogin()
    property bool mainFormLoaded: false
    property bool waitMainFormShow: false

    Component.onCompleted: {
        console.log(1, useSplash);
        console.log(2, useLogin);
    }

    // 加载界面文件
    property Loader loaderSplash: Loader {
        active: useSplash
        source: "./Splash.qml"
        onLoaded: {
            item.showForm();
        }
    }

    property Loader loaderLogin: Loader {
        source: "./Login.qml"
        active: ((!useSplash) && useLogin)
        onLoaded: {
            if (!useSplash)
                item.showForm();
        }
    }

    property Loader loaderMain: Loader {
        asynchronous: (useSplash || useLogin)
        source: "./MainForm.qml"
        active: ((!useSplash) && (!useLogin))
        onLoaded: {
            if ((!useSplash) && (!useLogin))
                item.showForm();
        }
    }
}
