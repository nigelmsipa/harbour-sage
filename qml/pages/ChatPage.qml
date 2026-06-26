// ChatPage.qml
// The main screen. This is where the whole experience happens:
//   - a scrolling list of chat bubbles
//   - a pulley menu (swipe DOWN from the top) for "New chat" and "Settings"
//   - a text box + send button docked at the bottom
//   - the live streaming reply from your Ollama server
//
// It leans on two helpers:
//   app.conversation  -> the shared message list (defined in harbour-sage.qml)
//   Ollama            -> the telephone-line code (js/ollama.js)

import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import "../components"
import "../js/ollama.js" as Ollama

Page {
    id: page

    // True while a reply is streaming in — used to disable send and show dots.
    property bool busy: false
    // Handle to the in-flight request so we can stop generation.
    property var currentRequest: null

    allowedOrientations: Orientation.All

    // --- Sending a message -------------------------------------------------
    function sendMessage(text) {
        text = text.trim();
        if (text.length === 0 || busy)
            return;

        // 1. Add the user's message to the conversation.
        app.conversation.append({ "role": "user", "content": text });

        // 2. Add an empty assistant bubble that we'll fill as words stream in.
        app.conversation.append({ "role": "assistant", "content": "" });
        var replyIndex = app.conversation.count - 1;

        busy = true;
        scrollToBottom();

        // 3. Build the message history Ollama expects (plain {role,content}).
        var history = [];
        for (var i = 0; i < app.conversation.count; i++) {
            var m = app.conversation.get(i);
            // Skip the empty placeholder we just added.
            if (i === replyIndex)
                continue;
            history.push({ "role": m.role, "content": m.content });
        }

        // 4. Dial the server and stream the answer into the placeholder bubble.
        currentRequest = Ollama.sendChat(app.provider, app.activeServerUrl(),
                                         app.activeApiKey(), app.activeModelName(),
                                         history, {
            onDelta: function(chunk) {
                var current = app.conversation.get(replyIndex).content;
                app.conversation.setProperty(replyIndex, "content", current + chunk);
                scrollToBottom();
            },
            onDone: function() {
                busy = false;
                currentRequest = null;
                app.saveCurrentChat();   // persist the finished exchange
            },
            onError: function(msg) {
                app.conversation.setProperty(replyIndex, "content", "⚠️ " + msg);
                busy = false;
                currentRequest = null;
            }
        });
    }

    function stopGeneration() {
        if (currentRequest) {
            currentRequest.abort();
            currentRequest = null;
        }
        busy = false;
    }

    function scrollToBottom() {
        // Defer one frame so the new bubble's height is known first.
        scrollTimer.restart();
    }

    Timer {
        id: scrollTimer
        interval: 30
        onTriggered: chatView.positionViewAtEnd()
    }

    // --- The scrolling list of bubbles ------------------------------------
    SilicaListView {
        id: chatView
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: inputArea.top
        }
        clip: true
        model: app.conversation
        spacing: Theme.paddingSmall

        // Pulley menu — Sailfish's signature swipe-down menu.
        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("New chat")
                onClicked: {
                    stopGeneration();
                    app.newChat();   // saves the current one, then clears
                }
            }
        }

        header: PageHeader {
            title: "Sage"
            description: app.providerLabel() + " · " + app.activeModelName()
        }

        delegate: MessageItem {
            role: model.role
            content: model.content
        }

        // Friendly empty state before the first message.
        ViewPlaceholder {
            enabled: app.conversation.count === 0
            text: qsTr("Say hello")
            hintText: qsTr("Chatting with %1").arg(app.activeModelName())
        }

        // Keep the typing dots pinned just under the last bubble.
        footer: Item {
            width: chatView.width
            height: page.busy ? typing.height + Theme.paddingMedium : 0
            TypingIndicator {
                id: typing
                x: Theme.horizontalPageMargin
                visible: page.busy
            }
        }

        VerticalScrollDecorator { }
    }

    // --- The input dock at the bottom -------------------------------------
    Rectangle {
        id: inputArea
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: inputRow.height + Theme.paddingMedium
        color: Theme.rgba(Theme.highlightDimmerColor, 0.4)

        Row {
            id: inputRow
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.paddingMedium
            }
            spacing: Theme.paddingSmall

            TextField {
                id: input
                width: parent.width - sendButton.width - parent.spacing
                placeholderText: qsTr("Message Sage…")
                label: qsTr("Message")
                // Let the field grow to several lines for longer prompts.
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    page.sendMessage(text);
                    text = "";
                }
            }

            IconButton {
                id: sendButton
                anchors.verticalCenter: input.verticalCenter
                icon.source: page.busy ? "image://theme/icon-m-clear"
                                       : "image://theme/icon-m-send"
                onClicked: {
                    if (page.busy) {
                        page.stopGeneration();
                    } else {
                        page.sendMessage(input.text);
                        input.text = "";
                    }
                }
            }
        }
    }

    // Open a saved chat from the sidebar, safely stopping any reply in flight.
    function openChat(id) {
        stopGeneration();
        app.loadChat(id);
        sidebar.open = false;
        scrollToBottom();
    }

    // --- The "dot": a round button (top-left) that opens the chats sidebar --
    Rectangle {
        id: chatsDot
        width: Theme.itemSizeSmall
        height: width
        radius: width / 2
        z: 5
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Theme.paddingMedium
            topMargin: Theme.paddingMedium
        }
        color: Theme.rgba(Theme.highlightBackgroundColor, 0.25)
        // Fade the dot away while the sidebar is open (it's covered anyway).
        opacity: sidebar.open ? 0.0 : 1.0
        Behavior on opacity { FadeAnimation { } }

        Icon {
            anchors.centerIn: parent
            source: "image://theme/icon-m-menu"
            color: Theme.highlightColor
        }
        MouseArea {
            anchors.fill: parent
            enabled: !sidebar.open
            onClicked: sidebar.open = true
        }
    }

    // --- Full-screen frosted backdrop while the drawer is open ------------
    // The WHOLE chat behind gets blurred (not just under the panel), so only
    // the sidebar's list on top stays sharp and legible.
    Item {
        id: drawerOverlay
        anchors.fill: parent
        z: 7
        opacity: sidebar.open ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { FadeAnimation { } }

        // Live snapshot of the entire chat page, captured at LOW resolution.
        // Downscaling first is the trick that makes the blur genuinely creamy —
        // FastBlur's radius maxes at 64 which isn't enough on a high-DPI phone,
        // so we shrink to 1/12 then blur, which smears the text away completely.
        ShaderEffectSource {
            id: drawerBackdrop
            anchors.fill: parent
            sourceItem: chatView
            live: true
            visible: false
            textureSize: Qt.size(Math.max(1, width / 12), Math.max(1, height / 12))
        }
        // ...blurred into frosted glass across the whole screen.
        FastBlur {
            anchors.fill: parent
            source: drawerBackdrop
            radius: 64
        }
        // Ambience tint over the blur (not black). Knob: raise = darker.
        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightDimmerColor, 0.52)
        }
        // Tap anywhere outside the drawer to close it.
        MouseArea {
            anchors.fill: parent
            enabled: sidebar.open
            onClicked: sidebar.open = false
        }
    }

    // --- The sidebar drawer: slides in from the left ----------------------
    Rectangle {
        id: sidebar
        z: 9
        property bool open: false
        property var chats: []

        function refresh() { chats = app.loadIndex(); }
        onOpenChanged: if (open) refresh();

        width: Math.min(page.width * 0.82, Theme.itemSizeHuge * 4)
        height: page.height
        x: open ? 0 : -width
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

        color: "transparent"

        ShaderEffectSource {
            id: sidebarSnapshot
            anchors.fill: parent
            sourceItem: chatView
            live: sidebar.open
            visible: false
            textureSize: Qt.size(Math.max(1, width / 12), Math.max(1, height / 12))
        }
        FastBlur {
            anchors.fill: parent
            source: sidebarSnapshot
            radius: 64
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.overlayBackgroundColor, 0.18)
        }
        // Swallow taps on blank panel areas so they don't close the drawer.
        MouseArea { anchors.fill: parent }

        SilicaListView {
            id: sidebarList
            anchors.fill: parent
            clip: true
            model: sidebar.chats

            header: Column {
                width: sidebarList.width
                spacing: Theme.paddingMedium

                PageHeader { title: qsTr("Chats") }

                // A prominent "New chat" action at the top of the drawer.
                BackgroundItem {
                    width: parent.width
                    height: Theme.itemSizeMedium
                    onClicked: {
                        page.stopGeneration();
                        app.newChat();
                        sidebar.open = false;
                    }
                    Row {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.horizontalPageMargin
                        }
                        spacing: Theme.paddingMedium
                        Icon {
                            source: "image://theme/icon-m-add"
                            color: Theme.highlightColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Label {
                            text: qsTr("New chat")
                            color: Theme.highlightColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            ViewPlaceholder {
                enabled: sidebar.chats.length === 0
                text: qsTr("No saved chats yet")
            }

            delegate: ListItem {
                id: chatRow
                width: sidebarList.width
                contentHeight: Theme.itemSizeMedium
                highlighted: down || modelData.id === app.currentChatId

                function remove() {
                    remorseAction(qsTr("Deleting"), function() {
                        app.deleteChat(modelData.id);
                        sidebar.refresh();
                    });
                }

                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: chatRow.remove()
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
                        color: (modelData.id === app.currentChatId)
                               ? Theme.highlightColor : Theme.primaryColor
                    }
                    Label {
                        width: parent.width
                        text: Qt.formatDateTime(new Date(modelData.updated), "ddd d MMM, hh:mm")
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                    }
                }

                onClicked: page.openChat(modelData.id)
            }

            VerticalScrollDecorator { }
        }
    }
}
