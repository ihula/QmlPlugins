#include "utils.h"
#include "hulalogger.h"
#include <QCryptographicHash>
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

QString Utils::getFileHash(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QFile::ReadOnly))
        return QString();

    QCryptographicHash hash(QCryptographicHash::Md5);
    hash.addData(&file);
    return hash.result().toHex();
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
                qDebug() << QString("Failed to copy file: %1 -> %2: %3").arg(fileInfo.filePath(), dstPath, srcFile.errorString());
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
        qDebug() << QString("Source file does not exist: %1").arg(cleanSrc);
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
            qDebug() << QString("Failed to remove target file: %1: %2").arg(cleanDst, dstFile.errorString());
            return false;
        }
    }

    QDir dstDir = dstInfo.absoluteDir();
    if (!dstDir.exists())
    {
        if (!dstDir.mkpath(dstDir.absolutePath()))
        {
            qDebug() << QString("Failed to create target directory: %1").arg(dstDir.absolutePath());
            return false;
        }
    }

    QFile srcFile(cleanSrc);
    if (!srcFile.copy(cleanDst))
    {
        qDebug() << QString("Failed to copy file: %1 -> %2: %3").arg(cleanSrc, cleanDst, srcFile.errorString());
        return false;
    }

    qDebug() << QString("Copied file: %1 -> %2").arg(cleanSrc, cleanDst);
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

bool Utils::syncDir(const QString &src, const QString &dst)
{
    Q_UNUSED(src)
    Q_UNUSED(dst)
    /*
    QString cleanSrc = QDir::cleanPath(QDir(src).absolutePath());
    QString cleanDst = QDir::cleanPath(QDir(dst).absolutePath());

    QDir srcObj(cleanSrc);
    QDir dstObj(cleanDst);

    bool srcExists = srcObj.exists();
    bool dstExists = dstObj.exists();

    // 两个文件夹都不存在 → 返回失败
    if (!srcExists && !dstExists)
    {
        qDebug() << QString("Both directories do not exist: %1, %2").arg(cleanSrc, cleanDst);
        return false;
    }

    // 源文件夹不存在，目标文件夹存在 → 创建源文件夹
    if (!srcExists && dstExists)
    {
        if (!srcObj.mkpath(cleanSrc))
        {
            qDebug() << QString("Failed to create directory: %1").arg(cleanSrc);
            return false;
        }
        qDebug() << QString("Created directory: %1").arg(cleanSrc);
    }

    // 目标文件夹不存在，源文件夹存在 → 创建目标文件夹
    if (srcExists && !dstExists)
    {
        qDebug() << QString("Destination directory do not exist: %1").arg(cleanDst);
        return false;
    }

    // a: dst根目录的文件名列表
    QList<QString> dstRootFiles;
    QDirIterator itA(dst, QDir::Files | QDir::NoDotAndDotDot);
    while (itA.hasNext())
    {
        QFileInfo fi(itA.next());
        QString filePath = fi.filePath();
        if (filePath.startsWith(dst))
            filePath = filePath.mid(dst.length());
        dstRootFiles << filePath;
    }

    // b: dst根目录的子目录名列表（递归）
    QList<QString> dstDirs;
    QDirIterator itB(dst, QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    while (itB.hasNext())
    {
        QFileInfo fi(itB.next());
        QString path = fi.path();
        if (path.startsWith(dst))
            path = path.mid(dst.length());
        dstDirs << path;
    }

    // List2: dst根目录及所有子目录中的文件（递归）
    QList<QString> dstFiles;
    QDirIterator it2(dst, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    while (it2.hasNext())
    {
        QFileInfo fi(it2.next());
        QString filePath = fi.filePath();
        dstFiles << filePath;
    }

    // List3: src中有、且与dst对应路径下的文件（相对路径）
    QList<QString> srcFiles;
    // List4: src中有、但不在List3中的文件（相对路径）
    QList<QString> srcNewFiles;

    for (int i = 0; i < dstRootFiles.size(); i++)
    {
        QFileInfo fi(src + "/" + dstRootFiles[i]);
        if (!fi.exists())
        {
            QFile::remove(dst + "/" + dstRootFiles[i]);
        }
    }

    // 在src中递归查找文件
    QDirIterator it3(src, QDir::Files | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    while (it3.hasNext())
    {
        QFileInfo fi(it3.next());
        QString path = fi.filePath();
        if ()

        QString relativePath = srcFullPath.mid(cleanSrc.length() + 1);
        QString topLevelName = relativePath.split(QDir::separator()).first();

        bool found = false;

        // 检查是否在a中（直接同名文件）
        if (a.contains(topLevelName))
        {
            found = true;
        }
        // 检查是否在b中（子目录下的文件）
        else if (b.contains(topLevelName))
        {
            // 在src中查找b中各子目录下的文件
            QString subPath = relativePath.mid(topLevelName.length() + 1);
            QString dstFullPath = cleanDst + QDir::separator() + topLevelName + QDir::separator() + subPath;
            if (QFileInfo::exists(dstFullPath))
            {
                found = true;
            }
        }

        if (found)
        {
            list3[relativePath] = srcFullPath;
        }
        else
        {
            list4[relativePath] = srcFullPath;
        }
    }

    int copiedToDst = 0;  // List4复制到dst
    int updatedCount = 0; // List3与List2比较后更新的文件
    int deletedCount = 0; // List2中存在但List3中不存在的文件
    int skippedCount = 0; // 内容相同跳过

    // 步骤4：将List4中所有文件复制到dst同路径下
    for (auto it = list4.begin(); it != list4.end(); ++it)
    {
        const QString &relativePath = it.key();
        const QString &srcPath = it.value();
        QString dstPath = cleanDst + QDir::separator() + relativePath;

        // 确保目标目录存在
        QDir dstDir = QFileInfo(dstPath).absoluteDir();
        if (!dstDir.exists())
        {
            if (!dstDir.mkpath(dstDir.absolutePath()))
            {
                qDebug() << QString("Failed to create directory: %1").arg(dstDir.absolutePath());
                return false;
            }
        }

        if (!QFile::copy(srcPath, dstPath))
        {
            qDebug() << QString("Failed to copy file: %1 -> %2").arg(srcPath, dstPath);
            return false;
        }
        copiedToDst++;
        qDebug() << QString("Copied to dst: %1").arg(relativePath);
    }

    // 步骤5：将List3中的文件与List2中比较，用新的且内容不同的文件替换掉旧文件
    for (auto it = list3.begin(); it != list3.end(); ++it)
    {
        const QString &relativePath = it.key();
        if (list2.contains(relativePath))
        {
            const QString &srcPath = it.value();
            const QString &dstPath = list2[relativePath];

            QString srcHash = Utils::getFileHash(srcPath);
            QString dstHash = Utils::getFileHash(dstPath);

            if (srcHash == dstHash)
            {
                skippedCount++;
            }
            else
            {
                // 内容不同，比较mtime决定方向
                QFileInfo srcInfo(srcPath);
                QFileInfo dstInfo(dstPath);

                if (srcInfo.lastModified() > dstInfo.lastModified())
                {
                    // src更新，复制到dst
                    if (!QFile::remove(dstPath) || !QFile::copy(srcPath, dstPath))
                    {
                        qDebug() << QString("Failed to sync file: %1 -> %2").arg(srcPath, dstPath);
                        return false;
                    }
                    updatedCount++;
                    qDebug() << QString("Updated (src->dst): %1").arg(relativePath);
                }
                else if (dstInfo.lastModified() > srcInfo.lastModified())
                {
                    // dst更新，复制到src
                    if (!QFile::remove(srcPath) || !QFile::copy(dstPath, srcPath))
                    {
                        qDebug() << QString("Failed to sync file: %1 -> %2").arg(dstPath, srcPath);
                        return false;
                    }
                    updatedCount++;
                    qDebug() << QString("Updated (dst->src): %1").arg(relativePath);
                }
                else
                {
                    // 时间戳相同但hash不同，从src复制到dst
                    if (!QFile::remove(dstPath) || !QFile::copy(srcPath, dstPath))
                    {
                        qDebug() << QString("Failed to sync file: %1 -> %2").arg(srcPath, dstPath);
                        return false;
                    }
                    updatedCount++;
                    qDebug() << QString("Updated (content differs): %1").arg(relativePath);
                }
            }
        }
    }

    // 步骤6：将存在于List2不存在于List3中的文件删除
    for (auto it = list2.begin(); it != list2.end(); ++it)
    {
        const QString &relativePath = it.key();
        if (!list3.contains(relativePath))
        {
            const QString &dstPath = it.value();
            if (QFile::remove(dstPath))
            {
                deletedCount++;
                qDebug() << QString("Deleted: %1").arg(relativePath);
            }
        }
    }

    if (copiedToDst > 0 || updatedCount > 0 || deletedCount > 0 || skippedCount > 0)
    {
        qDebug() << QString("Sync completed - Copied: %1, Updated: %2, Deleted: %3, Skipped: %4").arg(copiedToDst).arg(updatedCount).arg(deletedCount).arg(skippedCount);
    }
*/
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
        qDebug() << QString("Both file do not exist: %1, %2").arg(cleanSrc, cleanDst);
        return false;
    }

    // 2：源文件存在，目标文件不存在 → 复制源到目标
    if (srcInfo.exists() && !dstInfo.exists())
    {
        if (!QFile::copy(cleanSrc, cleanDst))
        {
            qDebug() << QString("Failed to copy file: %1 -> %2").arg(cleanSrc, cleanDst);
            return false;
        }
        qDebug() << QString("Synced file: %1 -> %2").arg(cleanSrc, cleanDst);
        return true;
    }

    // 3：源文件不存在，目标文件存在 → 复制目标到源
    if (!srcInfo.exists() && dstInfo.exists())
    {
        if (!QFile::copy(cleanDst, cleanSrc))
        {
            qDebug() << QString("Failed to copy file: %1 -> %2").arg(cleanDst, cleanSrc);
            return false;
        }
        qDebug() << QString("Synced file: %1 -> %2").arg(cleanDst, cleanSrc);
        return true;
    }

    // 4：两个文件都存在，比较更新时间
    QString srcHash = Utils::getFileHash(cleanSrc);
    QString dstHash = Utils::getFileHash(cleanDst);

    // 源文件更新 → 覆盖目标文件
    if (srcInfo.lastModified() > dstInfo.lastModified())
    {
        if (srcHash == dstHash)
        {
            qDebug() << QString("Files are identical (hash match), skipping: %1 -> %2").arg(cleanSrc, cleanDst);
            return true;
        }
        if (!QFile::remove(cleanDst) || !QFile::copy(cleanSrc, cleanDst))
        {
            qDebug() << QString("Failed to sync file: %1 -> %2").arg(cleanSrc, cleanDst);
            return false;
        }
        qDebug() << QString("Synced file: %1 -> %2").arg(cleanSrc, cleanDst);
        return true;
    }

    // 目标文件更新 → 覆盖源文件
    if (srcInfo.lastModified() < dstInfo.lastModified())
    {
        if (srcHash == dstHash)
        {
            qDebug() << QString("Files are identical (hash match), skipping: %1 -> %2").arg(cleanDst, cleanSrc);
            return true;
        }
        if (!QFile::remove(cleanSrc) || !QFile::copy(cleanDst, cleanSrc))
        {
            qDebug() << QString("Failed to sync file: %1 -> %2").arg(cleanDst, cleanSrc);
            return false;
        }
        qDebug() << QString("Synced file: %1 -> %2").arg(cleanDst, cleanSrc);
        return true;
    }

    // 时间戳相同但 hash 不同，说明文件被修改过，需要同步
    if (srcHash != dstHash)
    {
        if (!QFile::remove(cleanDst) || !QFile::copy(cleanSrc, cleanDst))
        {
            qDebug() << QString("Failed to sync file: %1 -> %2").arg(cleanSrc, cleanDst);
            return false;
        }
        qDebug() << QString("Synced file (content changed): %1 -> %2").arg(cleanSrc, cleanDst);
        return true;
    }

    return true;
}

QStringList Utils::getCustomProperties(QObject *obj)
{
    QStringList properties;
    if (!obj)
        return properties;

    const QMetaObject *meta = obj->metaObject();
    // 遍历所有属性
    for (int i = 0; i < meta->propertyCount(); ++i)
    {
        QMetaProperty prop = meta->property(i);
        properties << QString::fromLatin1(prop.name());
    }
    return properties;
}

QStringList Utils::getCustomProps(QObject *obj)
{
    QStringList props;
    if (!obj)
        return props;

    const QMetaObject *meta = obj->metaObject();
    // 使用 propertyOffset() 跳过基类的属性，只获取当前类及子类新增的属性
    for (int i = meta->propertyOffset(); i < meta->propertyCount(); ++i)
    {
        QMetaProperty prop = meta->property(i);
        props << QString::fromLatin1(prop.name());
    }
    return props;
}

void Utils::saveToJson(const QVariantMap &data, const QString &filePath)
{
    // 使用 QJsonDocument 将 QVariantMap 序列化并写入文件
    QJsonDocument doc = QJsonDocument::fromVariant(data);
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly))
    {
        file.write(doc.toJson());
    }
}
