pragma Singleton

import QtQuick
import QmlPlugins

QtObject {
    id: themer
    objectName: "themer"

    /**
     * @brief 当前主题对象
     * @type {HulaTheme}
     */
    property var theme: HulaTheme

    Component.onCompleted: {
        var themeConfig = Configer.theme();
        if (themeConfig === "HulaTheme")
            theme = HulaTheme;
        else if (themeConfig === "BlueTheme")
            theme = BlueTheme;
        else
            theme = DarkBlueTheme;
    }
}
