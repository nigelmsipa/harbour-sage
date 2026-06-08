// harbour-sage.cpp
// The "ignition key." Boots the QML user interface. We expand the usual
// one-liner slightly so we can hand our FileIO helper to QML — that's what
// lets the app save and load past chats.

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QGuiApplication>
#include <QQuickView>
#include <QQmlContext>
#include <sailfishapp.h>

#include "fileio.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app = SailfishApp::application(argc, argv);
    QQuickView *view = SailfishApp::createView();

    // Make "FileIO" available to every QML file as a global object.
    FileIO fileio;
    view->rootContext()->setContextProperty("FileIO", &fileio);

    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    int result = app->exec();

    delete view;
    delete app;
    return result;
}
