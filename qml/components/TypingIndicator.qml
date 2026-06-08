// TypingIndicator.qml
// The little "···" that pulses while we're waiting for the AI's first words.
// As soon as the first chunk of the reply arrives, the chat hides this and
// shows the real bubble instead.

import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: indicator
    spacing: Theme.paddingSmall
    height: Theme.itemSizeExtraSmall

    Repeater {
        model: 3
        Rectangle {
            width: Theme.paddingSmall
            height: width
            radius: width / 2
            color: Theme.secondaryHighlightColor
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation on opacity {
                running: indicator.visible
                loops: Animation.Infinite
                // Stagger each dot so they ripple.
                PauseAnimation { duration: index * 180 }
                NumberAnimation { to: 1.0; duration: 300 }
                NumberAnimation { to: 0.2; duration: 300 }
                PauseAnimation { duration: (2 - index) * 180 }
            }
        }
    }
}
