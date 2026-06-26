import QtQuick
import QtQuick.Window
import QtQuick.Controls
import HulaPlugins

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
                    loginLoader.item.show();
                else
                    mainLoader.item.show();
            });

            item.show();
        }
    }

    property Loader loginLoader: Loader {
        asynchronous: useSplash
        source: "./Login.qml"
        active: (!useSplash && useLogin)
        onLoaded: {
            item.showing.connect(function () {
                mainLoader.active = true;
            });

            item.closeing.connect(function () {
                mainLoader.item.show();
            });

            if (mainLoader.status === Loader.Ready)
                loginLoader.item.loadedMainForm();

            if (!useSplash)
                item.show();
        }
    }

    property Loader mainLoader: Loader {
        asynchronous: (useSplash || useLogin)
        source: "./MainForm.qml"
        active: ((!useSplash) && (!useLogin))
        onLoaded: {
            item.showed.connect(function () {
                splashLoader.source = "";
                loginLoader.source = "";
            });

            if (useSplash)
                splashLoader.item.loadedMainForm();

            if (useLogin && (loginLoader.status === Loader.Ready))
                loginLoader.item.loadedMainForm();

            if ((!useSplash) && (!useLogin))
                item.show();
        }
    }
}
