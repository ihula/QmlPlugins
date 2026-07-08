import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "../Components"
import HulaPlugins

Item {
    id: root
    anchors.fill: parent
    property bool autoDestroy: false
    property int userAge: 0
    property bool isVisible: visible

    onIsVisibleChanged: {
        if (visible) {} else {}
    }

    Component.onCompleted: {
        //loader1.active = true;
        //loader1.anchors.fill = parent;
        tabBar.itemAt(0).clicked();
    }

    TabBar {
        id: tabBar
        width: parent.width
        background: Item {
            anchors.fill: parent
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                border.color: "#d5d6d8"
                color: "transparent"
            }
        }

        Repeater {
            id: rptButton
            property int currentIndex: -1
            property var pages: [loaderDataDict, loaderRoleManager, loaderUserManager, loaderPreferences, loaderMachine, loaderTheme]
            model: ["Setting.DataDict", "Setting.RoleManager", "Setting.UserManager", "Setting.SystemSetting", "Setting.MachineSetting", "Setting.ThemeSetting"]
            TabButton {
                font.pixelSize: 18
                text: qsTr(modelData)
                width: implicitWidth + 40
                Material.foreground: hovered ? Themer.buttonColor : "black"
                background: Rectangle {
                    anchors.fill: parent
                    color: hovered ? "#10000000" : "transparent"
                    radius: 4
                }

                // 选中时的下划线颜色
                indicator: Rectangle {
                    height: 2
                    anchors.bottom: parent.bottom
                    visible: parent.checked
                }
                onClicked: {
                    if (rptButton.currentIndex === index)
                        return;

                    rptButton.currentIndex = index;
                    rptButton.pages[index].active = true;
                    contentStack.replace(rptButton.pages[index], StackView.PopTransition);
                }
            }
        }
    }

    StackView {
        id: contentStack
        anchors.top: tabBar.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Loader {
            id: loaderDataDict
            active: false
            source: "Page5.qml"
        }

        Loader {
            id: loaderRoleManager
            active: false
            source: "RoleManagerForm.qml"
        }

        Loader {
            id: loaderUserManager
            active: false
            source: "UserManagerForm.qml"
        }

        Loader {
            id: loaderPreferences
            active: false
            source: "Preferences.qml"
        }

        Loader {
            id: loaderMachine
            active: false
            //source: "UserManagerForm.qml"
        }

        Loader {
            id: loaderTheme
            active: false
            //source: "UserManagerForm.qml"
        }
    }
}
