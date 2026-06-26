#include "messagecenter.h"
#include "configer.h"
#include "dbmanager.h"
#include "hulalogger.h"
#include <QDate>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QSettings>

MessageCenter::MessageCenter(QObject *parent) : QObject(parent)
{
    QString dir = getErrorInfoDir();
    QDir d(dir);
    if (!d.exists())
    {
        d.mkpath(dir);
    }
}

QString MessageCenter::getErrorInfoDir() const
{
    return QGuiApplication::applicationDirPath() + "/ErrorInfo/";
}

QString MessageCenter::getCurrentFileName(const QString &date) const
{
    QString dateStr = date.trimmed();
    if (dateStr.isEmpty())
    {
        dateStr = QDate::currentDate().toString("yyyyMMdd");
    }
    return getErrorInfoDir() + dateStr + ".txt";
}

int MessageCenter::generateNextId(const QString &fileName)
{
    QSettings infoFile(fileName, QSettings::IniFormat);
    return infoFile.childGroups().size() + 1;
}

QList<QVariantMap> MessageCenter::getDatas(const QString &date)
{
    QMutexLocker locker(&m_mutex);

    QString dateStr = date.trimmed();
    if (dateStr.isEmpty())
    {
        dateStr = QDate::currentDate().toString("yyyyMMdd");
    }
    m_currentDate = dateStr;

    QString infoFile = getCurrentFileName(dateStr);
    if (!QFile::exists(infoFile))
    {
        return QList<QVariantMap>();
    }

    QSettings file(infoFile, QSettings::IniFormat);
    QStringList groupList = file.childGroups();
    std::sort(groupList.begin(), groupList.end(), [](const QString &a, const QString &b) { return QString::compare(a, b, Qt::CaseInsensitive) > 0; });

    QList<QVariantMap> datas;
    const QStringList &groupsRef = groupList;
    for (int i = 0; i < groupsRef.size(); ++i)
    {
        const QString &group = groupsRef.at(i);
        file.beginGroup(group);

        QString errorInfo = file.value("ErrorInfo").toString();
        if (errorInfo.isEmpty())
        {
            file.endGroup();
            continue;
        }

        QVariantMap data;
        data["Id"] = group;
        data["StatusCode"] = file.value("StatusCode").toString();
        data["ErrorInfo"] = errorInfo;
        data["UserCode"] = file.value("UserCode").toString();
        data["UserName"] = file.value("UserName").toString();
        data["LogTime"] = file.value("LogTime").toString();
        file.endGroup();
        datas.append(data);
    }

    return datas;
}

int MessageCenter::deleteData(quint64 id)
{
    QMutexLocker locker(&m_mutex);

    if (m_currentDate.isEmpty())
    {
        HulaLogger::instance()->writeLog(QtMsgType::QtWarningMsg, "MessageCenter::deleteData called without prior getDatas", QMessageLogContext());
        return -1;
    }

    QString infoFile = getCurrentFileName(m_currentDate);
    QSettings file(infoFile, QSettings::IniFormat);
    file.remove(QString::number(id));

    return 0;
}

int MessageCenter::deleteAllData()
{
    QMutexLocker locker(&m_mutex);

    if (m_currentDate.isEmpty())
    {
        HulaLogger::instance()->writeLog(QtMsgType::QtWarningMsg, "MessageCenter::deleteAllData called without prior getDatas", QMessageLogContext());
        return -1;
    }

    QString infoFile = getCurrentFileName(m_currentDate);
    if (QFile::exists(infoFile))
    {
        if (!QFile::remove(infoFile))
        {
            HulaLogger::instance()->writeLog(QtMsgType::QtWarningMsg, QString("Failed to remove file: %1").arg(infoFile), QMessageLogContext());
            return -1;
        }
    }

    return 0;
}

bool MessageCenter::hasNewInfo()
{
    QMutexLocker locker(&m_mutex);
    return m_hasNewInfo;
}

void MessageCenter::appendData(const QVariantMap &data)
{
    QMutexLocker locker(&m_mutex);

    QString fileName = getCurrentFileName(QString());
    int id = generateNextId(fileName);
    QString group = QString::number(id);

    QSettings infoFile(fileName, QSettings::IniFormat);
    infoFile.beginGroup(group);
    infoFile.setValue("StatusCode", data["StatusCode"].toString());
    infoFile.setValue("ErrorInfo", data["ErrorInfo"].toString());
    infoFile.setValue("UserCode", data["UserCode"].toString());
    infoFile.setValue("UserName", data["UserName"].toString());
    infoFile.setValue("LogTime", data["LogTime"].toString());
    infoFile.endGroup();

    m_hasNewInfo = true;
}

void MessageCenter::handleMessage(const MessageInfo &msg)
{
    if (static_cast<int>(msg.statusCode) != 0)
    {
        QVariantMap data;
        data["ErrorInfo"] = msg.text;
        data["StatusCode"] = static_cast<int>(msg.statusCode);
        data["UserCode"] = Configer::instance()->userAccount();
        data["UserName"] = Configer::instance()->userName();
        data["LogTime"] = QDateTime::currentDateTime().toString(TIME_MSEC_FMT);
        appendData(data);
    }

    emit messageEmitted(msg);
}

void MessageCenter::handleQmlMessage(const QVariantMap &msg)
{
    MessageInfo info;
    info.text = msg["text"].toString();
    info.promptType = static_cast<PromptType>(msg["promptType"].toInt());
    info.statusCode = static_cast<StatusCode>(msg["statusCode"].toInt());
    handleMessage(info);
}
