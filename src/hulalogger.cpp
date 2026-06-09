#include "hulalogger.h"
#include <QString>
#include <QLoggingCategory>
#include <QIODevice>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QDateTime>
#include <QMutex>
#include <QMutexLocker>
#include <QGuiApplication>
#ifdef QT_DEBUG
#include <iostream>
#endif

QString logDir;
QString logFileName;
QMutex mutex;
QFile file;
QTextStream textStream;

static LogLevel LogType = Debug; //日志等级初始化设置

void outputMessage(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(context)

    QString text;
    switch(type)
    {
    case QtDebugMsg:
        text = QString("[Debug]");
        break;
    case QtInfoMsg:
        text = QString("[Info]");
        break;
    case QtWarningMsg:
        text = QString("[Warning]");
        break;
    case QtCriticalMsg:
        text = QString("[Critical]");
        break;
    case QtFatalMsg:
        text = QString("[Fatal]");
    }
#ifdef QT_DEBUG
    text.append(QString(" [%1] ").arg(QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss")));
    QString str = "[" + QString(context.file).trimmed() + " Line: " + QString::number(context.line) + "]";
    text.append(str);
    //text.append(QString(" [%1: Line: %2] ").arg(QString(context.file).trimmed(), context.line));
    text.append(QString(" [Function: %1] ").arg(QString(context.function)));
#endif

    QMutexLocker locker(&mutex);
    if (file.fileName() != logFileName || !file.isOpen()) {
        if (file.isOpen())
            file.close();
        file.setFileName(logFileName);
        file.open(QIODevice::Text | QIODevice::WriteOnly | QIODevice::Append);
        textStream.setDevice(&file);
    }
#ifdef QT_DEBUG
    std::cout << text.toStdString().c_str() << std::endl << msg.toStdString().data() << std::endl;
    textStream << text << Qt::endl << msg << Qt::endl;
#else
    QString strTime = "[" + QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz") + "]";
    QString info = "";
    QString tmp = msg;
    tmp = tmp.replace("\"", "");
    QString tmp1 = tmp.left(23);
    QDateTime date1 = QDateTime::fromString(tmp1,"yyyy-MM-dd hh:mm:ss:zzz");
    QString tmp2 = tmp.left(19);
    QDateTime date2 = QDateTime::fromString(tmp2,"yyyy-MM-dd hh:mm:ss");
    if (date1.isValid())
        info = " " + tmp.right(tmp.length() - 23).trimmed();
    else if (date2.isValid())
        info = " " + tmp.right(tmp.length() - 19).trimmed();
    else
        info = " " + tmp.trimmed();
    textStream << strTime << info << Qt::endl;
#endif
    textStream.flush();
}

//初始化读取配置文件
void setLogType(int type)
{
    LogType = static_cast<LogLevel>(type);
}


bool findFileForDelete(const QString & path)
{
    QDir dir(path);
    if (!dir.exists())
        return false;

    dir.setFilter(QDir::Dirs|QDir::Files);
    dir.setSorting(QDir::DirsFirst);
    QFileInfoList list = dir.entryInfoList();

    for (int i = 0; i < list.size(); ++i) {
        QFileInfo fileInfo = list.at(i);
        if ((fileInfo.fileName() == ".") || (fileInfo.fileName() == ".."))
            continue;

        if (fileInfo.isDir())
        {
            if (!findFileForDelete(fileInfo.filePath()))
                return false;
        }
        else
        {
            //如果是文件，判断文件日期 目前默认是30天。
            QDateTime delDateTime = QDateTime::currentDateTime().addDays(-30);
            qint64 second = delDateTime.secsTo(fileInfo.birthTime());
            if (second < 0)
            {
                fileInfo.dir().remove(fileInfo.fileName());
            }
        }
    }
    return true;
}

void logInit(int type)
{
    setLogType(type);
    logDir  = QGuiApplication::applicationDirPath() +"/Log/";

    QDir dir(logDir);
    if(!dir.exists())
        dir.mkdir(logDir);

    logFileName = logDir + QDate::currentDate().toString("yyyyMMdd")+".log";
    QMutexLocker locker(&mutex);

    /*以下这段代码的含义是初始化时检查日志文件是否存在一个月之前的日志，如果存在删除之*/
    findFileForDelete(logDir);
    /*安装上述自定义函数*/
    qInstallMessageHandler(outputMessage);
}


