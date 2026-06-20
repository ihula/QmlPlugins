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
                id: animFadeIn
                target: getAnimObj("fade")
                duration: root.duration
                easing.type: root.easingType
                property: 'opacity'
                from: 0
                to: 1
            }

            PropertyAnimation {
                id: animWidthIncrease
                target: getAnimObj("width")
                duration: root.duration
                easing.type: root.easingType
                property: 'width'
                from: 0
                to: target ? target.width : 0
            }

            PropertyAnimation {
                id: animHeightIncrease
                target: getAnimObj("height")
                duration: root.duration
                easing.type: root.easingType
                property: 'height'
                from: 0
                to: target ? target.height : 0
            }

            PropertyAnimation {
                id: animBig
                target: getAnimObj("scale")
                duration: root.duration
                easing.type: root.easingType
                property: 'scale'
                from: 0.2
                to: 1
            }

            PropertyAnimation {
                id: animInRight
                target: getAnimObj("flyRight")
                duration: root.duration
                easing.type: root.easingType
                property: 'x'
                from: target ? -target.width : 0
                to: target ? target.x : 0
            }

            PropertyAnimation {
                id: animInLeft
                target: getAnimObj("flyLeft")
                duration: root.duration
                easing.type: root.easingType
                property: 'x'
                from: getTarget(target).width
                to: target ? target.x : 0
            }

            PropertyAnimation {
                id: animInUp
                target: getAnimObj("flyUp")
                duration: root.duration
                easing.type: root.easingType
                property: 'y'
                from: getTarget(target).height
                to: target ? target.y : 0
            }

            PropertyAnimation {
                id: animInDown
                target: getAnimObj("flyDown")
                duration: root.duration
                easing.type: root.easingType
                property: 'y'
                from: target ? -target.height : 0
                to: target ? target.y : 0
            }
        }
    }
}
