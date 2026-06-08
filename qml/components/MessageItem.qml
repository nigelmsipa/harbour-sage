// MessageItem.qml
// One chat bubble. The chat list reuses this for every message.
// Your messages sit on the right in the highlight color; the AI's replies
// sit on the left in plain text — the familiar two-sided chat look, done the
// Sailfish way with Theme colors and spacing.

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: bubble

    // These are filled in by the list for each row.
    property string role: "assistant"
    property string content: ""

    readonly property bool isUser: role === "user"

    width: ListView.view ? ListView.view.width : parent.width
    // The bubble is as tall as its text plus some breathing room.
    height: bg.height + Theme.paddingMedium

    Rectangle {
        id: bg
        // User bubbles hug the right edge, AI bubbles hug the left — but always
        // kept off the screen edge by the standard Sailfish page margin.
        anchors {
            right: isUser ? parent.right : undefined
            left: isUser ? undefined : parent.left
            rightMargin: Theme.horizontalPageMargin
            leftMargin: Theme.horizontalPageMargin
        }
        // Don't let a bubble span the whole width — leave room on the other side.
        width: Math.min(label.implicitWidth + 2 * Theme.paddingMedium,
                        bubble.width - Theme.horizontalPageMargin - bubble.width * 0.18)
        height: label.implicitHeight + 2 * Theme.paddingMedium
        radius: Theme.paddingMedium
        color: isUser ? Theme.rgba(Theme.highlightBackgroundColor, 0.25)
                      : Theme.rgba(Theme.primaryColor, 0.08)

        Label {
            id: label
            anchors {
                fill: parent
                margins: Theme.paddingMedium
            }
            text: content
            wrapMode: Text.Wrap
            // Let the AI reply use very light markdown-ish formatting nicely.
            textFormat: Text.PlainText
            color: isUser ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
