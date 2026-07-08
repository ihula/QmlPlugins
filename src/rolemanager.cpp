#include "rolemanager.h"
#include "dbmanager.h"
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QVariantMap>

QJsonArray RoleManager::getModuleDefines()
{
    QJsonArray result;
    auto defs = m_moduleDefines;
    for (auto it = defs.constBegin(); it != defs.constEnd(); ++it)
    {
        QJsonObject obj;
        obj["module"] = it.key();
        obj["actions"] = QJsonArray::fromStringList(it.value());
        result.append(obj);
    }
    return result;
}

QList<QVariantMap> RoleManager::getRoles()
{
    QString sql = QString("select * from %1").arg(m_tableName);
    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->getDatas(sql, datas);
    logDebug(status, "RoleManager::getRoles error.");
    return datas;
}

QVariantMap RoleManager::findRole(const QVariantMap &data)
{
    QVariantMap condData = data;
    condData.insert("TableName", m_tableName);
    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->searchDatas(condData, datas);
    logDebug(status, "RoleManager::findRole error.");
    if (datas.size() > 0)
        return datas[0];
    else
        return QVariantMap();
}

int RoleManager::deleteRoles(const QStringList &idlist)
{
    if (idlist.size() == 0)
        return 0;

    QString sql = QString("DELETE FROM Roles WHERE Id IN (%1)").arg(idlist.join(","));
    StatusCode status = DbManager::instance()->execSql(sql);
    logDebug(status, "RoleManager::appendRole error.");
    return static_cast<int>(status);
}

quint64 RoleManager::appendRole(const QVariantMap &data)
{
    QVariantMap newData = data;
    newData.insert("TableName", m_tableName);
    quint64 newId = 0;
    StatusCode status = DbManager::instance()->appendData(newData, newId);
    logDebug(status, "RoleManager::appendRole error.");
    if (status == StatusCode::Success)
        return newId;
    else
        return 0;
}

int RoleManager::roleNameExisted(const QString &roleName, bool isUpdate)
{
    QString sql;
    if (!isUpdate)
    {
        sql = QString("select %1 from %2").arg(m_fieldId, m_tableName);
    }
    else
    {
        sql = QString("select %1 from %2 where %3 <> %4").arg(m_fieldId, m_tableName, m_fieldName, roleName);
    }

    QList<QVariantMap> datas;
    StatusCode status = DbManager::instance()->getDatas(sql, datas);
    logDebug(status, "UserInfo::accountExisted error.");
    if (datas.size() > 0)
        return 1;
    else
        return 0;
}

int RoleManager::updateRole(const QVariantMap &data, const QVariantMap &condData)
{
    QVariantMap newData = data;
    newData.insert("TableName", m_tableName);
    StatusCode status = DbManager::instance()->updateData(newData, condData);
    logDebug(status, "RoleManager::updateRole error.");
    if (status == StatusCode::Success)
        return 0;
    else
        return 1;
}

QMap<QString, QSet<QString>> RoleManager::loadPermissions(const QString &roleName)
{
    QMap<QString, QSet<QString>> perms = {};

    QList<QVariantMap> results;
    QString sql = QString("SELECT permissions FROM %1 WHERE Name=%2").arg(m_tableName, roleName);

    StatusCode status = DbManager::instance()->getDatas(sql, results);
    if (status != StatusCode::Success || results.isEmpty())
    {
        qWarning() << "Failed to load permissions for role:" << roleName;
        return perms;
    }

    QString permissionsJson = results.first()["permissions"].toString();
    QJsonDocument doc = QJsonDocument::fromJson(permissionsJson.toUtf8());

    if (doc.isNull() || !doc.isObject())
    {
        qWarning() << "Invalid permissions JSON for role:" << roleName;
        return perms;
    }

    QJsonObject permissions = doc.object();
    for (auto it = permissions.begin(); it != permissions.end(); ++it)
    {
        QString module = it.key();
        QJsonValue val = it.value();

        if (val.isArray())
        {
            // 格式: {"customers": ["read","write","delete"]}
            QSet<QString> actions;
            const QJsonArray arr = val.toArray();
            for (const auto a : arr)
            {
                actions.insert(a.toString());
            }
            perms[module] = actions;
        }
    }
    return perms;
}
