// SettingsPage.qml
// Where you point the app at your brain. Things to set:
//   - Provider: OpenRouter, Google, or local Ollama
//   - API keys for hosted providers
//   - Server address for local Ollama
//   - Which model to chat with
// There's a "Find models" button that asks the selected provider what it offers.

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/ollama.js" as Ollama

Page {
    id: settings
    allowedOrientations: Orientation.All

    property var foundModels: []

    function providerIndex() {
        if (app.provider === "google")
            return 1;
        if (app.provider === "ollama")
            return 2;
        return 0;
    }

    function setProvider(name) {
        app.provider = name;
        settings.foundModels = [];
        statusLabel.text = "";
    }

    function setSelectedModel(name) {
        if (app.provider === "google") {
            app.googleModelName = name;
            googleModelField.text = name;
        } else if (app.provider === "ollama") {
            app.ollamaModelName = name;
            ollamaModelField.text = name;
        } else {
            app.modelName = name;
            openRouterModelField.text = name;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Settings") }

            ComboBox {
                width: parent.width
                label: qsTr("AI provider")
                currentIndex: settings.providerIndex()
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("OpenRouter")
                        onClicked: settings.setProvider("openrouter")
                    }
                    MenuItem {
                        text: qsTr("Google")
                        onClicked: settings.setProvider("google")
                    }
                    MenuItem {
                        text: qsTr("Local Ollama")
                        onClicked: settings.setProvider("ollama")
                    }
                }
            }

            TextField {
                id: openRouterUrlField
                width: parent.width
                visible: app.provider === "openrouter"
                height: visible ? implicitHeight : 0
                text: app.serverUrl
                label: qsTr("OpenRouter endpoint")
                placeholderText: qsTr("https://openrouter.ai/api/v1")
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: app.serverUrl = text
                onTextChanged: app.serverUrl = text
            }

            TextField {
                id: openRouterKeyField
                width: parent.width
                visible: app.provider === "openrouter"
                height: visible ? implicitHeight : 0
                text: app.apiKey
                label: qsTr("API key (OpenRouter)")
                placeholderText: qsTr("sk-or-…")
                echoMode: TextInput.PasswordEchoOnEdit
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                                  | Qt.ImhHiddenText | Qt.ImhSensitiveData
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: app.apiKey = text
                onTextChanged: app.apiKey = text
            }

            TextField {
                id: openRouterModelField
                width: parent.width
                visible: app.provider === "openrouter"
                height: visible ? implicitHeight : 0
                text: app.modelName
                label: qsTr("OpenRouter model")
                placeholderText: "openai/gpt-oss-20b:free"
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: app.modelName = text
                onTextChanged: app.modelName = text
            }

            TextField {
                id: googleKeyField
                width: parent.width
                visible: app.provider === "google"
                height: visible ? implicitHeight : 0
                text: app.googleApiKey
                label: qsTr("API key (Google)")
                placeholderText: qsTr("Google API key")
                echoMode: TextInput.PasswordEchoOnEdit
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                                  | Qt.ImhHiddenText | Qt.ImhSensitiveData
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: app.googleApiKey = text
                onTextChanged: app.googleApiKey = text
            }

            TextField {
                id: googleModelField
                width: parent.width
                visible: app.provider === "google"
                height: visible ? implicitHeight : 0
                text: app.googleModelName
                label: qsTr("Google model")
                placeholderText: "gemini-2.5-flash"
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: app.googleModelName = text
                onTextChanged: app.googleModelName = text
            }

            TextField {
                id: ollamaUrlField
                width: parent.width
                visible: app.provider === "ollama"
                height: visible ? implicitHeight : 0
                text: app.ollamaServerUrl
                label: qsTr("Ollama server")
                placeholderText: qsTr("http://100.120.174.125:11434")
                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: app.ollamaServerUrl = text
                onTextChanged: app.ollamaServerUrl = text
            }

            TextField {
                id: ollamaModelField
                width: parent.width
                visible: app.provider === "ollama"
                height: visible ? implicitHeight : 0
                text: app.ollamaModelName
                label: qsTr("Ollama model")
                placeholderText: "gpt-oss:20b"
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: app.ollamaModelName = text
                onTextChanged: app.ollamaModelName = text
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Find models")
                onClicked: {
                    statusLabel.text = qsTr("Asking %1…").arg(app.providerLabel());
                    Ollama.listModels(app.provider, app.activeServerUrl(), app.activeApiKey(), {
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
                        color: modelData === app.activeModelName()
                               ? Theme.highlightColor : Theme.primaryColor
                    }
                    onClicked: {
                        settings.setSelectedModel(modelData);
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
                text: qsTr("Switch providers here without rebuilding the app. "
                           + "OpenRouter and Google use separate saved API keys. "
                           + "Local Ollama uses your private server address and no key.")
            }
        }
    }
}
