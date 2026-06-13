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
#include "userinfo.h"
#include "configer.h"
#include "dbmanager.h"
#include <QCryptographicHash>
#include <QDate>
#include <QDebug>
#include <QUuid>
#include <QVariant>

int UserInfo::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_data.size();
}

int UserInfo::columnCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_headers.size();
}

QVariant UserInfo::data(const QModelIndex &index, int role) const
{
    QMutexLocker locker(&m_dataMutex);

    if (!index.isValid() || index.row() >= m_data.size() || index.column() >= m_headers.size())
    {
        return QVariant();
    }

    if (role == Qt::DisplayRole)
    {
        return m_data[index.row()][index.column()];
    }

    return QVariant();
}

QVariant UserInfo::headerData(int section, Qt::Orientation orientation, int role) const
{
    QMutexLocker locker(&m_dataMutex);

    if (role != Qt::DisplayRole)
    {
        return QVariant();
    }

    if (orientation == Qt::Horizontal)
    {
        if (section >= 0 && section < m_headers.size())
        {
            return m_headers[section];
        }
    }
    else
    {
        return QString("Row %1").arg(section);
    }

    return QVariant();
}

void UserInfo::loadDatas()
{
    QMutexLocker locker(&m_dataMutex);
    beginResetModel();
    m_headers.clear();
    m_data.clear();

    QString sql = "SELECT * FROM UserInfo";
    QSqlQuery query = DbManager::instance()->newQuery();
    if (!query.exec(sql))
    {
        QString error = query.lastError().text();
        qWarning() << "Query failed:" << error;
        emit messageEmitted(MessageInfo(error, StatusCode::DbExecuteFailed));
        endResetModel();
        return;
    }

    QSqlRecord record = query.record();
    int columnCount = record.count();

    for (int i = 0; i < columnCount; ++i)
    {
        m_headers << record.fieldName(i);
    }

    while (query.next())
    {
        QList<QVariant> row;
        for (int i = 0; i < columnCount; ++i)
        {
            row << query.value(i);
        }
        m_data << row;
    }
    endResetModel();
}

QJsonObject UserInfo::find(const QString &value, const QString &key)
{
    QJsonObject data = {};
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare(QString("select * from UserInfo where %1 = :value").arg(key));
    qry.bindValue(":value", value);
    if (!qry.exec())
    {
        qDebug() << qry.lastError().text();
        emit messageEmitted(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return data;
    }
    QList<QJsonObject> datas;
    DbManager::instance()->getDbDatas(qry, datas);
    if (datas.count() == 0)
        return data;

    data = datas[0];
    return data;
}

QList<QVariantMap> UserInfo::getDatas()
{
    QString sql = "select * from UserInfo";
    QList<QVariantMap> datas;
    if (DbManager::instance()->getDatas(sql, datas) != StatusCode::Success)
        sendDbMessage();
    return datas;
}

quint64 UserInfo::appendData(QJsonObject data)
{
    // 确保盐值存在
    if (!data.contains("Salt") || data["Salt"].toString().isEmpty())
    {
        data["Salt"] = generateSalt();
    }
    // 如果传入明文密码，使用数据库中的盐值进行哈希
    if (data.contains("Password") && !data["Password"].toString().isEmpty())
    {
        data["Password"] = hashPassword(data["Password"].toString(), data["Salt"].toString());
    }

    QList<QJsonObject> datas;
    datas.append(data);
    int ret = DbManager::instance()->appendDatas(datas, "UserInfo");
    if (ret > 0)
        return 0;

    return datas[0].value("Id").toString().toULongLong();
}

int UserInfo::updateData(QJsonObject data)
{
    // 如果传入明文密码，使用数据库中的盐值进行哈希
    if (data.contains("Password") && !data["Password"].toString().isEmpty())
    {
        // 确保盐值存在
        if (!data.contains("Salt") || data["Salt"].toString().isEmpty())
        {
            data["Salt"] = generateSalt();
        }
        data["Password"] = hashPassword(data["Password"].toString(), data["Salt"].toString());
    }

    QStringList whereFileds = {};
    whereFileds.append("Id");
    QList<QJsonObject> datas = {};
    datas.append(data);
    int ret = DbManager::instance()->updateDatas(datas, whereFileds, "UserInfo");
    return ret;
}

int UserInfo::deleteData(const QString &id)
{
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare("DELETE FROM UserInfo WHERE Id = :id");
    qry.bindValue(":id", id);
    if (!qry.exec())
    {
        qDebug() << qry.lastError().text();
        emit messageEmitted(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return 1;
    }
    return 0;
}

int UserInfo::accountExisted(const QString &account, const QString &id)
{
    QSqlQuery qry = DbManager::instance()->newQuery();
    QString sql;
    if (id == "")
    {
        qry.prepare("select Name from UserInfo where Account = :account");
    }
    else
    {
        qry.prepare("select Name from UserInfo where Account = :account and Id <> :id");
        qry.bindValue(":id", id);
    }
    qry.bindValue(":account", account);
    if (!qry.exec())
    {
        qDebug() << qry.lastError().text();
        emit messageEmitted(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return 0;
    }
    QList<QJsonObject> datas;
    DbManager::instance()->getDbDatas(qry, datas);
    if (datas.size() > 0)
        return 1;
    else
        return 0;
}

int UserInfo::checkPassword(const QString &account, const QString &pwd)
{
    QJsonObject user = findUserByAccount(account);
    if (user.isEmpty())
    {
        return 1; // 用户不存在
    }
    QString storedHash = user["Password"].toString();
    QString salt = user["Salt"].toString();
    if (verifyPassword(pwd, storedHash, salt))
    {
        return 0; // 密码正确
    }
    return 1; // 密码错误
}

int UserInfo::login(const QString &account, const QString &pwd)
{
    bool isLogined = false;
    QJsonObject user = findUserByAccount(account);
    if (!user.isEmpty())
    {
        QString storedHash = user["Password"].toString();
        QString salt = user["Salt"].toString();
        if (verifyPassword(pwd, storedHash, salt))
        {
            isLogined = true;
            QString userName = user["Name"].toString();
            Configer::instance()->setUserAccount(account);
            Configer::instance()->setUserName(userName);
            emit logined(account, userName);
        }
    }
    return isLogined;
}

QString UserInfo::getUserName(const QString &account)
{
    QJsonObject user = findUserByAccount(account);
    if (!user.isEmpty())
    {
        return user["Name"].toString();
    }
    return "";
}

// ========== 私有辅助方法 ==========

QJsonObject UserInfo::findUserByAccount(const QString &account)
{
    QJsonObject data;
    QSqlQuery qry = DbManager::instance()->newQuery();
    qry.prepare("select * from UserInfo where Account = :account");
    qry.bindValue(":account", account);
    if (!qry.exec())
    {
        qDebug() << qry.lastError().text();
        emit messageEmitted(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return data;
    }
    QList<QJsonObject> datas;
    DbManager::instance()->getDbDatas(qry, datas);
    if (datas.size() > 0)
    {
        data = datas[0];
    }
    return data;
}

QString UserInfo::hashPassword(const QString &password, const QString &salt)
{
    // 使用数据库中的盐值进行哈希
    QByteArray saltBytes = salt.toUtf8();
    QByteArray hash = QCryptographicHash::hash(saltBytes + password.toUtf8(), QCryptographicHash::Sha256);
    // 迭代 10000 次增强安全性
    for (int i = 0; i < 10000; ++i)
    {
        hash = QCryptographicHash::hash(hash + password.toUtf8(), QCryptographicHash::Sha256);
    }
    return QString::fromUtf8(hash.toBase64());
}

void UserInfo::sendDbMessage()
{
    MessageInfo msg;
    if (DbManager::instance()->takeLastError(msg))
    {
        qCritical() << QString("Error code: %1, error information:%2").arg(static_cast<int>(msg.statusCode)).arg(msg.text);
        emit messageEmitted(msg);
    }
}

bool UserInfo::verifyPassword(const QString &password, const QString &storedHash, const QString &salt)
{
    QString computedHash = hashPassword(password, salt);
    return computedHash == storedHash;
}

QString UserInfo::generateSalt()
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}
