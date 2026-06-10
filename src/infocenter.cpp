#include "configer.h"
#include "infocenter.h"
#include "dbmanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDir>
#include <QDate>
#include <QFile>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>
#include <QGuiApplication>


InfoCenter::InfoCenter(QObject *parent) : QObject(parent)
{
    // 记录类的方法名,用于权限管理
    /*
    QString className = this->objectName();
    QString cls = GET_CLASS_NAME(InfoCenter);
    QString funcName = GET_FUNC_NAME(InfoCenter::getDatas);

    qDebug().noquote() << 12 << className  << 13 << cls << 14 << funcName;
    */
}

QJsonArray InfoCenter::getDatas(QString date)
{
    QMutexLocker locker(&m_fileMutex);
    m_currFileName = date.trimmed();
    if (m_currFileName == "")
        m_currFileName = QDate::currentDate().toString("yyyyMMdd");
    QString infofile = "ErrorInfo/" + m_currFileName + ".txt";
    QSettings file(infofile, QSettings::IniFormat);
    QStringList groupList = file.childGroups();
    std::sort(groupList.begin(), groupList.end(), [](const QString& a, const QString& b){
        return QString::compare(a, b, Qt::CaseInsensitive) > 0; });

    QJsonArray datas;
    for (int i = 0; i < groupList.size(); i++)
    {
        file.beginGroup(groupList[i]);
        QString str = file.value("ErrorInfo").toString();
        if (str.isEmpty())
            continue;

        QJsonObject data = {};
        data["Id"] = groupList[i];
        data["ErrorNum"] = file.value("ErrorNum").toString();
        data["ErrorInfo"] = file.value("ErrorInfo").toString();
        data["UserCode"] = file.value("UserCode").toString();
        data["UserName"] = file.value("UserName").toString();
        data["LogTime"] = file.value("LogTime").toString();
        file.endGroup();
        datas.append(data);
    }

    return datas;
}

int InfoCenter::deleteData(quint64 id)
{
    QMutexLocker locker(&m_fileMutex);
    QString infofile = "ErrorInfo/" + m_currFileName + ".txt";
    QSettings file(infofile, QSettings::IniFormat);
    file.remove(QString::number(id));
    return 0;
}

int InfoCenter::deleteAllData()
{
    QMutexLocker locker(&m_fileMutex);
    QString infofile = "ErrorInfo/" + m_currFileName + ".txt";
    QFile::remove(infofile);
    return 0;
}

bool InfoCenter::hasNewInfo()
{
    return m_hasNewInfo;
}

void InfoCenter::appendData(QJsonObject data)
{
    QMutexLocker locker(&m_fileMutex);
    QString fileName = "ErrorInfo/" + QDate::currentDate().toString("yyyyMMdd") + ".txt";
    QSettings infoFile(fileName, QSettings::IniFormat);
    int id = infoFile.childGroups().size();

    id++;
    QString group = QString::number(id);
    infoFile.beginGroup(group);
    infoFile.setValue("ErrorNum", data["ErrorNum"].toString());
    infoFile.setValue("ErrorInfo", data["ErrorInfo"].toString());
    infoFile.setValue("UserCode", data["UserCode"].toString());
    infoFile.setValue("UserName", data["UserName"].toString());
    infoFile.setValue("LogTime", data["LogTime"].toString());
    m_hasNewInfo = true;
}

void InfoCenter::receiveMessage(QString info, Enums::InfoType type, Enums::ErrorCode code)
{
    // 错误码非成功时保存到文件
    if (code != Enums::ErrorCode::Success)
    {
        QJsonObject data;
        data["ErrorInfo"] = info;
        data["ErrorCode"] = static_cast<int>(code);
        data["InfoType"] = static_cast<int>(type);
        data["UserCode"] = Configer::instance()->userAccount();
        data["UserName"] = Configer::instance()->userName();
        data["LogTime"] = QDateTime::currentDateTime().toString(TIME_MSEC_FMT);
        appendData(data);
    }

    emit messageEmitted(info, type, code);
}

// template<typename SenderType>
// void InfoCenter::connectRecv(SenderType *sender, Qt::ConnectionType type)
// {
//     if (!sender) {
//         return;
//     }

//     // 使用函数指针语法连接信号和槽，提供编译时类型检查
//     QObject::connect(sender,
//                      &SenderType::sendInfo,
//                      InfoCenter::instance(),
//                      &InfoCenter::receiveInfo,
//                      type);
// }
