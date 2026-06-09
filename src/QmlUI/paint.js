var rect = null
var selectedRect = null
var dragging = false
var offsetX = 0
var offsetY = 0
var canvas = null
var context = null

//传参函数
function setContext(context_, canvasDraw) {
    canvas = canvasDraw
    context = context_
}

//图形的定义，实际应用中想拖动什么图形，这里就可以自己定义
function Rect(x, y, width, height, border, color, fillColor) {
    this.x = parseInt(x)
    this.y = parseInt(y)
    this.width = parseInt(width)
    this.height = parseInt(height)
    this.border = parseInt(border)
    this.color = color
    this.fillColor = fillColor
    this.selected = false
    this.showing = true
}

//添加一些相同的圆
function addRect(x, y, width, height, border, color, fillColor) {
    rect = new Rect(x, y, width, height, border, color, fillColor)
    //重新绘制画布
    drawCanvas()
}

function rectInfo() {
    if (rect === null)
        return

    return {
        "x": rect.x,
        "y": rect.y,
        "width": rect.width,
        "height": rect.height,
        "border": rect.border,
        "color": rect.color
    }
}

function resizeRect(x, y, width, height) {
    if (rect === null)
        return

    rect.x = parseInt(x)
    rect.y = parseInt(y)
    rect.width = parseInt(width)
    rect.height = parseInt(height)
    //重新绘制画布.
    drawCanvas()
}

function clearCanvas() {
    rect = null

    //重新绘制画布.
    if ((context !== null) && (canvas !== null))
        context.clearRect(0, 0, canvas.width, canvas.height)
}

function drawCanvas() {
    if (rect === null)
        return
    if (!rect.showing)
        return
    // 清除画布，准备绘制
    context.clearRect(0, 0, canvas.width, canvas.height)
    context.font = "bold 20px Arial"
    context.fillStyle = rect.fillColor
    context.strokeStyle = rect.color
    if (rect.selected) {
        context.lineWidth = rect.border + 1
    } else {
        context.lineWidth = rect.border
    }

    // 绘制圆圈
    context.beginPath()
    context.fillRect(rect.x, rect.y, rect.width, rect.height)
    context.strokeRect(rect.x, rect.y, rect.width, rect.height)
}

function selectRect(x, y) {
    // 取得画布上被单击的点
    var clickx = x
    var clicky = y
    // 清除之前的选择
    if (selectedRect !== null) {
        selectedRect.selected = false
        selectedRect = null
    }
    if (rect === null)
        return
    if ((x < rect.x) || (x > (rect.x + rect.width)))
        return false
    if ((y < rect.y) || (y > (rect.y + rect.height)))
        return false

    selectedRect = rect

    //选择新圆圈
    rect.selected = true
    offsetX = clickx - rect.x
    offsetY = clicky - rect.y

    // 使圆圈允许拖拽
    dragging = true
    drawCanvas()
    return true
}

function stopDragging() {
    dragging = false
}

//拖动圆
function dragRect(x, y) {
    // 判断圆圈是否开始拖拽
    if (!dragging)
        return
    // 判断拖拽对象是否存在
    if (selectedRect === null)
        return

    // 将圆圈移动到鼠标位置
    selectedRect.x = x - offsetX
    selectedRect.y = y - offsetY
    // 更新画布
    drawCanvas()
}
