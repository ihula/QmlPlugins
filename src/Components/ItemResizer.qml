import QtQuick
import QtQuick.Controls

Item {
    id: root
    property QtObject control: parent
    // 定义边缘热区的厚度
    property int edgeSize: 8
    // 标题栏
    property QtObject titlebar: null
    // 窗体是否为全屏模式
    property bool isFullscreen: false

    // 标题栏拖动区域
    Item {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.titlebar?.height || 0

        // 系统级拖拽移动（Aero Snap 的核心）
        DragHandler {
            target: null // 不移动内部元素
            grabPermissions: TapHandler.CanTakeOverFromAnything // 允许在按钮上拖动
            onActiveChanged: {
                if (active) {
                    root.control.startSystemMove();
                }
            }
        }

        // 2. 双击标题栏最大化/还原（Aero 体验的补充）
        TapHandler {
            onPressedChanged: {
                if (pressed)
                    titleBar.state = "Pressed";
                else
                    titleBar.state = "Released";
            }

            onDoubleTapped: {
                if ((root.control.visibility === Window.FullScreen) || (root.control.visibility === Window.Maximized)) {
                    root.control.showNormal();
                } else {
                    if (root.isFullscreen)
                        root.control.showFullScreen();
                    else
                        root.control.showMaximized();
                }
            }
            gesturePolicy: TapHandler.DragThreshold // 防止与拖动冲突
        }
    }

    // 顶部边缘
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.edgeSize
        anchors.leftMargin: root.edgeSize
        anchors.rightMargin: root.edgeSize

        //处理悬停和鼠标样式（替代 MouseArea 的 hoverEnabled 和 cursorShape）
        HoverHandler {
            cursorShape: Qt.SizeVerCursor
        }

        // 处理点击事件（替代 MouseArea 的 acceptedButtons: Qt.NoButton 的意图）
        TapHandler {
            acceptedButtons: Qt.NoButton  // 保持与原来一致：不拦截任何鼠标按键
            // 如果你需要处理点击，可以改为 Qt.LeftButton 并添加 onTapped 信号
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeVerCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.TopEdge);
            }
        }
    }

    // 底部边缘
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.edgeSize
        anchors.leftMargin: root.edgeSize
        anchors.rightMargin: root.edgeSize

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeVerCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeVerCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.BottomEdge);
            }
        }
    }

    // 左侧边缘
    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.edgeSize
        anchors.topMargin: root.edgeSize
        anchors.bottomMargin: root.edgeSize

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeHorCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeHorCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.LeftEdge);
            }
        }
    }

    // 右侧边缘
    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.edgeSize
        anchors.topMargin: root.edgeSize
        anchors.bottomMargin: root.edgeSize

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeHorCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeHorCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.RightEdge);
            }
        }
    }

    // --- 以下是四个角落的热区，必须放在最后以保证最高 Z 轴优先级 ---

    // 左上角
    Item {
        width: root.edgeSize
        height: root.edgeSize
        anchors.top: parent.top
        anchors.left: parent.left

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeFDiagCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeFDiagCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.LeftEdge | Qt.TopEdge);
            }
        }
    }

    // 右上角
    Item {
        width: root.edgeSize
        height: root.edgeSize
        anchors.top: parent.top
        anchors.right: parent.right

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeBDiagCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeBDiagCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.RightEdge | Qt.TopEdge);
            }
        }
    }

    // 左下角
    Item {
        width: root.edgeSize
        height: root.edgeSize
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeBDiagCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeBDiagCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.LeftEdge | Qt.BottomEdge);
            }
        }
    }

    // 右下角
    Item {
        width: root.edgeSize
        height: root.edgeSize
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeFDiagCursor
        }

        DragHandler {
            target: null
            margin: root.edgeSize
            cursorShape: Qt.SizeFDiagCursor
            onActiveChanged: {
                if (active)
                    control.startSystemResize(Qt.RightEdge | Qt.BottomEdge);
            }
        }
    }
}
