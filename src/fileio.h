// fileio.h
// A tiny helper that lets our QML screens read and write files on disk.
// QML on its own can't save files, so this little C++ class exposes a few
// simple methods (read / write / list / remove) that the QML can call.
// Everything lives under the app's own private data folder.

#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QString>
#include <QStringList>

class FileIO : public QObject
{
    Q_OBJECT
    // The app's private data folder, e.g. ~/.local/share/harbour-sage
    Q_PROPERTY(QString dataDir READ dataDir CONSTANT)

public:
    explicit FileIO(QObject *parent = nullptr);

    QString dataDir() const;

    // All paths below are absolute (build them from dataDir in QML).
    Q_INVOKABLE bool write(const QString &path, const QString &data);
    Q_INVOKABLE QString read(const QString &path);
    Q_INVOKABLE bool remove(const QString &path);
    Q_INVOKABLE bool exists(const QString &path);
    Q_INVOKABLE bool mkpath(const QString &dir);
    // Returns the file names (not full paths) inside a directory.
    Q_INVOKABLE QStringList list(const QString &dir);
};

#endif // FILEIO_H
