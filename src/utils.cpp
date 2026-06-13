#include "utils.h"
#include "hulalogger.h"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QMessageLogContext>

QStringList Utils::getDirFiles(const QString &path, const QStringList &filter)
{
    QStringList fileList;
    QDir dir(path);
    if (!dir.exists())
        return fileList;

    QDirIterator it(path, filter, QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot | QDir::Dirs);
    while (it.hasNext())
    {
        fileList.append(QFileInfo(it.next()).fileName());
    }
    return fileList;
}

bool Utils::copyDir(const QString &sourceDir, const QString &toDir, bool overwrite)
{
    QString cleanToDir = QDir::cleanPath(toDir);
    QString cleanSourceDir = QDir::cleanPath(sourceDir);

    if (cleanSourceDir == cleanToDir)
        return true;

    QDir srcDir(cleanSourceDir);
    if (!srcDir.exists())
        return false;

    QDir dstDir(cleanToDir);
    if (dstDir.exists())
    {
        if (overwrite)
            dstDir.removeRecursively();
        else
            return false;
    }

    if (!dstDir.mkpath(cleanToDir))
        return false;

    const QFileInfoList fileInfoList = srcDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    const int fileCount = fileInfoList.count();
    for (int i = 0; i < fileCount; ++i)
    {
        const QFileInfo &fileInfo = fileInfoList.at(i);
        QString dstPath = QDir::cleanPath(cleanToDir + QDir::separator() + fileInfo.fileName());
        if (fileInfo.isDir())
        {
            if (!copyDir(fileInfo.filePath(), dstPath, overwrite))
                return false;
        }
        else
        {
            QFile srcFile(fileInfo.filePath());
            if (!srcFile.copy(dstPath))
            {
                HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to copy file: %1 -> %2: %3").arg(fileInfo.filePath(), dstPath, srcFile.errorString()), QMessageLogContext());
                return false;
            }
        }
    }

    return true;
}

bool Utils::updateFile(const QString &src, const QString &dst, bool overwrite)
{
    QString cleanSrc = QDir::cleanPath(src);
    QString cleanDst = QDir::cleanPath(dst);

    QFileInfo srcInfo(cleanSrc);
    if (!srcInfo.exists())
    {
        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Source file does not exist: %1").arg(cleanSrc), QMessageLogContext());
        return false;
    }

    QFileInfo dstInfo(cleanDst);
    if (dstInfo.exists())
    {
        if (!overwrite && srcInfo.lastModified() <= dstInfo.lastModified())
        {
            return true;
        }

        QFile dstFile(cleanDst);
        if (!dstFile.remove())
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to remove target file: %1: %2").arg(cleanDst, dstFile.errorString()), QMessageLogContext());
            return false;
        }
    }

    QDir dstDir = dstInfo.absoluteDir();
    if (!dstDir.exists())
    {
        if (!dstDir.mkpath(dstDir.absolutePath()))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to create target directory: %1").arg(dstDir.absolutePath()), QMessageLogContext());
            return false;
        }
    }

    QFile srcFile(cleanSrc);
    if (!srcFile.copy(cleanDst))
    {
        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to copy file: %1 -> %2: %3").arg(cleanSrc, cleanDst, srcFile.errorString()), QMessageLogContext());
        return false;
    }

    HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Copied file: %1 -> %2").arg(cleanSrc, cleanDst), QMessageLogContext());
    return true;
}

QDateTime Utils::getDirLatestTime(const QString &dirPath)
{
    QDir dir(dirPath);
    QDateTime latestTime = QFileInfo(dirPath).lastModified();

    const QFileInfoList fileList = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    const int fileCount = fileList.count();
    for (int i = 0; i < fileCount; ++i)
    {
        const QFileInfo &fileInfo = fileList.at(i);
        if (fileInfo.isDir())
        {
            latestTime = qMax(latestTime, Utils::getDirLatestTime(fileInfo.filePath()));
        }
        else
        {
            latestTime = qMax(latestTime, fileInfo.lastModified());
        }
    }
    return latestTime;
}

bool Utils::syncDir(const QString &dir1, const QString &dir2, bool deleteOrphaned)
{
    QString cleanDir1 = QDir::cleanPath(dir1);
    QString cleanDir2 = QDir::cleanPath(dir2);

    QDir dir1Obj(cleanDir1);
    QDir dir2Obj(cleanDir2);

    bool dir1Exists = dir1Obj.exists();
    bool dir2Exists = dir2Obj.exists();

    // 两个文件夹都不存在 → 返回失败
    if (!dir1Exists && !dir2Exists)
    {
        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Both directories do not exist: %1, %2").arg(cleanDir1, cleanDir2), QMessageLogContext());
        return false;
    }

    // 源文件夹不存在，目标文件夹存在 → 创建源文件夹
    if (!dir1Exists && dir2Exists)
    {
        if (!dir1Obj.mkpath(cleanDir1))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to create directory: %1").arg(cleanDir1), QMessageLogContext());
            return false;
        }
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Created directory: %1").arg(cleanDir1), QMessageLogContext());
    }

    // 目标文件夹不存在，源文件夹存在 → 创建目标文件夹
    if (dir1Exists && !dir2Exists)
    {
        if (!dir2Obj.mkpath(cleanDir2))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to create directory: %1").arg(cleanDir2), QMessageLogContext());
            return false;
        }
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Created directory: %1").arg(cleanDir2), QMessageLogContext());
    }

    QDateTime time1 = Utils::getDirLatestTime(cleanDir1);
    QDateTime time2 = Utils::getDirLatestTime(cleanDir2);

    QString source;
    QString target;
    if (time1 >= time2)
    {
        source = cleanDir1;
        target = cleanDir2;
    }
    else
    {
        source = cleanDir2;
        target = cleanDir1;
    }

    HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Syncing from newer directory: %1 -> %2").arg(source, target), QMessageLogContext());

    int copiedCount = 0;
    int deletedCount = 0;
    int skippedCount = 0;
    QString info = QString("Sync Dir: %1 >> %2").arg(source, target);

    QDir srcDir(source);
    QDir dstDir(target);

    if (deleteOrphaned)
    {
        const QFileInfoList dstFileList = dstDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
        const int dstFileCount = dstFileList.count();
        for (int i = 0; i < dstFileCount; ++i)
        {
            const QFileInfo &fileInfo = dstFileList.at(i);
            if (!srcDir.exists(fileInfo.fileName()))
            {
                QString targetPath = QDir::cleanPath(target + QDir::separator() + fileInfo.fileName());
                if (fileInfo.isDir())
                {
                    QDir dirToRemove(targetPath);
                    if (dirToRemove.removeRecursively())
                    {
                        deletedCount++;
                        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Deleted directory: %1").arg(fileInfo.fileName()), QMessageLogContext());
                    }
                    else
                    {
                        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to delete directory: %1").arg(fileInfo.fileName()), QMessageLogContext());
                    }
                }
                else
                {
                    QFile fileToRemove(targetPath);
                    if (fileToRemove.remove())
                    {
                        deletedCount++;
                        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Deleted file: %1").arg(fileInfo.fileName()), QMessageLogContext());
                    }
                    else
                    {
                        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to delete file: %1: %2").arg(fileInfo.fileName(), fileToRemove.errorString()), QMessageLogContext());
                    }
                }
            }
        }
    }

    const QFileInfoList fileInfoList = srcDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    const int fileCount = fileInfoList.count();
    for (int i = 0; i < fileCount; ++i)
    {
        const QFileInfo &fileInfo = fileInfoList.at(i);
        QString targetPath = QDir::cleanPath(target + QDir::separator() + fileInfo.fileName());

        if (fileInfo.isDir())
        {
            if (!syncDir(fileInfo.filePath(), targetPath, deleteOrphaned))
                return false;
        }
        else
        {
            bool needCopy = true;
            if (dstDir.exists(fileInfo.fileName()))
            {
                QFileInfo dstFile(targetPath);
                if (fileInfo.lastModified() <= dstFile.lastModified())
                {
                    needCopy = false;
                    skippedCount++;
                }
            }

            if (needCopy)
            {
                if (dstDir.exists(fileInfo.fileName()))
                {
                    QFile fileToRemove(targetPath);
                    if (!fileToRemove.remove())
                    {
                        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to remove file: %1: %2").arg(fileInfo.fileName(), fileToRemove.errorString()), QMessageLogContext());
                        return false;
                    }
                }

                QFile srcFile(fileInfo.filePath());
                if (!srcFile.copy(targetPath))
                {
                    HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to copy file: %1 -> %2: %3").arg(fileInfo.filePath(), targetPath, srcFile.errorString()), QMessageLogContext());
                    return false;
                }
                else
                {
                    copiedCount++;
                    if (copiedCount == 1)
                    {
                        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, info, QMessageLogContext());
                    }
                    HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Copied: %1").arg(fileInfo.fileName()), QMessageLogContext());
                }
            }
        }
    }

    if (copiedCount > 0 || deletedCount > 0 || skippedCount > 0)
    {
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Sync completed - Copied: %1, Deleted: %2, Skipped: %3").arg(copiedCount).arg(deletedCount).arg(skippedCount), QMessageLogContext());
    }

    return true;
}

bool Utils::syncFile(const QString &src, const QString &dst)
{
    QString cleanSrc = QDir::cleanPath(src);
    QString cleanDst = QDir::cleanPath(dst);

    QFileInfo srcInfo(cleanSrc);
    QFileInfo dstInfo(cleanDst);

    // 1：两个文件都不存在
    if (!srcInfo.exists() && !dstInfo.exists())
    {
        HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Both file do not exist: %1, %2").arg(cleanSrc, cleanDst), QMessageLogContext());
        return false;
    }

    // 2：源文件存在，目标文件不存在 → 复制源到目标
    if (srcInfo.exists() && !dstInfo.exists())
    {
        if (!QFile::copy(cleanSrc, cleanDst))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to copy file: %1 -> %2").arg(cleanSrc, cleanDst), QMessageLogContext());
            return false;
        }
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Synced file: %1 -> %2").arg(cleanSrc, cleanDst), QMessageLogContext());
        return true;
    }

    // 3：源文件不存在，目标文件存在 → 复制目标到源
    if (!srcInfo.exists() && dstInfo.exists())
    {
        if (!QFile::copy(cleanDst, cleanSrc))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to copy file: %1 -> %2").arg(cleanDst, cleanSrc), QMessageLogContext());
            return false;
        }
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Synced file: %1 -> %2").arg(cleanDst, cleanSrc), QMessageLogContext());
        return true;
    }

    // 4：两个文件都存在，比较更新时间
    // 源文件更新 → 覆盖目标文件
    if (srcInfo.lastModified() > dstInfo.lastModified())
    {
        if (!QFile::remove(cleanDst) || !QFile::copy(cleanSrc, cleanDst))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to sync file: %1 -> %2").arg(cleanSrc, cleanDst), QMessageLogContext());
            return false;
        }
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Synced file: %1 -> %2").arg(cleanSrc, cleanDst), QMessageLogContext());
        return true;
    }

    // 目标文件更新 → 覆盖源文件
    if (srcInfo.lastModified() < dstInfo.lastModified())
    {
        if (!QFile::remove(cleanSrc) || !QFile::copy(cleanDst, cleanSrc))
        {
            HulaLogger::instance()->log(QtMsgType::QtWarningMsg, QString("Failed to sync file: %1 -> %2").arg(cleanDst, cleanSrc), QMessageLogContext());
            return false;
        }
        HulaLogger::instance()->log(QtMsgType::QtInfoMsg, QString("Synced file: %1 -> %2").arg(cleanDst, cleanSrc), QMessageLogContext());
        return true;
    }

    return true;
}
