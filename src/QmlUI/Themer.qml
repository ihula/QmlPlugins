pragma Singleton

import QtQuick
import HulaPlugins

QtObject {
    id: themer

    property color theme1Color: "#20B2AA"
    property color theme2Color: "#5d5b67"
    property color theme3Color: "#1296db"
    property color theme4Color: "#2b7adb"
    property color theme5Color: "#3b477f"
    property color themeColor: "#2643d2"
    property color mainColor: "#3b477f"
    property color backColor: "white"
    property color workBackColor: "#F4F4F4"
    property color normalColor: "#3b477f"
    property color hoveredColor: "#5a6bb8"
    property color pressedColor: "#2d3964"
    property color gradientColor1: "#3b477f"
    property color gradientColor2: "#5a6bb8"
    property color titleFontColor: "white"
    property color workFormColor: "#f8f8f8"
    property color iconHoveredColor: "#2b7adb"
    property color editorFontColor: "#535353"
    property color editedFontColor: "#e91e63"
    property color lineColor: "#d8d8d8"
    property color buttonBackground: "white"
    property color buttonCheckedBackground: "#f1f1f1"
    property color buttonTextColor: "white"
    property color buttonColor: "#436fF6"
    property color viewColor: "#ebedf3"
    property color borderColor: "#f1f1f1"
    property color borderGrayColor: "gray"
    property color barColor: "#1296db"
    property color leftTitleColor: "white"
    property color warnColor: "#f67b3e"
    property color loginLeftBackColor: "#1B6CB5"
    property color fontDarkColor: "#212121"
    property color fontLightColor: "#ffffff"

    property int editorFontSize: 18
    property int editorHeight: 42
    property int buttonFontSize: 18
    property int buttonHeight: 48
    property int buttonWidth: 120

    property Gradient buttonGradient: Gradient {
        GradientStop {
            id: gs1
            position: 0.0
            color: gradientColor1
        }
        GradientStop {
            id: gs2
            position: 1.0
            color: gradientColor2
        }
    }

    property Gradient titleBarGradient: Gradient {
        GradientStop {
            position: 0
            color: "white"
        }
        GradientStop {
            position: 0.5
            color: "#f4f4f4"
        }
        GradientStop {
            position: 1.0
            color: "white"
        }
    }

    property Gradient titleGradient: Gradient {
        GradientStop {
            position: 0.0
            color: gradientColor1
        }
        GradientStop {
            position: 1.0
            color: gradientColor2
        }
    }

    property Gradient viewGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            id: gs10
            position: 0
            color: Qt.lighter(gradientColor2, 1.2)
        }
        GradientStop {
            position: 0.5
            color: gradientColor2
        }
        GradientStop {
            position: 0.6
            color: gradientColor2
        }
        GradientStop {
            position: 1.0
            color: Qt.lighter(gradientColor2, 1.2)
        }
    }

    function loadTheme(themeName) {
        var datas = Configer.loadTheme(themeName);
        var keys = Object.keys(datas);

        for (var i = 0; i < keys.length; i++) {
            var fullKey = keys[i];
            var value = datas[fullKey];
            if (value === undefined || value === "")
                continue;

            // 从 "Colors/theme1Color" 格式提取属性名
            var parts = fullKey.split("/");
            var propertyName = parts.length > 1 ? parts[1] : parts[0];
            var group = parts.length > 1 ? parts[0] : "";

            if (group === "String" || group === "") {
                themer[propertyName] = value;
                continue;
            }
            if (group === "Int") {
                themer[propertyName] = parseInt(value);
                continue;
            }
            if (group === "Number") {
                themer[propertyName] = Number(value);
                continue;
            }
            if (group === "Gradient") {
                var str = 'import QtQuick; Gradient {';
                var gradParts = value.split("|");
                if (gradParts.length >= 2) {
                    var orientation = parseInt(gradParts[0]);
                    if (orientation === 0)
                        var orieVal = "Gradient.Horizontal";
                    else
                        orieVal = "Gradient.Vertical";
                    str = str + "orientation:" + orieVal + ";";

                    var stopsStr = gradParts[1];
                    var stopItems = stopsStr.split(";");

                    var stops = [];
                    for (var j = 0; j < stopItems.length; j++) {
                        var stopParts = stopItems[j].split(",");
                        if (stopParts.length === 2) {
                            str += "GradientStop {position:%1; color:\"%2\";}".replace("%1", stopParts[0]).replace("%2", stopParts[1]);
                        }
                    }
                    str = str + "}";
                    // 创建 Gradient 对象
                    var gradient = Qt.createQmlObject(str, themer);
                    themer[propertyName] = gradient;
                }
                continue;
            }
        }
    }

    function checkType(value) {
        var jsType = typeof value;

        // 判断数字 (int / number)
        if (jsType === "number") {
            return Number.isInteger(value) ? "int" : "number";
        }

        // 判断颜色 (color)
        if (jsType === "object" && value !== null) {
            // 判断 Gradient
            var str = String(value);
            if (str.includes("QGradient")) {
                return "gradient";
            }

            var colorObj = Qt.color(value);
            if (colorObj.valid) {
                return "color";
            }
        }

        // 其他类型
        return jsType; // "string", "boolean", "undefined" 等
    }

    function saveTheme(themeName) {
        var theme = BlueTheme;
        var datas = {};
        var keys = Utils.getCustomProps(theme);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            var type = checkType(theme[key]);
            if (type === "color")
                datas[key] = theme[key];
            else if (type === "number")
                datas[key] = theme[key];
            else if (type === "int")
                datas[key] = parseInt(theme[key]);
            else if (type === "gradient") {
                var str = "";
                if (theme[key]["orientation"] === Gradient.Vertical)
                    str = "0|";
                else
                    str = "1|";
                var stops = [];
                for (var k = 0; k < theme[key].stops.length; ++k) {
                    var stop = theme[key].stops[k];
                    stops.push(String(stop.position) + "," + stop.color.toString());
                }
                str += stops.join(";");
                datas[key] = str;
            }
        }

        // 调用新的 C++ 方法保存
        Configer.saveTheme(datas, themeName);
    }

    function gradientToJson() {
        var stopsArray = [];
        // 遍历 Gradient 中的所有 GradientStop
        for (var i = 0; i < viewGradient.stops.length; ++i) {
            var stop = viewGradient.stops[i];
            stopsArray.push({
                position: stop.position,
                // 将颜色转为字符串，如 "#ff0000"
                color: stop.color.toString()
            });
        }

        var gradientData = {
            orientation: viewGradient.orientation,
            stops: stopsArray
        };

        // 序列化为 JSON 字符串并保存
        var jsonString = JSON.stringify(gradientData);
        console.log(jsonString);
    }

    Component.onCompleted: {
        //saveTheme("BlueTheme");
        var themeName = Configer.theme();
        loadTheme(themeName);
    }
}
