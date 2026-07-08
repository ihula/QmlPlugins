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
** Brief: 数据字典类
** History:
****************************************************************************/
#include "datadict.h"
#include "dbmanager.h"
#include "messagecenter.h"
#include <QDebug>
#include <QSqlError>
#include <QSqlQuery>
#include <QVariant>

DataDict::DataDict(QObject *parent) : QObject(parent)
{
    MessageCenter *msgCenter = MessageCenter::instance();
    connect(this, &DataDict::messageEmitted, msgCenter, &MessageCenter::handleMessage);
}

QList<QJsonObject> DataDict::getDatas(DictType type)
{
    QList<QJsonObject> datas = {};
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare("select * from DataDict where Type = :type");
    qry.bindValue(":type", static_cast<int>(type));
    if (!qry.exec())
    {
        m_lastError = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
        emit messageEmitted(m_lastError);
        return datas;
    }
    DbManager::instance()->getDbDatas(qry, datas);
    return datas;
}

QStringList DataDict::getValues(DictType type)
{
    QStringList values = {};
    QList<QJsonObject> datas = getDatas(type);
    for (int i = 0; i < datas.length(); i++)
        values.append(datas[i].value("Value").toString());

    return values;
}

quint64 DataDict::appendData(const QJsonObject &data)
{
    QList<QJsonObject> datas;
    datas.append(data);
    int ret = DbManager::instance()->appendDatas(datas, "DataDict");
    if (ret > 0)
        return 0;

    return datas[0].value("Id").toString().toULongLong();
}

int DataDict::updateData(const QJsonObject &data)
{
    QStringList whereFileds = {};
    whereFileds.append("Id");
    QList<QJsonObject> datas = {};
    datas.append(data);
    int ret = DbManager::instance()->updateDatas(datas, whereFileds, "DataDict");
    return ret;
}

int DataDict::deleteData(quint64 id)
{
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare("DELETE from DataDict where Id = :id");
    qry.bindValue(":id", id);
    if (!qry.exec())
    {
        m_lastError = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
        emit messageEmitted(m_lastError);
        return 1;
    }
    return 0;
}

MessageInfo DataDict::lastError()
{
    return m_lastError;
}

int DataDict::codeExisted(quint64 id, const QString &code)
{
    QSqlQuery qry = DbManager::instance()->newQuery();
    if (id == 0)
    {
        qry.prepare("select Name from DataDict where Code = :code");
    }
    else
    {
        qry.prepare("select Name from DataDict where Code = :code and Id <> :id");
        qry.bindValue(":id", id);
    }
    qry.bindValue(":code", code);
    if (!qry.exec())
    {
        m_lastError = MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed);
        emit messageEmitted(m_lastError);
        return 1;
    }
    QList<QJsonObject> datas;
    DbManager::instance()->getDbDatas(qry, datas);

    if (datas.length() > 0)
        return 0;
    else
        return 1;
}
