#include "messagecenter.h"
#include "configer.h"
#include "dbmanager.h"
#include <QDate>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonObject>
#include <QSqlError>
#include <QSqlQuery>

MessageCenter::MessageCenter(QObject *parent) : QObject(parent)
{
    // 记录类的方法名,用于权限管理
    /*
    QString className = this->objectName();
    QString cls = GET_CLASS_NAME(MessageCenter);
    QString funcName = GET_FUNC_NAME(MessageCenter::getDatas);

    qDebug().noquote() << 12 << className  << 13 << cls << 14 << funcName;
    */
}

QList<QVariantMap> MessageCenter::getDatas(QString date)
{
    QMutexLocker locker(&m_fileMutex);
    m_currFileName = date.trimmed();
    if (m_currFileName == "")
        m_currFileName = QDate::currentDate().toString("yyyyMMdd");
    QString infofile = "ErrorInfo/" + m_currFileName + ".txt";
    QSettings file(infofile, QSettings::IniFormat);
    QStringList groupList = file.childGroups();
    std::sort(groupList.begin(), groupList.end(), [](const QString &a, const QString &b) { return QString::compare(a, b, Qt::CaseInsensitive) > 0; });

    QList<QVariantMap> datas;
    for (int i = 0; i < groupList.size(); i++)
    {
        file.beginGroup(groupList[i]);
        QString str = file.value("ErrorInfo").toString();
        if (str.isEmpty())
            continue;

        QVariantMap data = {};
        data["Id"] = groupList[i];
        data["StatusCode"] = file.value("StatusCode").toString();
        data["ErrorInfo"] = file.value("ErrorInfo").toString();
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
    QMutexLocker locker(&m_fileMutex);
    QString infofile = "ErrorInfo/" + m_currFileName + ".txt";
    QSettings file(infofile, QSettings::IniFormat);
    file.remove(QString::number(id));
    return 0;
}

int MessageCenter::deleteAllData()
{
    QMutexLocker locker(&m_fileMutex);
    QString infofile = "ErrorInfo/" + m_currFileName + ".txt";
    QFile::remove(infofile);
    return 0;
}

bool MessageCenter::hasNewInfo()
{
    return m_hasNewInfo;
}

void MessageCenter::appendData(QVariantMap data)
{
    QMutexLocker locker(&m_fileMutex);
    QString fileName = "ErrorInfo/" + QDate::currentDate().toString("yyyyMMdd") + ".txt";
    QSettings infoFile(fileName, QSettings::IniFormat);
    int id = infoFile.childGroups().size();

    id++;
    QString group = QString::number(id);
    infoFile.beginGroup(group);
    infoFile.setValue("StatusCode", data["StatusCode"].toString());
    infoFile.setValue("ErrorInfo", data["ErrorInfo"].toString());
    infoFile.setValue("UserCode", data["UserCode"].toString());
    infoFile.setValue("UserName", data["UserName"].toString());
    infoFile.setValue("LogTime", data["LogTime"].toString());
    m_hasNewInfo = true;
}

void MessageCenter::handleMessage(const MessageInfo &msg)
{
    // 错误码非成功时保存到文件
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
