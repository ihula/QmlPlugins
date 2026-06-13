import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.Basic as Basic
import QtMultimedia
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../HulaUI"

HulaDialog {
    id: root
    width: mainForm.width - 16
    height: mainForm.height - 16
    x: 8
    y: 8
    formTitle: qsTr("Capture.Title") + translater.change
    backColor: "#F8F8F8"
    property bool homeJumped: false
    property var patientData: ({})
    property int btnWidth: 98
    property int btnHeight: 38
    property int lblHeight: 18
    property int lblPixelSize: 14
    property string reportNo: ""
    property string testId: ""
    property string name: ""
    property var roi: []
    signal formClosed(string testId)

    Connections {
        target: camera
        function onImageSizeChanged(w, h) {
            var wRate = leftBar.width / w
            var hRate = leftBar.height / h

            if (wRate <= hRate) {
                itemPreview.width = leftBar.width
                itemPreview.height = leftBar.width * h / w
            } else {
                itemPreview.height = leftBar.height
                itemPreview.width = leftBar.height * w / h
            }
            camera.setImageRoiRatio(root.roi[0] / itemPreview.width,
                                    root.roi[1] / itemPreview.height,
                                    root.roi[2] / itemPreview.width,
                                    root.roi[3] / itemPreview.height)
        }

        function onImageUpdated() {
            imgPreview.source = "image://imageProvider?" + Math.random()
        }

        function onImageCaptured(id) {
            var path = "image://imageProvider?" + id
            imagePaths.append({
                                  "type": 1,
                                  "id": id,
                                  "path": path
                              })
        }
    }

    onShowForm: {
        var size = configer.cameraSize()
        if (size === "")
            size = "640x480"
        var list = size.split("x")
        var w = strToInt(list[0])
        var h = strToInt(list[1])
        var wRate = leftBar.width / w
        var hRate = leftBar.height / h

        if (wRate <= hRate) {
            itemPreview.width = leftBar.width
            itemPreview.height = leftBar.width * h / w
        } else {
            itemPreview.height = leftBar.height
            itemPreview.width = leftBar.height * w / h
        }

        var hues = configer.cameraHues()
        if (hues.length !== 4) {
            hues[0] = 0
            hues[1] = 0
            hues[2] = 0
            hues[3] = 0
        }
        sldHue.value = hues[0]
        sldSaturation.value = hues[1]
        sldBrightness.value = hues[2]
        sldContrast.value = hues[3]

        root.roi = configer.cameraRoi()
        if (root.roi.length !== 4) {
            root.roi[0] = 0
            root.roi[1] = 0
            root.roi[2] = w
            root.roi[3] = h
        }
        camera.setImageRoiRatio(root.roi[0] / itemPreview.width,
                                root.roi[1] / itemPreview.height,
                                root.roi[2] / itemPreview.width,
                                root.roi[3] / itemPreview.height)

        lblTestId.text = root.patientData["TestId"]
        lblName.text = root.patientData["Name"]
        if (lblTestId.text !== "") {
            loadExistImages()
        }
        var cameraName = configer.cameraName()
        camera.openCamera(cameraName, w, h)
    }

    onHideForm: {
        //camera.closeCamera()
        formClosed(lblTestId.text)
    }

    Rectangle {
        id: leftBar
        color: "black"
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: righttBar.left
        anchors.bottom: parent.bottom
        anchors.margins: 20
        width: 800
        radius: 8
        border.width: 1
        border.color: HulaTheme.lineColor

        Item {
            id: itemPreview
            anchors.centerIn: parent
            clip: true
            smooth: true

            Image {
                id: imgPreview
                property int lastId: 0
                anchors.fill: parent
                clip: true
                visible: true
                fillMode: Image.PreserveAspectFit
                cache: false
                smooth: true
            }

            BrightnessContrast {
                id: contr
                anchors.fill: imgPreview
                source: imgPreview
                brightness: 0.0
                contrast: 0
            }

            HueSaturation {
                id: light
                anchors.fill: imgPreview
                source: contr
                lightness: 0
                hue: 0
                saturation: 0
            }
            CanvasDraw {
                id: canvasDraw
                parent: imgPreview
            }
        }
    }

    Rectangle {
        height: 90
        anchors.left: leftBar.left
        anchors.bottom: leftBar.bottom
        anchors.right: leftBar.right
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        radius: 8
        color: "#30000000"

        Label {
            id: lblTestId
            height: lblHeight
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: 12
            Material.foreground: "white"
            font.pixelSize: lblPixelSize
            text: ""
            width: 80
        }
        Label {
            height: lblHeight
            anchors.top: lblTestId.top
            anchors.right: lblTestId.left
            anchors.rightMargin: 6
            Material.foreground: "white"
            font.pixelSize: lblPixelSize
            text: qsTr("Capture.TestId") + translater.change
        }
        Label {
            id: lblName
            height: lblHeight
            anchors.top: lblTestId.bottom
            anchors.topMargin: 6
            anchors.right: lblTestId.right
            Material.foreground: "white"
            font.pixelSize: lblPixelSize
            text: ""
            width: 80
        }
        Label {
            height: lblHeight
            anchors.top: lblName.top
            anchors.right: lblName.left
            anchors.rightMargin: 12
            Material.foreground: "white"
            font.pixelSize: lblPixelSize
            text: qsTr("Capture.Name") + translater.change
        }
        RowLayout {
            anchors.top: lblName.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.right: lblName.right

            RoundButton {
                id: btnCaptureImage
                radius: 4
                implicitHeight: btnHeight
                implicitWidth: btnWidth
                Material.foreground: "white"
                Material.background: "#2f2f2f"
                text: qsTr("Capture.CaptureImage") + translater.change
                enabled: !canvasDraw.drawing
                onClicked: {
                    itemPreview.grabToImage(function (result) {
                        camera.captureVariantImage(result.image)
                    })
                }
            }
            RoundButton {
                id: btnCaptureRoiImage
                radius: 4
                implicitHeight: btnHeight
                implicitWidth: btnWidth
                Material.foreground: "white"
                Material.background: "#2f2f2f"
                text: qsTr("Capture.CaptureRoiImage") + translater.change
                enabled: !canvasDraw.drawing
                onClicked: {
                    itemPreview.grabToImage(function (result) {
                        // result.saveToFile("1.jpg")
                        camera.captureVariantImage(result.image, true)
                    })
                }
            }
            RoundButton {
                radius: 4
                implicitHeight: btnHeight
                implicitWidth: btnWidth
                Material.foreground: "white"
                Material.background: canvasDraw.drawing ? "#707070" : "#2f2f2f"
                property string title: canvasDraw.drawing ? "Capture.SaveImageRoi" : "Capture.ImageRoi"
                text: qsTr(title) + translater.change
                onClicked: {
                    canvasDraw.drawing = !canvasDraw.drawing
                    if (!canvasDraw.drawing) {
                        var rect = canvasDraw.rectInfo()
                        if (rect.hasOwnProperty("x")) {
                            root.roi[0] = rect.x
                            root.roi[1] = rect.y
                            root.roi[2] = rect.width
                            root.roi[3] = rect.height
                            configer.setCameraRoi(rect.x, rect.y, rect.width,
                                                  rect.height)
                            camera.setImageRoiRatio(
                                        root.roi[0] / itemPreview.width,
                                        root.roi[1] / itemPreview.height,
                                        root.roi[2] / itemPreview.width,
                                        root.roi[3] / itemPreview.height)
                        }
                        canvasDraw.clearCanvas()
                    } else {
                        if (root.roi.length >= 4) {
                            canvasDraw.addRect(roi[0], roi[1], roi[2], roi[3],
                                               1, "blue", "#30ffffff")
                        }
                    }
                }
            }
            RoundButton {
                id: btnProperty
                radius: 4
                implicitHeight: btnHeight
                implicitWidth: btnWidth
                Material.foreground: "white"
                Material.background: "#2f2f2f"
                text: qsTr("Capture.VideoProperty") + translater.change
                enabled: !canvasDraw.drawing
                onClicked: {
                    camera.openDialog(0)
                }
            }
            RoundButton {
                id: btnReport
                radius: 4
                implicitHeight: btnHeight
                implicitWidth: btnWidth
                Material.foreground: "white"
                Material.background: "#2f2f2f"
                text: qsTr("Capture.MakeReport") + translater.change
                enabled: !canvasDraw.drawing
                onClicked: {
                    if (!root.homeJumped) {
                        close()
                        return
                    }
                    var funcOpenReport = function () {
                        openReport(reportSelect.reportNo, root.patientData)
                        close()
                    }
                    reportSelect.callbackOk = funcOpenReport
                    reportSelect.open()
                }
            }
            RoundButton {
                id: btnSaveImage
                radius: 4
                implicitHeight: btnHeight
                implicitWidth: btnWidth
                Material.foreground: "white"
                Material.background: "#0888FF"
                text: qsTr("Capture.SaveImage") + translater.change
                enabled: !canvasDraw.drawing
                onClicked: {
                    camera.savePreviewImage(lblTestId.text)
                    snackMessage("Capture.SaveImageValid")
                }
            }
        }

        Slider {
            id: sldContrast // 对比度
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 12
            height: btnHeight
            from: -100
            to: 100
            value: 0
            onValueChanged: {
                contr.brightness = value / 100
                contr.contrast = value / 100
            }
        }
        Label {
            id: lblContrasTxt
            x: sldContrast.x + 6
            y: sldContrast.y - height + 10
            color: "white"
            text: qsTr("Capture.Contras") + translater.change
        }
        Label {
            id: lblContrasVal
            x: sldContrast.x + sldContrast.width - width - 12
            y: lblContrasTxt.y
            color: "white"
            text: String(sldContrast.value.toFixed(0)) + "%"
        }

        Slider {
            id: sldSaturation // 饱和度
            anchors.bottom: sldContrast.bottom
            anchors.left: sldContrast.right
            height: btnHeight
            from: -100
            to: 100
            value: 0
            onValueChanged: {
                light.saturation = value / 100
                configer.setCameraHues(sldHue.value, sldSaturation.value,
                                       sldBrightness.value, sldContrast.value)
            }
        }
        Label {
            id: lblSaturationTxt
            x: sldSaturation.x + 6
            y: sldSaturation.y - height + 10
            color: "white"
            text: qsTr("Capture.Saturation") + translater.change
        }
        Label {
            id: lblSaturationVal
            x: sldSaturation.x + sldSaturation.width - width - 12
            y: lblSaturationTxt.y
            color: "white"
            text: String(sldSaturation.value.toFixed(0)) + "%"
        }

        Slider {
            id: sldBrightness
            anchors.bottom: sldContrast.top
            anchors.left: sldContrast.left
            height: btnHeight
            from: -100
            to: 100
            value: 0
            onValueChanged: {
                light.lightness = value / 100
                configer.setCameraHues(sldHue.value, sldSaturation.value,
                                       sldBrightness.value, sldContrast.value)
            }
        }
        Label {
            id: lblBrightnessTxt
            x: sldBrightness.x + 6
            y: sldBrightness.y - height + 10
            color: "white"
            text: qsTr("Capture.Brightness") + translater.change
        }
        Label {
            id: lblBrightnessVal
            x: sldBrightness.x + sldBrightness.width - width - 12
            y: lblBrightnessTxt.y
            color: "white"
            text: String(sldBrightness.value.toFixed(0)) + "%"
        }

        Slider {
            id: sldHue // 色相
            anchors.bottom: sldBrightness.bottom
            anchors.left: sldBrightness.right
            height: btnHeight
            from: 0
            to: 100
            value: 0
            onValueChanged: {
                light.hue = value / 100
                configer.setCameraHues(sldHue.value, sldSaturation.value,
                                       sldBrightness.value, sldContrast.value)
            }
        }
        Label {
            id: lblHueTxt
            x: lblSaturationTxt.x
            y: sldBrightness.y - height + 10
            color: "white"
            text: qsTr("Capture.Hue") + translater.change
        }
        Label {
            id: lblHueVal
            x: lblSaturationVal.x
            y: lblBrightnessTxt.y
            color: "white"
            text: String(sldHue.value.toFixed(0)) + "%"
        }
    }

    ListModel {
        id: imagePaths
        onCountChanged: {
            if (count === 1) {
                imgSize.source = get(0).path
                gridView.cellHeight = imgSize.paintedHeight
                        / imgSize.paintedWidth * gridView.cellWidth
                imgSize.source = ""
            }
        }
    }

    Item {
        id: righttBar
        anchors.top: titleBar.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        width: 530
        Rectangle {
            color: "white"
            anchors.fill: parent
            anchors.margins: 1
            anchors.bottomMargin: 12
            radius: 8
            border.width: 1
            border.color: HulaTheme.lineColor

            Label {
                id: rightTitle
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.right: parent.right
                height: 40
                font.pixelSize: 16
                color: "#555555"
                text: qsTr("Report.Images") + translater.change
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                background: Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 8
                    color: "#eaeaea"

                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: parent.radius
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        color: "#eaeaea"
                    }
                }
            }

            GridView {
                id: gridView
                anchors.fill: parent
                anchors.margins: 1
                anchors.topMargin: rightTitle.height
                cellWidth: width / 2
                clip: true
                ScrollBar.vertical: Basic.ScrollBar {}
                model: imagePaths

                delegate: Rectangle {
                    property alias image: img
                    width: GridView.view.cellWidth
                    height: GridView.view.cellHeight
                    color: "transparent"
                    Image {
                        id: img
                        anchors.fill: parent
                        anchors.margins: 6
                        source: model.path
                        clip: true
                        fillMode: Image.PreserveAspectFit
                    }
                    RoundButton {
                        x: (img.width - img.paintedWidth) / 2 + 8
                        y: (img.height - img.paintedHeight) / 2 + 8
                        radius: 4
                        padding: 0
                        leftInset: 0
                        topInset: 0
                        rightInset: 0
                        bottomInset: 0
                        implicitHeight: 24
                        implicitWidth: 24
                        display: AbstractButton.IconOnly
                        icon.source: "file:" + "Images/delete.svg"
                        icon.height: 24
                        icon.width: 24
                        onClicked: {
                            if (model.type === 1) {
                                camera.removePreviewImage(model.id)
                            } else {
                                var filePath = img.source.toString().replace(
                                            "file:///", "")
                                filePath = filePath.replace("file:", "")
                                camera.deleteFile(filePath)
                            }
                            imagePaths.remove(index)
                        }
                    }
                }
            }
        }
    }

    ReportSelect {
        id: reportSelect
        autoDestroy: false
    }

    Image {
        id: imgSize
        visible: false
        fillMode: Image.PreserveAspectFit
    }

    function loadExistImages() {
        var path = lblTestId.text
        var nameList = camera.getDirImageNames(path)
        if (nameList.length === 0)
            return

        for (var i = 0; i < nameList.length; i++) {
            imagePaths.append({
                                  "type": 2,
                                  "path": "file:" + nameList[i]
                              })
        }
    }
}
