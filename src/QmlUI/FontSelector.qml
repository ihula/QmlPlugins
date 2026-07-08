import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Fusion as Fusion
import QtQuick.Layouts
import HulaPlugins

// 自定义字体选择弹窗
HulaDialog {
    id: fontDialogPopup
    anchors.centerIn: parent
    width: 520
    height: 430
    title: qsTr("MessageCenter.Title")
    leftPadding: 12
    rightPadding: 12
    topPadding: 12
    bottomPadding: 12
    property font selectedFont: null
    signal selected(font font)

    function currentSafeFont() {
        if (listView.currentItem)
            return listView.currentText;
        else
            return "Microsoft YaHei";
    }

    contentItem: ColumnLayout {
        spacing: 10

        // 字体列表 + 预览
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 字体列表
            Rectangle {
                color: Themer.workFormColor
                width: 200
                Layout.fillHeight: true
                radius: 8
                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 8
                    property string currentText: ""
                    property color itemColor: Qt.alpha(Themer.workFormColor, mainForm.alpha)
                    property color highColor: Qt.alpha(Themer.hoveredColor, mainForm.alpha)
                    model: Qt.fontFamilies().filter(f => {
                        // 拉黑所有会报 DirectWrite 错误的古董系统字体
                        const badFonts = ["System", "Small Fonts", "Terminal", "Fixedsys", "OEM", "Roman", "Script", "Modern", "MS Sans Serif", "MS Serif", "MS Gothic", "MS PGothic", "Symbol", "Marlett", "Webdings", "Wingdings"];
                        return !badFonts.includes(f);
                    })
                    clip: true
                    currentIndex: 0
                    ScrollBar.vertical: Fusion.ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    highlight: Item {
                        width: 200
                        height: 36
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: listView.highColor
                            radius: 6
                        }
                    }
                    delegate: ItemDelegate {
                        width: 200
                        height: 36
                        //property string text: itemText.text
                        anchors.margins: 2
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                listView.currentIndex = index;
                                listView.currentText = itemText.text;
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: listView.itemColor
                        }
                        Text {
                            id: itemText
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Themer.editorFontSize
                            text: modelData
                            font.family: modelData
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                        }
                    }
                }
            }

            // 右侧设置区
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        font.pixelSize: Themer.editorFontSize
                        text: "字号："
                    }
                    SpinBox {
                        id: sizeSpin
                        font.pixelSize: Themer.editorFontSize
                        implicitHeight: 36
                        from: 8
                        to: 72
                        value: 12
                    }
                }

                // 样式复选
                RowLayout {
                    Layout.fillWidth: true
                    CheckBox {
                        id: checkBold
                        font.pixelSize: Themer.editorFontSize
                        text: "粗体"
                    }
                    CheckBox {
                        id: checkItalic
                        font.pixelSize: Themer.editorFontSize
                        text: "斜体"
                    }
                    CheckBox {
                        id: checkUnderline
                        font.pixelSize: Themer.editorFontSize
                        text: "下划线"
                    }
                }

                // 预览区域
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: "#ccc"
                    Text {
                        anchors.centerIn: parent
                        text: "Aa 字体预览 123"
                        font.family: currentSafeFont()
                        font.pixelSize: sizeSpin.value
                        font.bold: checkBold.checked
                        font.italic: checkItalic.checked
                        font.underline: checkUnderline.checked
                    }
                }
            }
        }

        // 确定取消按钮
        RowLayout {
            //Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            implicitHeight: 32
            spacing: 10
            RoundButton {
                id: btnOk
                radius: 4
                Material.background: "white"
                Material.foreground: "#535353"
                implicitWidth: 84
                font.pixelSize: Themer.buttonFontSize
                text: qsTr("Preferences.Ok")
                onClicked: {
                    // 把选中的字体参数抛出去给外部使用
                    selectedFont.family = currentSafeFont();
                    selectedFont.pixelSize = sizeSpin.value;
                    selectedFont.bold = checkBold.checked;
                    selectedFont.italic = checkItalic.checked;
                    selectedFont.underline = checkUnderline.checked;
                    selected(selectedFont);
                    fontDialogPopup.close();
                }
            }

            RoundButton {
                id: btnBack
                radius: 4
                Material.background: "white"
                Material.foreground: "#535353"
                implicitWidth: 84
                font.pixelSize: Themer.buttonFontSize
                text: qsTr("Preferences.Cancel")
                onClicked: {
                    fontDialogPopup.hide();
                }
            }
        }
    }
} // 存储选中结果// property var fontSelectResult: ({//     family: "Microsoft YaHei",
//     size: 12,
//     bold: false,
//     italic: false,
//     underline: false
// })

// // 监听字体变化示例
// Connections {
//     target: root
//     onFontSelectResultChanged: {
//         console.log("选中字体：", fontSelectResult.family,
//                     "字号：", fontSelectResult.size,
//                     "粗体：", fontSelectResult.bold)
//     }
// }

