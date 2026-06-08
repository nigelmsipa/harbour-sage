# harbour-sage.pro
# This is the "table of contents" the build tool reads first.
# It says: this is a Sailfish QML app, here are all my files.

TARGET = harbour-sage

CONFIG += sailfishapp

SOURCES += \
    src/harbour-sage.cpp \
    src/fileio.cpp

HEADERS += \
    src/fileio.h

DISTFILES += \
    qml/harbour-sage.qml \
    qml/cover/CoverPage.qml \
    qml/pages/ChatPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/PastChatsPage.qml \
    qml/components/MessageItem.qml \
    qml/components/TypingIndicator.qml \
    qml/js/ollama.js \
    rpm/harbour-sage.spec \
    harbour-sage.desktop \
    translations/*.ts

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# Translations (Sailfish wants this block even if we only have one language)
CONFIG += sailfishapp_i18n
TRANSLATIONS += translations/harbour-sage-en.ts
