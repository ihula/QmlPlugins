import QtQuick 2.9
import QtQuick.Controls 2.5
import "paint.js" as Painter

//将一些功能封装进js里面，稍后展示代码
Canvas {
    id: canvasDraw
    anchors.fill: parent
    property bool roiRecting: false
    property bool drawing: false
    signal disableMoveParent
    signal enableMoveParent
    signal rectSelected(var circle)
    signal rectMoved(int x, int y)
    signal mousePress(int x, int y)

    function drawCanvas() {
        canvasDraw.requestPaint()
        Painter.drawCanvas()
    }

    // 添加
    function addRect(x, y, width, height, border, color, fillColor) {
        canvasDraw.requestPaint()
        Painter.clearCanvas()
        Painter.addRect(x, y, width, height, border, color, fillColor)
    }

    function hideRect() {
        canvasDraw.requestPaint()
        Painter.rect.showing = false
    }

    function clearCanvas() {
        canvasDraw.requestPaint()
        Painter.clearCanvas()
    }

    function rectInfo() {
        return Painter.rectInfo()
    }

    function resizeRect(x, y, width, height) {
        canvasDraw.requestPaint()
        Painter.resizeRect(x, y, width, height)
    }

    //重绘事件发生时会调用onPaint()，这里是用于不使图形变形
    onPaint: Painter.drawCanvas()

    onAvailableChanged: Painter.setContext(canvasDraw.getContext("2d"),
                                           canvasDraw)

    //放一个鼠标区域，相应鼠标事件
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        property point clickPoint: "0, 0"
        onPressed: {
            //每次使用外部函数进行绘制前不要忘了这一句
            canvasDraw.requestPaint()
            //这里是为了实现选取一个圆，鼠标坐标是为了计算鼠标是否在圆内
            var ret = Painter.selectRect(mouseX, mouseY)
            if (ret)
                disableMoveParent()

            if (Painter.selectedRect !== null)
                rectSelected(Painter.selectedRect)

            clickPoint = Qt.point(mouseX, mouseY)
            mousePress(mouseX, mouseY)
        }
        //鼠标释放
        onReleased: {
            enableMoveParent()
            canvasDraw.requestPaint()
            //停止拖动
            Painter.stopDragging()
            if (Painter.selectedRect !== null) {
                rectMoved(Painter.selectedRect.x, Painter.selectedRect.y)
            }
        }
        //这个槽默认状态下意思是鼠标既按下又拖动，可以设置为不按下就拖动
        onPositionChanged: {
            canvasDraw.requestPaint()
            if (!drawing)
                return
            if (Painter.selectedRect !== null) {
                Painter.dragRect(mouseX, mouseY)
                return
            }
            if (Painter.rect === null) {
                Painter.addRect(clickPoint.x, clickPoint.y,
                                mouseX - clickPoint.x, mouseY - clickPoint.y,
                                1, "blue", "#30ffffff")
            } else {
                Painter.resizeRect(clickPoint.x, clickPoint.y,
                                   mouseX - clickPoint.x, mouseY - clickPoint.y)
            }
        }
    }
}
