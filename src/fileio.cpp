// fileio.cpp — see fileio.h for the why.

#include "fileio.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>
#include <QStandardPaths>

FileIO::FileIO(QObject *parent) : QObject(parent)
{
    // Make sure the data folder exists from the very first launch.
    QDir().mkpath(dataDir());
}

QString FileIO::dataDir() const
{
    // AppDataLocation -> ~/.local/share/harbour-sage on Sailfish.
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

bool FileIO::write(const QString &path, const QString &data)
{
    // Ensure the parent directory exists before writing.
    QFileInfo info(path);
    QDir().mkpath(info.absolutePath());

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return false;
    QTextStream out(&file);
    out.setCodec("UTF-8");
    out << data;
    file.close();
    return true;
}

QString FileIO::read(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return QString();
    QTextStream in(&file);
    in.setCodec("UTF-8");
    QString content = in.readAll();
    file.close();
    return content;
}

bool FileIO::remove(const QString &path)
{
    return QFile::remove(path);
}

bool FileIO::exists(const QString &path)
{
    return QFile::exists(path);
}

bool FileIO::mkpath(const QString &dir)
{
    return QDir().mkpath(dir);
}

QStringList FileIO::list(const QString &dir)
{
    QDir d(dir);
    return d.entryList(QDir::Files, QDir::Name);
}
