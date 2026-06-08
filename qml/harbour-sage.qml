// harbour-sage.qml
// The "picture frame" of the whole app. Every Sailfish app has one
// ApplicationWindow. It holds two things:
//   - the first page you land on (the chat screen)
//   - the cover (the little card shown when you swipe the app to the background)

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "pages"
import "cover"

ApplicationWindow {
    id: app

    // ---- App-wide settings, kept in one place so every screen can read them.
    // They start from whatever was saved last time (or the defaults below the
    // first time you run). When a screen changes them, we write the new value
    // back to disk so it's remembered next launch.
    property string serverUrl: cfgServerUrl.value
    property string modelName: cfgModelName.value

    onServerUrlChanged: cfgServerUrl.value = serverUrl
    onModelNameChanged: cfgModelName.value = modelName

    // Nemo.Configuration is Sailfish's built-in "saved settings" drawer.
    ConfigurationValue {
        id: cfgServerUrl
        key: "/apps/harbour-sage/serverUrl"
        defaultValue: "http://100.120.174.125:11434"
    }
    ConfigurationValue {
        id: cfgModelName
        key: "/apps/harbour-sage/modelName"
        defaultValue: "gpt-oss:20b"
    }

    // The conversation lives here so both the chat page AND the cover can see it.
    // Each entry is { role: "user"|"assistant", content: "..." }.
    property ListModel conversation: ListModel { }

    // Which saved chat we're currently in. Empty = a brand-new, unsaved chat.
    property string currentChatId: ""

    // ---- Chat history, stored as plain JSON files on disk ----------------
    // Layout under FileIO.dataDir():
    //   chats/index.json      -> [{id, title, updated}, ...]  (the chat list)
    //   chats/<id>.json       -> {id, title, created, updated, messages:[...]}

    function chatsDir() { return FileIO.dataDir + "/chats" }
    function chatPath(id) { return chatsDir() + "/" + id + ".json" }
    function indexPath() { return chatsDir() + "/index.json" }

    function loadIndex() {
        var raw = FileIO.read(indexPath());
        if (!raw)
            return [];
        try { return JSON.parse(raw); } catch (e) { return []; }
    }

    function saveIndex(list) {
        FileIO.mkpath(chatsDir());
        FileIO.write(indexPath(), JSON.stringify(list));
    }

    // Turn the current on-screen conversation into a saved file (and keep the
    // index up to date). Called after each completed reply.
    function saveCurrentChat() {
        if (conversation.count === 0)
            return;
        if (currentChatId === "")
            currentChatId = "chat-" + Date.now();

        // Build a title from the first thing the user said.
        var title = qsTr("New chat");
        for (var i = 0; i < conversation.count; i++) {
            if (conversation.get(i).role === "user") {
                title = conversation.get(i).content.substring(0, 40);
                break;
            }
        }

        var messages = [];
        for (var j = 0; j < conversation.count; j++) {
            var m = conversation.get(j);
            messages.push({ "role": m.role, "content": m.content });
        }

        var now = Date.now();
        var record = {
            "id": currentChatId,
            "title": title,
            "created": now,
            "updated": now,
            "messages": messages
        };
        FileIO.mkpath(chatsDir());
        FileIO.write(chatPath(currentChatId), JSON.stringify(record));

        // Update (or insert) this chat at the top of the index.
        var list = loadIndex();
        var entry = { "id": currentChatId, "title": title, "updated": now };
        var filtered = list.filter(function(e) { return e.id !== currentChatId; });
        filtered.unshift(entry);
        saveIndex(filtered);
    }

    // Replace the on-screen conversation with a saved one.
    function loadChat(id) {
        var raw = FileIO.read(chatPath(id));
        if (!raw)
            return;
        var record;
        try { record = JSON.parse(raw); } catch (e) { return; }
        conversation.clear();
        var msgs = record.messages || [];
        for (var i = 0; i < msgs.length; i++)
            conversation.append({ "role": msgs[i].role, "content": msgs[i].content });
        currentChatId = id;
    }

    // Save whatever we have, then start a fresh empty chat.
    function newChat() {
        saveCurrentChat();
        conversation.clear();
        currentChatId = "";
    }

    function deleteChat(id) {
        FileIO.remove(chatPath(id));
        var list = loadIndex().filter(function(e) { return e.id !== id; });
        saveIndex(list);
        // If we deleted the chat we're looking at, clear the screen too.
        if (id === currentChatId) {
            conversation.clear();
            currentChatId = "";
        }
    }

    initialPage: Component { ChatPage { } }
    cover: Component { CoverPage { } }

    allowedOrientations: defaultAllowedOrientations
}
