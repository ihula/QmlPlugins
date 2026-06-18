import QtQuick
import QtQuick.Controls.Material

ComboBox {
    id: root
    property int popupX: 0
    property int popupY: 0
    property alias dayNames: cdPick.dayNames
    property alias calendarBorder: cdPick.border
    property alias hoverBorderColor: cdPick.hoverBorderColor
    property alias textColor: cdPick.textColor
    property alias selectedTextColor: cdPick.selectedTextColor
    property alias selectedBackColor: cdPick.selectedBackColor
    property alias calendarFont: cdPick.font
    property alias dateFormat: cdPick.dateFormat
    selectTextByMouse: true
    editable: true

    function dateString(format = "") {
        return cdPick.dateString(format);
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
            locale: root.locale
            dateFormat: root.dateFormat
            onClicked: {
                root.editText = date();
                popup.close();
            }
        }
    }
}
