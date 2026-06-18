import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QmlPlugins

QtObject {
    id: main
    property bool useSplash: Configer.enableSplash()
    property bool useLogin: Configer.enableLogin()

    // 加载界面文件
    property Loader splashLoader: Loader {
        active: useSplash
        source: "./Splash.qml"
        onLoaded: {
            item.showing.connect(function () {
                if (useLogin)
                    loginLoader.active = true;
                mainLoader.active = true;
            });

            item.closeing.connect(function () {
                if (useLogin)
                    loginLoader.item.showForm();
                else
                    mainLoader.item.showForm();

                item.closeWithAnimation();
            });

            item.showForm();
        }
    }

    property Loader loginLoader: Loader {
        source: "./Login.qml"
        active: useLogin
        visible: false
        onLoaded: {
            item.showing.connect(function () {
                mainLoader.active = true;
            });

            item.closeing.connect(function () {
                mainLoader.item.showForm();
                item.closeWithAnimation();
            });
        }
    }

    property Loader mainLoader: Loader {
        asynchronous: (useSplash || useLogin)
        source: "./MainForm.qml"
        active: ((!useSplash) && (!useLogin))
        onLoaded: {
            if (useSplash)
                splashLoader.item.loadedMainForm();

            if (useLogin)
                loginLoader.item.loadedMainForm();

            if ((!useSplash) && (!useLogin))
                item.showForm();
        }
    }
}
