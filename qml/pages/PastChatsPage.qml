// PastChatsPage.qml
// The list of your saved conversations. Tap one to reopen it; press and hold
// for a Delete option. The data comes from app.loadIndex() (the chats/index.json
// file written by harbour-sage.qml).

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: pastPage
    allowedOrientations: Orientation.All

    // The list of {id, title, updated}. Refreshed whenever the page appears.
    property var chats: []

    function refresh() {
        chats = app.loadIndex();
    }

    // Reload every time we land on this page (e.g. after deleting one).
    onStatusChanged: {
        if (status === PageStatus.Active)
            refresh();
    }

    // Turn a millisecond timestamp into something human ("Today 14:03", etc.).
    function whenText(ms) {
        if (!ms)
            return "";
        var d = new Date(ms);
        return Qt.formatDateTime(d, "ddd d MMM, hh:mm");
    }

    SilicaListView {
        anchors.fill: parent
        model: pastPage.chats

        header: PageHeader { title: qsTr("Past chats") }

        ViewPlaceholder {
            enabled: pastPage.chats.length === 0
            text: qsTr("No saved chats yet")
            hintText: qsTr("Your conversations will show up here")
        }

        delegate: ListItem {
            id: item
            width: ListView.view.width
            contentHeight: Theme.itemSizeMedium

            function remove() {
                remorseAction(qsTr("Deleting"), function() {
                    app.deleteChat(modelData.id);
                    pastPage.refresh();
                });
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: item.remove()
                }
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }

                Label {
                    width: parent.width
                    text: modelData.title
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: pastPage.whenText(modelData.updated)
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                }
            }

            onClicked: {
                app.loadChat(modelData.id);
                pageStack.pop();   // back to the chat screen, now showing this chat
            }
        }

        VerticalScrollDecorator { }
    }
}
