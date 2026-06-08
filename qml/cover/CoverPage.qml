// CoverPage.qml
// The "minimized card." When you swipe Sage to the background, Sailfish shows
// this small tile. We show the app name and a peek at the last reply, plus a
// quick "new chat" action you can trigger without even reopening the app.

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    // Grab the most recent message to preview on the card.
    function lastMessageText() {
        var convo = app.conversation;
        if (convo.count === 0)
            return qsTr("Ask me anything");
        return convo.get(convo.count - 1).content;
    }

    Column {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.paddingLarge
        }
        spacing: Theme.paddingMedium

        Label {
            text: "Sage"
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
        }

        Label {
            width: parent.width
            text: cover.lastMessageText()
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 6
            elide: Text.ElideRight
        }
    }

    // The pull-out actions on the cover (swipe left/right on the card).
    CoverActionList {
        id: coverAction
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: app.newChat()
        }
    }
}
