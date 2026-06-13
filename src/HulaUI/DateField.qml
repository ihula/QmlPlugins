import QtQuick
import QtQuick.Controls.Material

ComboBox {
    id: root
    property int popupX: 0
    property int popupY: 0
    property string dateFormat: "yyyy-MM-dd"
    selectTextByMouse: true
    editable: true

    function currDateString(format = "") {
        return cdPick.currDateString(format)
    }

    popup: Popup {
        parent: root.parent
        x: popupX
        y: popupY
        implicitHeight: contentItem.implicitHeight
        padding: 0
        background: Rectangle {
            radius: 4
        }

        contentItem: CalendarPicker {
            id: cdPick
            clip: true
            radius: 4
            property string dateFormat: root.dateFormat
            onClicked: {
                root.editText = selectDate()
                popup.close()
            }
        }
    }
}
