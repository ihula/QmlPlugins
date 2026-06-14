/****************************************************************************
** Qt for cross-platform series
** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
** This work is licensed under the Creative Commons
** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
** Author: Hula
** Web: www.123hula.com
** WeChat: ihula123
** Contact: benny1225@hotmail.com
** Date: 2018.4.25
** Brief: 病人信息类
** History:
****************************************************************************/
#include "patients.h"
#include <QDate>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSqlError>
#include <QSqlQuery>
#ifdef USE_QXLSX
#include "hulaxlsx.h"
#endif
#include "dbmanager.h"
#include "translater.h"

Patients::Patients(QObject *parent) : QObject(parent), m_sender(this)
{
    connect(this, &Patients::messageEmitted, &m_sender, &BaseMsgSender::messageEmitted);
}

QJsonObject Patients::findPatient(const QString &value, const QString &key)
{
    QJsonObject data = {};
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare(QString("select * from PatientInfo where %1 = :value").arg(key));
    qry.bindValue(":value", value);
    if (!qry.exec())
    {
        MessageInfo msg = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
        qDebug() << msg.text;
        emit messageEmitted(msg);
        return data;
    }
    QList<QJsonObject> datas;
    DbManager::instance()->getDbDatas(qry, datas);
    if (datas.count() == 0)
        return data;

    data = datas[0];
    return data;
}

QList<QJsonObject> Patients::findPatients(const QJsonObject &data)
{
    QJsonObject queryData = data;
    queryData.insert("TableName", "PatientInfo");
    QList<QJsonObject> datas = DbManager::instance()->findDatas(queryData);
    return datas;
}

QList<QVariantMap> Patients::searchDatas(const QVariantMap &data)
{
    MessageInfo msg;
    msg.promptType = PromptType::Error;
    msg.statusCode = StatusCode::AuthenticationFailed;
    msg.text = "AuthenticationFailed";
    messageEmitted(msg);
    QVariantMap cond = data;
    cond.insert("TableName", "PatientInfo");
    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->searchDatas(cond, datas);
    if (status != StatusCode::Success)
        sendDbMessage();

    return datas;
}

QList<QVariantMap> Patients::getAllPatients()
{
    QString sql = "select * from PatientInfo";
    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->getDatas(sql, datas);
    if (status != StatusCode::Success)
        sendDbMessage();
    return datas;
}

quint64 Patients::appendPatient(const QJsonObject &data)
{
    QList<QJsonObject> datas;
    datas.append(data);
    int ret = DbManager::instance()->appendDatas(datas, "PatientInfo");
    if (ret > 0)
        return 0;

    return datas[0].value("Id").toString().toULongLong();
}

int Patients::updatePatient(const QJsonObject &data)
{
    QStringList whereFileds = {};
    whereFileds.append("Id");
    QList<QJsonObject> datas = {};
    datas.append(data);
    int ret = DbManager::instance()->updateDatas(datas, whereFileds, "PatientInfo");
    return ret;
}

int Patients::deletePatients(const QString &pids)
{
    if (pids.size() == 0)
        return 0;

    // 将逗号分隔的 ID 列表拆分，逐条参数化删除
    QStringList idList = pids.split(",", Qt::SkipEmptyParts);
    if (idList.isEmpty())
        return 0;

    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare("DELETE FROM PatientInfo WHERE Id = :id");
    const auto idListConst = idList;
    for (const QString &id : idListConst)
    {
        qry.bindValue(":id", id.trimmed());
        if (!qry.exec())
        {
            MessageInfo msg = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
            qDebug() << msg.text;
            emit messageEmitted(msg);
            return 1;
        }
    }
    return 0;
}

int Patients::deleteDir(const QString &path)
{
    QDir dir(path);

    if (dir.exists())
    {
        if (dir.removeRecursively())
        {
            return 0;
        }
        else
        {
            return 1;
        }
    }
    else
    {
        return 0;
    }
}

QString Patients::getNextTestId()
{
    // QString receiptDate = QDate::currentDate().toString("yyyy-MM-dd");
    QString sql = "SELECT MAX(CAST(TestId AS INTEGER)) AS MaxTestId FROM PatientInfo";
    // Where ReceiptDate='" + receiptDate + "'";
    QList<QVariantMap> datas;
    DbManager::instance()->getDatas(sql, datas);
    if (datas.length() == 0)
        return 0;

    int next = datas[0].value("MaxTestId").toInt() + 1;
    QString ret = QString("%1").arg(next, 8, 10, QChar('0'));
    return ret;
}

QJsonObject Patients::findReport(const QString &value, const QString &key)
{
    QJsonObject data = {};
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare(QString("select * from Report where %1 = :value").arg(key));
    qry.bindValue(":value", value);
    if (!qry.exec())
    {
        MessageInfo msg = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
        qDebug() << msg.text;
        emit messageEmitted(msg);
        return data;
    }
    QList<QJsonObject> datas;
    DbManager::instance()->getDbDatas(qry, datas);
    if (datas.count() == 0)
        return data;

    data = datas[0];
    return data;
}

quint64 Patients::appendReport(const QJsonObject &data)
{
    QList<QJsonObject> datas;
    datas.append(data);
    int ret = DbManager::instance()->appendDatas(datas, "Report");
    if (ret > 0)
        return 0;

    return datas[0].value("Id").toString().toULongLong();
}

int Patients::updateReport(const QJsonObject &data)
{
    QStringList whereFileds = {};
    whereFileds.append("Id");
    QList<QJsonObject> datas = {};
    datas.append(data);
    int ret = DbManager::instance()->updateDatas(datas, whereFileds, "Report");
    return ret;
}

int Patients::deleteReport(const QString &rid)
{
    if (rid == "")
        return 0;

    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare("DELETE FROM Report WHERE Id = :id");
    qry.bindValue(":id", rid);
    if (!qry.exec())
    {
        MessageInfo msg = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
        qDebug() << msg.text;
        emit messageEmitted(msg);
        return 1;
    }
    return 0;
}

int Patients::backupRecords(const QString &fileName, const QList<QJsonObject> &datas)
{
    QJsonArray dbs;
    for (int i = 0; i < datas.size(); i++)
    {
        QJsonArray dataInfo;
        dataInfo.append(datas[i]);
        int rid = datas[i]["ReportId"].toInt();
        if (rid <= 0)
        {
            dbs.append(dataInfo);
            continue;
        }
        QJsonObject repData = findReport(QString::number(rid));
        if (!repData.isEmpty())
            dataInfo.append(repData);
        dbs.append(dataInfo);
    }
    QFile file(fileName);
    if (!file.open(QIODevice::WriteOnly))
    {
        qDebug() << "File open error";
        return 1;
    }
    else
    {
        // qDebug() << "File open!";
    }
    QJsonDocument jsonDoc;
    jsonDoc.setArray(dbs);
    file.write(jsonDoc.toJson());
    file.close();
    return 0;
}

int Patients::recoverRecords(const QString &fileName)
{
    QFile loadFile(fileName);
    if (!loadFile.exists())
    {
        MessageInfo msg = MessageInfo("recoverDb: " + fileName + " file dont exist.", StatusCode::FileNotFound);
        qDebug() << msg.text;
        emit messageEmitted(msg);
        return 1;
    }
    if (!loadFile.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        MessageInfo msg = MessageInfo("recoverDb: " + tr("Search.LoadFileInvalid") + ": " + fileName, StatusCode::FileReadFailed);
        qDebug() << msg.text;
        emit messageEmitted(msg);
        return 1;
    }
    QByteArray array = loadFile.readAll();
    loadFile.close();
    QJsonParseError jsonParseError;
    QJsonDocument jsonDoc(QJsonDocument::fromJson(array, &jsonParseError));
    if (QJsonParseError::NoError != jsonParseError.error)
    {
        QString str = tr("Search.JsonParseError") + jsonParseError.errorString();
        qDebug() << str;
        emit messageEmitted(MessageInfo(str, StatusCode::InvalidFormat));
        return 1;
    }
    QJsonArray dbs = jsonDoc.array();
    for (int i = 0; i < dbs.size(); i++)
    {
        qint64 rid = 0;
        QJsonArray infos = dbs[i].toArray();
        if (infos.size() == 0)
            continue;

        QJsonObject patData = infos[0].toObject();
        quint64 id = patData["Id"].toDouble(-1);
        if (id < 1)
            continue;

        QJsonObject tmpData = findPatient(QString::number(id));
        if (!tmpData.isEmpty())
            continue;

        if (infos.size() > 1)
        {
            QJsonObject repData = infos[1].toObject();
            rid = appendReport(repData);
            if (rid == 0)
            {
                MessageInfo msg = MessageInfo(tr("Search.RecoverDbInvalid"), StatusCode::DbRecoverFailed);
                qDebug() << msg.text;
                emit messageEmitted(msg);
                return 1;
            }
        }

        if (rid > 0)
            patData["ReportId"] = rid;
        id = appendPatient(patData);
        if (id == 0)
        {
            MessageInfo msg = MessageInfo(tr("Search.RecoverDbInvalid"), StatusCode::DbRecoverFailed);
            qDebug() << msg.text;
            emit messageEmitted(msg);
            return 1;
        }
    }
    return 0;
}

int Patients::exportXlsx(const QString &fileName, const QList<QJsonObject> &datas, const QList<QString> &fields)
{
#ifndef USE_QXLSX
    Q_UNUSED(fileName)
    Q_UNUSED(datas)
    Q_UNUSED(fields)
#endif
#ifdef USE_QXLSX
    QString col = "";
    char upper;
    HulaXlsx hulaXlsx;
    hulaXlsx.open(fileName);
    for (int i = 0; i < fields.size(); i++)
    {
        QString langKey = "Home." + fields[i];
        QString label = Translater::instance()->trans(langKey);
        if (i < 26)
        {
            upper = 'A' + i;
            col = QString(upper);
        }
        else
        {
            upper = 'A' + i - 26;
            col = "A" + QString(upper);
        }
        hulaXlsx.write(col + "1", label);
    }

    for (int i = 0; i < datas.size(); i++)
    {
        QString strRow = QString::number(i + 2);
        QList<QString> keys = fields;
        // hulaXlsx.addSheet(QString::number(datas[i]["Id"].toInt()));
        for (int j = 0; j < keys.size(); j++)
        {
            if (j < 26)
            {
                upper = 'A' + j;
                col = QString(upper);
            }
            else
            {
                upper = 'A' + j - 26;
                col = "A" + QString(upper);
            }
            if (keys[j] == "Menopause")
            {
                int val = datas[i][keys[j]].toInt();
                if (val == 1)
                {
                    hulaXlsx.write(col + strRow, "是");
                }
                else if (val == 2)
                {
                    hulaXlsx.write(col + strRow, "否");
                }
            }
            else
            {
                hulaXlsx.write(col + strRow, datas[i][keys[j]].toString());
            }
        }
    }
    hulaXlsx.save();
#endif
    return 0;
}

void Patients::sendDbMessage()
{
    MessageInfo msg;
    if (DbManager::instance()->takeLastError(msg))
    {
        qCritical() << QString("Error code: %1, error information:%2").arg(static_cast<int>(msg.statusCode)).arg(msg.text);
        emit messageEmitted(msg);
    }
}
