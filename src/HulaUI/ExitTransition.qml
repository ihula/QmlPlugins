import QtQuick

Transition {
    id: root
    property string animTypes: ""
    property int duration: 200
    property int easingType: Easing.Bezier
    property QtObject target: null
    property QtObject holder: null

    function getAnimObj(typeName) {
        return root.animTypes.includes(typeName) ? root.target : holder;
    }

    function getTarget(item) {
        if (item === null)
            return 0;
        return (item.parent !== null) ? getTarget(item.parent) : item;
    }

    ParallelAnimation {
        ParallelAnimation {
            PropertyAnimation {
                id: animFadeOut
                target: getAnimObj("fade")
                duration: root.duration
                easing.type: root.easingType
                property: 'opacity'
                from: 1
                to: 0.2
            }

            PropertyAnimation {
                id: animWidthDecrease
                target: getAnimObj("width")
                duration: root.duration
                easing.type: root.easingType
                property: 'width'
                // 省略 from，引擎会自动获取 target 当前的 width 值
                from: target ? target.width : 0
                to: 0
            }

            PropertyAnimation {
                id: animHeightDecrease
                target: getAnimObj("height")
                duration: root.duration
                easing.type: root.easingType
                property: 'height'
                from: target ? target.height : 0
                to: 0
            }

            PropertyAnimation {
                id: animSmall
                target: getAnimObj("scale")
                duration: root.duration
                easing.type: root.easingType
                property: 'scale'
                from: 1
                to: 0.2
            }

            PropertyAnimation {
                id: animOutRight
                target: getAnimObj("flyRight")
                duration: root.duration
                easing.type: root.easingType
                property: 'x'
                from: target ? target.x : 0
                to: getTarget(target).width
            }

            PropertyAnimation {
                id: animOutLeft
                target: getAnimObj("flyLeft")
                duration: root.duration
                easing.type: root.easingType
                property: 'x'
                from: target ? target.x : 0
                to: target ? -target.width : 0
            }

            PropertyAnimation {
                id: animOutUp
                target: getAnimObj("flyUp")
                duration: root.duration
                easing.type: root.easingType
                property: 'y'
                from: target ? target.y : 0
                to: target ? -target.height : 0
            }

            PropertyAnimation {
                id: animOutDown
                target: getAnimObj("flyDown")
                duration: root.duration
                easing.type: root.easingType
                property: 'y'
                from: target ? target.y : 0
                to: getTarget(target).height
            }
        }
    }
}
