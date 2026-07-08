/****************************************************************************
** Qt for cross-platform series
** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
** This work is licensed under the Creative Commons
** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
** Author: Hula
** Web: www.123hula.com
** WeChat: ihula123
** Contact: benny1225@hotmail.com
** Date: 2026.5.25
** Brief: 用户类
** History:
****************************************************************************/
#include "userinfo.h"
#include "dbmanager.h"
#include "rolemanager.h"
#include <QCryptographicHash>
#include <QDate>
#include <QDebug>
#include <QUuid>
#include <QVariant>

void UserInfo::loadPermissions()
{
    m_permissions.clear();
    if (m_roleName.isEmpty())
        return;
    m_permissions = RoleManager::loadPermissions(m_roleName);
}

bool UserInfo::hasModuleAction(const QString &module, const QString &action)
{
    if (!m_permissions.contains(module))
        return false;
    return m_permissions[module].contains(action);
}

bool UserInfo::hasModule(const QString &module)
{
    return m_permissions.contains(module);
}

QList<QVariantMap> UserInfo::getUsers()
{
    QString sql = QString("select * from %1").arg(m_tableName);
    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->getDatas(sql, datas);
    logDebug(status, "UserInfo::appendUser error.");
    return datas;
}

quint64 UserInfo::appendUser(const QVariantMap &data)
{
    QVariantMap newData = data;
    newData.insert("TableName", m_tableName);
    // 确保盐值存在
    if (!newData.contains(m_fieldSalt) || newData[m_fieldSalt].toString().isEmpty())
    {
        newData[m_fieldSalt] = generateSalt();
    }
    // 如果传入明文密码，使用数据库中的盐值进行哈希
    if (newData.contains(m_fieldPassWord) && !newData[m_fieldPassWord].toString().isEmpty())
    {
        newData[m_fieldPassWord] = hashPassword(newData[m_fieldPassWord].toString(), newData[m_fieldSalt].toString());
    }
    quint64 newId = 0;
    StatusCode status = DbManager::instance()->appendData(newData, newId);
    logDebug(status, "UserInfo::appendUser error.");
    if (status == StatusCode::Success)
        return newId;
    else
        return 0;
}

int UserInfo::updateUser(const QVariantMap &data, const QVariantMap &condData)
{
    QVariantMap newData = data;
    newData.insert("TableName", m_tableName);
    QVariantMap srcData = findUser(m_fieldId, condData[m_fieldId].toString());
    if (srcData.isEmpty())
    {
        logDebug(StatusCode::DBRecordNotFound, "UserInfo::updateUser error.");
        return 1;
    }
    newData[m_fieldSalt] = srcData[m_fieldSalt];
    // 如果传入明文密码，使用数据库中的盐值进行哈希
    if (newData.contains(m_fieldPassWord) && !newData[m_fieldPassWord].toString().isEmpty())
    {
        newData[m_fieldPassWord] = hashPassword(newData[m_fieldPassWord].toString(), newData[m_fieldSalt].toString());
    }
    StatusCode status = DbManager::instance()->updateData(newData, condData);
    logDebug(status, "UserInfo::updateUser error.");
    if (status == StatusCode::Success)
        return 0;
    else
        return 1;
}

int UserInfo::deleteUsers(const QStringList &idList)
{
    QString sql = QString("DELETE FROM %1 WHERE Id IN (%2)").arg(m_tableName, idList.join(","));
    StatusCode status = DbManager::instance()->execSql(sql);
    logDebug(status, "UserInfo::updateUser error.");
    if (status == StatusCode::Success)
        return 0;
    else
        return 1;
}

int UserInfo::accountExisted(const QString &account, bool isUpdate)
{
    QString sql;
    if (!isUpdate)
    {
        sql = QString("select %1 from %2").arg(m_fieldId, m_tableName);
    }
    else
    {
        sql = QString("select %1 from %2 where %3 <> %4").arg(m_fieldId, m_tableName, m_fieldAccount, account);
    }

    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->getDatas(sql, datas);
    logDebug(status, "UserInfo::accountExisted error.");
    if (datas.size() > 0)
        return 1;
    else
        return 0;
}

bool UserInfo::login(const QString &account, const QString &pwd)
{
    bool isLogined = false;
    QVariantMap user = findUser(m_fieldAccount, account);
    if (!user.isEmpty())
    {
        QString storedHash = user[m_fieldPassWord].toString();
        QString salt = user[m_fieldSalt].toString();
        if (salt.isEmpty())
        {
            isLogined = (storedHash == pwd);
        }
        else
        {
            QString computedHash = hashPassword(pwd, salt);
            isLogined = (computedHash == storedHash);
        }

        if (isLogined)
        {
            m_userName = user[m_fieldName].toString();
            m_userAccount = account;
            m_roleName = user[m_fieldRoleName].toString();
            emit logined(m_userAccount, m_userName);
        }
    }
    return isLogined;
}

QString UserInfo::findUserName(const QString &account)
{
    QVariantMap user = findUser(m_fieldAccount, account);
    if (!user.isEmpty())
    {
        return user[m_fieldName].toString();
    }
    return "";
}

QVariantMap UserInfo::findUser(const QString &fieldName, const QString &val)
{
    QVariantMap data;
    data.insert(fieldName + "=", QVariant(val));
    data.insert("TableName", m_tableName);
    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->searchDatas(data, datas);
    logDebug(status, "UserInfo::findUser error.");
    if (datas.size() > 0)
        return datas[0];
    else
        return QVariantMap();
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
