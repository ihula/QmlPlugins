#include "utils.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDirIterator>
#include <QDateTime>
#include <QDebug>


QStringList Utils::getDirFiles(const QString &path, const QStringList &filter)
{
    QStringList fileList;
    QDir dir(path);
    if(!dir.exists())
        return fileList;

    //目录迭代器
    QDirIterator it(path, filter, QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot | QDir::Dirs);
    //QDirIterator::Subdirectories第四个参数可以设置一个文件迭代器标志
    //来访问子文件夹中的符合条件的文件，但是会卡飞天

    //文件遍历流程
    while(it.hasNext())
    {
        it.next();
        QFileInfo fileinfo = it.fileInfo();
        fileList.append(fileinfo.fileName());
    }
    return fileList;
}


bool Utils::copyDir(const QString &sourceDir, const QString &toDir, bool cover)
{
    QString cleanToDir = toDir;
    cleanToDir.replace("\\","/");
    if (sourceDir == cleanToDir)
        return true;

    QDir srcDir(sourceDir);
    if (!srcDir.exists())
        return false;

    QDir dstDir(cleanToDir);
    if (dstDir.exists())
    {
        if(cover)
            dstDir.removeRecursively();
        else
            return false;
    }

    if (!dstDir.mkpath(cleanToDir))
        return false;

    QFileInfoList fileInfoList = srcDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QFileInfo &fileInfo : fileInfoList)
    {
        QString dstPath = cleanToDir + "/" + fileInfo.fileName();
        if (fileInfo.isDir())
        {
            if (!copyDir(fileInfo.filePath(), dstPath, cover))
                return false;
        }
        else
        {
            if (!QFile::copy(fileInfo.filePath(), dstPath))
                return false;
        }
    }

    return true;
}


bool Utils::updateDirFiles(const QString &fromDir, const QString &toDir, bool cover)
{
    QDir sourceDir(fromDir);
    QDir targetDir(toDir);
    // 如果目标目录不存在，则进行创建
    if(!targetDir.exists())
    {
        if(!targetDir.mkdir(targetDir.absolutePath()))
            return false;
    }

    bool firstCopy = true;
    QString info = "Update Dir Files:" + fromDir + " >> " + toDir;

    // 删除源目录不存在的文件
    QFileInfoList dstFileList = targetDir.entryInfoList();
    for (const QFileInfo &fileInfo : dstFileList)
    {
        if(fileInfo.fileName() == "." || fileInfo.fileName() == "..")
            continue;

        if (!sourceDir.exists(fileInfo.fileName()))
        {
            targetDir.remove(fileInfo.fileName());
            qDebug().noquote() << "deleted: " << fileInfo.fileName();
        }
    }

    QFileInfoList fileInfoList = sourceDir.entryInfoList();
    for (const QFileInfo &fileInfo : fileInfoList)
    {
        if(fileInfo.fileName() == "." || fileInfo.fileName() == "..")
        {
            continue;
        }
        if (targetDir.exists(fileInfo.fileName()))
        {
            QFileInfo dstFile(toDir + "/" + fileInfo.fileName());
            if (fileInfo.lastModified() <= dstFile.lastModified())
                continue;
        }
        // 当为目录时，递归的进行copy
        if(fileInfo.isDir())
        {
            if(!updateDirFiles(fileInfo.filePath(), targetDir.filePath(fileInfo.fileName()), cover))
                return false;
        }
        else
        {
            // 当允许覆盖操作时，将旧文件进行删除操作
            if(cover && targetDir.exists(fileInfo.fileName()))
                targetDir.remove(fileInfo.fileName());

            // 进行文件copy
            if(!QFile::copy(fileInfo.filePath(), targetDir.filePath(fileInfo.fileName())))
            {
                return false;
            }
            else
            {
                if (firstCopy)
                {
                    firstCopy = false;
                    qDebug().noquote() << info;
                }
                qDebug().noquote() << fileInfo.fileName();
            }
        }
    }
    return true;
}

bool Utils::updateFile(const QString &src, const QString &dst, bool cover)
{
    QFileInfo srcInfo(src);
    if (!srcInfo.exists())
        return true;
    QFileInfo dstInfo(dst);
    if (dstInfo.exists())
    {
        if (srcInfo.lastModified() <= dstInfo.lastModified())
            return true;
    }

    if (cover)
        QFile::remove(dst);
    // 进行文件copy
    if(!QFile::copy(src, dst))
        return false;
    else
        qDebug().noquote() << "Update File:" << dst;
    return true;
}

