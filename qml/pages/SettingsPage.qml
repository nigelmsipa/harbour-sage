// SettingsPage.qml
// Where you point the app at your brain. Two things to set:
//   - Server address (your computer's Tailscale address + Ollama's port)
//   - Which model to chat with
// There's a "Find models" button that asks the server what it has installed,
// so you don't have to remember exact names like "gpt-oss:20b".

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/ollama.js" as Ollama

Page {
    id: settings
    allowedOrientations: Orientation.All

    property var foundModels: []

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Settings") }

            TextField {
                id: urlField
                width: parent.width
                text: app.serverUrl
                label: qsTr("Server address")
                placeholderText: qsTr("http://100.120.174.125:11434")
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: app.serverUrl = text
                onTextChanged: app.serverUrl = text
            }

            TextField {
                id: modelField
                width: parent.width
                text: app.modelName
                label: qsTr("Model")
                placeholderText: "gpt-oss:20b"
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: app.modelName = text
                onTextChanged: app.modelName = text
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Find models on server")
                onClicked: {
                    statusLabel.text = qsTr("Asking the server…");
                    Ollama.listModels(app.serverUrl, {
                        onResult: function(names) {
                            settings.foundModels = names;
                            statusLabel.text = names.length > 0
                                ? qsTr("Tap one below to use it")
                                : qsTr("No models installed on the server");
                        },
                        onError: function(msg) {
                            statusLabel.text = "⚠️ " + msg;
                        }
                    });
                }
            }

            Label {
                id: statusLabel
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: ""
            }

            // The list of models the server reported — tap to select.
            Repeater {
                model: settings.foundModels
                delegate: ListItem {
                    width: column.width
                    Label {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: Theme.horizontalPageMargin
                        }
                        text: modelData
                        color: modelData === app.modelName
                               ? Theme.highlightColor : Theme.primaryColor
                    }
                    onClicked: {
                        app.modelName = modelData;
                        modelField.text = modelData;
                    }
                }
            }

            // A gentle note so future-you remembers what this app talks to.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: qsTr("Sage talks to Ollama on your own machine over your "
                           + "private network. Make sure Ollama is running and "
                           + "reachable at the address above.")
            }
        }
    }
}
