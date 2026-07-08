import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ComboBox {
    id: root

    // 自定义下拉列表 delegate，使用 ComboBox 自身的字体大小
    delegate: ItemDelegate {
        width: root.popup.width
        contentItem: Text {
            text: {
                if (root.textRole && model && model[root.textRole] !== undefined)
                    return model[root.textRole]
                if (root.textRole && root.model && root.model[index] && root.model[index][root.textRole] !== undefined)
                    return root.model[index][root.textRole]
                return modelData !== undefined ? modelData : ""
            }
            font: root.font
            color: Material.foreground
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }
        highlighted: root.highlightedIndex === index
    }
}
