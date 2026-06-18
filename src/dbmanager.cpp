#include "dbmanager.h"
#include "configer.h"
#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QPluginLoader>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlField>
#include <QSqlRecord>
#include <QThread>

// ========== TransactionGuard 实现 ==========

TransactionGuard::TransactionGuard(QSqlDatabase *db) : m_db(db)
{
    if (m_db)
    {
        m_db->transaction();
    }
}

TransactionGuard::~TransactionGuard()
{
    if (m_db && !m_committed)
    {
        m_db->rollback();
    }
}

void TransactionGuard::commit()
{
    if (m_db)
    {
        m_db->commit();
        m_committed = true;
    }
}

// ========== DbManager 实现 ==========

DbManager::DbManager(QObject *parent) : QObject(parent)
{
}

DbManager::~DbManager()
{
}

StatusCode DbManager::connect(const QString &dbname)
{
    if (dbname.isEmpty())
    {
        setLastError(MessageInfo("Database name is empty", StatusCode::InvalidParameter));
        return StatusCode::InvalidParameter;
    }

    QMutexLocker locker(&m_dbMutex);
    m_dbName = dbname;
    QString threadId = QString("%1").arg(quintptr(QThread::currentThreadId()));

    // 使用线程ID作为连接名称，避免冲突
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", threadId);
    db.setDatabaseName(m_dbName);

    if (!db.open())
    {
        QString err = QString("Failed to open database: %1").arg(db.lastError().text());
        setLastError(MessageInfo(err, StatusCode::DbOpenFailed));
        return StatusCode::DbOpenFailed;
    }
    m_dbList.setLocalData(db);
    setWalMode(false);
    loadDbSchema();
    return StatusCode::Success;
}

StatusCode DbManager::setWalMode(bool enable)
{
    QSqlQuery query = newQuery();
    bool isWal = false;
    query.exec("PRAGMA journal_mode");
    if (query.next())
    {
        QString mode = query.value(0).toString().toLower();
        if (mode == "wal")
            isWal = true;
        else
            isWal = false;
    }

    if (isWal == enable)
        return StatusCode::Success;

    if (!enable)
    {
        if (query.exec("PRAGMA journal_mode = DELETE"))
            return StatusCode::Success;
        else
            return StatusCode::DbExecuteFailed;
    }

    // 开启 WAL 模式
    if (!query.exec("PRAGMA journal_mode=WAL"))
    {
        QString err = QString("Failed to enable WAL mode: %1").arg(query.lastError().text());
        setLastError(MessageInfo(err, StatusCode::DbOpenFailed));
        return StatusCode::DbOpenFailed;
    }
    else
    {
        // 设置繁忙等待超时（5000毫秒）
        // 防止多线程并发写入时因锁冲突立即抛出 "database is locked" 错误
        query.exec("PRAGMA busy_timeout=5000");
    }
    return StatusCode::Success;
}

QSqlDatabase *DbManager::getDatabase()
{
    if (!m_dbList.hasLocalData())
    {
        StatusCode result = connect(m_dbName);
        if (result != StatusCode::Success)
        {
            return nullptr;
        }
    }

    QSqlDatabase &db = m_dbList.localData();
    if (!db.isOpen())
    {
        // 连接已断开，尝试重新连接
        StatusCode result = connect(m_dbName);
        if (result != StatusCode::Success)
        {
            return nullptr;
        }
        db = m_dbList.localData();
    }

    return &db;
}

int DbManager::backupDb(const QString &fileName)
{
    if (fileName.isEmpty())
    {
        QString err = "Backup file name is empty";
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::InvalidParameter));
        return static_cast<int>(StatusCode::InvalidParameter);
    }

    // 确保数据库文件存在
    QFileInfo dbFileInfo(m_dbName);
    if (!dbFileInfo.exists())
    {
        QString err = QString("Database file not found: %1").arg(m_dbName);
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::FileWriteFailed));
        return static_cast<int>(StatusCode::FileWriteFailed);
    }

    // 先删除目标文件（如果存在）
    QFile::remove(fileName);

    // 执行备份
    QFile sourceFile(m_dbName);
    if (sourceFile.copy(fileName))
    {
        qDebug() << "Database backup successful: " << fileName;
        return static_cast<int>(StatusCode::Success);
    }
    else
    {
        QString err = QString("Failed to backup database: %1").arg(sourceFile.errorString());
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::DbBackupFailed));
        return static_cast<int>(StatusCode::DbBackupFailed);
    }
}

int DbManager::recoverDb(const QString &fileName)
{
    QFileInfo backupFileInfo(fileName);
    if (!backupFileInfo.exists())
    {
        QString err = QString("Backup file not found: %1").arg(fileName);
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::InvalidParameter));
        return static_cast<int>(StatusCode::InvalidParameter);
    }

    QSqlDatabase *db = getDatabase();
    QString originalDbName = m_dbName;

    // 先关闭连接
    db->close();

    // 备份当前数据库文件（用于回滚）
    QString backupPath = originalDbName + ".bak";
    QFile::remove(backupPath);
    if (!QFile::copy(originalDbName, backupPath))
    {
        db->open(); // 恢复原连接
        QString err = "Failed to backup current database";
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::DbBackupFailed));
        return static_cast<int>(StatusCode::DbBackupFailed);
    }

    // 执行恢复
    if (!QFile::remove(originalDbName))
    {
        db->open();
        QString err = "Failed to remove original database file";
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::FileWriteFailed));
        return static_cast<int>(StatusCode::FileWriteFailed);
    }

    if (!QFile::copy(fileName, originalDbName))
    {
        // 回滚：恢复原文件
        QFile::copy(backupPath, originalDbName);
        db->open();
        QString err = "Failed to copy backup file";
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::DbRecoverFailed));
        return static_cast<int>(StatusCode::DbRecoverFailed);
    }

    // 重新打开连接
    if (!db->open())
    {
        // 回滚
        QFile::copy(backupPath, originalDbName);
        db->open();
        QString err = "Failed to reopen database after recovery";
        qCritical() << err;
        setLastError(MessageInfo(err, StatusCode::DbOpenFailed));
        return static_cast<int>(StatusCode::DbOpenFailed);
    }

    // 清理备份文件
    QFile::remove(backupPath);
    qDebug() << "Database recovery successful";
    return static_cast<int>(StatusCode::Success);
}

StatusCode DbManager::loadDbSchema()
{
    QSqlQuery query = newQuery();
    // 获取所有用户表
    QString sql = "select name from sqlite_master where type='table' AND name NOT LIKE 'sqlite_%'";
    query.prepare(sql);
    if (!query.exec())
    {
        setLastError(MessageInfo(query.lastError().text(), StatusCode::DbOpenFailed));
        return StatusCode::DbOpenFailed;
    }

    while (query.next())
    {
        QString tableName = query.value(0).toString();
        TableSchema table;
        m_dbSchema[tableName] = table;
    }

    for (const QString &tableName : m_dbSchema.keys())
    {
        // 直接修改原数据，无拷贝
        TableSchema &tableSchema = m_dbSchema[tableName];

        // 获取表主建
        sql = QString("PRAGMA table_info(%1)").arg(tableName);
        query.clear();
        query.prepare(sql);
        if (!query.exec())
        {
            setLastError(MessageInfo(query.lastError().text(), StatusCode::DbOpenFailed));
            return StatusCode::DbOpenFailed;
        }

        query.clear();
        sql = QString("PRAGMA table_info(%1)").arg(tableName);
        query.prepare(sql);
        if (!query.exec())
        {
            setLastError(MessageInfo(query.lastError().text(), StatusCode::DbOpenFailed));
            return StatusCode::DbOpenFailed;
        }

        while (query.next())
        {
            QString fieldName = query.value("name").toString();
            QString typeName = query.value("type").toString().toUpper();
            bool notNull = query.value("notnull").toBool();
            QVariant defaultValue = query.value("dflt_value");
            // 大于0即为主键
            // 如果一张表存在联合主键（Composite Primary Key），
            // SQLite 会在 pk 列中返回递增的数字（如 1, 2, 3...）来表示这些字段共同组成主键。

            bool isPk = query.value("pk").toInt() > 0;

            FieldInfo &field = tableSchema[fieldName];
            field.name = fieldName;
            field.defaultValue = defaultValue;
            field.isNullable = !notNull;
            field.isPrimaryKey = isPk;

            // 解析类型信息
            if (typeName.contains("INT") || typeName.contains("INTEGER"))
            {
                field.metaType = QMetaType(QMetaType::Int);
                if (typeName.contains("AUTOINCREMENT") || isPk)
                {
                    field.isAutoInc = true;
                }
            }
            else if (typeName.contains("VARCHAR") || typeName.contains("TEXT"))
            {
                field.metaType = QMetaType(QMetaType::QString);
                // 解析长度信息，如 VARCHAR(255)
                QRegularExpression re(R"(\((\d+)\))");
                QRegularExpressionMatch match = re.match(typeName);
                if (match.hasMatch())
                {
                    field.length = match.captured(1).toInt();
                }
            }
            else if (typeName.contains("REAL") || typeName.contains("FLOAT") || typeName.contains("DOUBLE"))
            {
                field.metaType = QMetaType(QMetaType::Double);
                // 解析精度信息，如 DECIMAL(10,2)
                QRegularExpression re(R"(\((\d+)(?:,(\d+))?\))");
                QRegularExpressionMatch match = re.match(typeName);
                if (match.hasMatch())
                {
                    field.precision = match.captured(1).toInt();
                    if (match.lastCapturedIndex() >= 2)
                    {
                        field.length = match.captured(2).toInt();
                    }
                }
            }
            else if (typeName.contains("BOOL") || typeName.contains("BOOLEAN"))
            {
                field.metaType = QMetaType(QMetaType::Bool);
            }
            else if (typeName.contains("DATETIME"))
            {
                field.metaType = QMetaType(QMetaType::QDateTime);
            }
            else if (typeName.contains("DATE"))
            {
                field.metaType = QMetaType(QMetaType::QDate);
            }
            else if (typeName.contains("TIME"))
            {
                field.metaType = QMetaType(QMetaType::QTime);
            }
            else if (typeName.contains("BLOB"))
            {
                field.metaType = QMetaType(QMetaType::QByteArray);
            }
            else
            {
                field.metaType = QMetaType(QMetaType::QVariant);
            }
        }
    }
#if 0
    // === 调试：验证 m_dbSchema 解析结果 ===
    qDebug() << "[loadDbSchema] 共加载" << m_dbSchema.size() << "张表";
    for (auto tableIt = m_dbSchema.cbegin(); tableIt != m_dbSchema.cend(); ++tableIt)
    {
        qDebug() << "  [表]" << tableIt.key() << "共" << tableIt.value().size() << "个字段";
        for (auto fieldIt = tableIt.value().cbegin(); fieldIt != tableIt.value().cend(); ++fieldIt)
        {
            const FieldInfo &fi = fieldIt.value();
            qDebug() << QString("    [字段] name=%1 type=%2 len=%3 prec=%4 pk=%5 autoInc=%6 nullable=%7 dflt=%8")
                            .arg(fi.name, -20)
                            .arg(QString(fi.metaType.name()), -12)
                            .arg(fi.length, -5)
                            .arg(fi.precision, -5)
                            .arg(fi.isPrimaryKey ? "true" : "false", -6)
                            .arg(fi.isAutoInc   ? "true" : "false", -6)
                            .arg(fi.isNullable  ? "true" : "false", -6)
                            .arg(fi.defaultValue.toString());
        }
    }
    // === 调试结束 ===
#endif
    return StatusCode::Success;
}

QSqlQuery DbManager::newQuery()
{
    QSqlDatabase *db = getDatabase();
    QSqlQuery qry(*db);
    // qDebug() << "newQuery threadId: " << QThread::currentThreadId();
    return qry;
}

int DbManager::queryCount(QSqlQuery &qry) const
{
    int count = 0;
    int initialPos = qry.at();
    // Very strange but for no records .at() returns -2
    if (qry.last())
        count = qry.at() + 1;
    else
        count = 0;

    // Important to restore initial pos
    // 调用此函数后,使用 qry.next() 前调用
    qry.seek(initialPos);
    return count;
}

QJsonArray DbManager::getQueryResult(QSqlQuery &qry)
{
    QJsonArray datas = {};
    if (!qry.isActive())
    {
        if (!qry.exec())
        {
            QString errorInfo = "DbManager::getQueryResult call error:" + qry.lastError().text();
            setLastError(MessageInfo(errorInfo, StatusCode::DbExecuteFailed));
            return datas;
        }
    }

    QStringList fieldNames = {};
    QSqlRecord rec = qry.record();
    for (int i = 0; i < rec.count(); i++)
    {
        fieldNames.append(rec.value(i).toString());
    }

    while (qry.next())
    {
        QJsonObject data = {};
        for (int i = 0; i < fieldNames.count(); i++)
        {
            data[fieldNames[i]] = qry.value(fieldNames[i]).toString();
        }
        datas.append(data);
    }
    return datas;
}

void DbManager::getJsonKeyValues(const QJsonObject &data, QString &keys, QString &values, const QString &sep)
{
    QStringList keyList;
    QStringList valueList;
    for (auto &key : data.keys())
    {
        keyList.append(key);
        valueList.append("'" + data[key].toString() + "'");
    }
    keys = keyList.join(sep);
    values = valueList.join(sep);
}

/**
 * @brief 辅助函数：为 QSqlQuery 绑定 JSON 值
 * @param qry 查询对象
 * @param placeholder 占位符名（如 ":col0"）
 * @param value JSON 值
 */
static void bindJsonValue(QSqlQuery &qry, const QString &placeholder, const QJsonValue &value)
{
    if (value.isBool())
        qry.bindValue(placeholder, value.toBool());
    else if (value.isDouble())
        qry.bindValue(placeholder, value.toDouble());
    else
        qry.bindValue(placeholder, value.toString());
}

StatusCode DbManager::bindVariantValue(QSqlQuery &qry, const QList<BindInfo> &bindInfos)
{
    for (const auto &info : bindInfos)
    {
        QVariant val = info.val;
        // convert() 会尝试将 val 转换为指定的 metaType，保证类型与数据库字段匹配
        // 如果转换失败，val 会变成无效状态 (Invalid)
        if (!val.convert(info.fieldInfo.metaType))
        {
            QString text = "Failed to convert variant to metaType:" + QString(info.fieldInfo.metaType.name());
            setLastError(MessageInfo(text, StatusCode::TypeConvFailed));
            return StatusCode::TypeConvFailed;
        }

        // 绑定到查询中
        // 支持命名占位符 (如 ":name") 或位置占位符 (如 "?")
        qry.bindValue(info.holder, val);
    }
    return StatusCode::Success;
}

int DbManager::updateDatas(const QList<QJsonObject> &datas, const QStringList &whereFileds, const QString &tableName)
{
    if (datas.count() == 0)
        return 0;

    if (tableName == "")
    {
        QString errorInfo = "The table name is empty.";
        setLastError(MessageInfo(errorInfo, StatusCode::InvalidParameter));
        return static_cast<int>(StatusCode::InvalidParameter);
    }

    QSqlDatabase *db = getDatabase();
    TransactionGuard guard(db);
    QSqlQuery qry = newQuery();

    for (int i = 0; i < datas.size(); i++)
    {
        QJsonObject data = datas[i];

        // 去掉 where 字段
        QStringList fields = data.keys();
        for (int j = 0; j < whereFileds.size(); j++)
        {
            int idIndex = fields.indexOf(whereFileds[j]);
            if (idIndex > -1)
                fields.removeAt(idIndex);
        }

        // 构建 SET 占位符: "col0=:val0, col1=:val1, ..."
        QStringList setPlaceholders;
        for (int j = 0; j < fields.count(); j++)
            setPlaceholders.append(fields[j] + "=:" + fields[j]);

        // 构建 WHERE 占位符: "whereCol0=:whereVal0 and whereCol1=:whereVal1"
        QStringList wherePlaceholders;
        for (int j = 0; j < whereFileds.count(); j++)
            wherePlaceholders.append(whereFileds[j] + "=:w_" + whereFileds[j]);

        QString sql = "UPDATE " + tableName + " SET " + setPlaceholders.join(",") + " WHERE " + wherePlaceholders.join(" and ");
        qry.prepare(sql);

        // 绑定 SET 值
        for (int j = 0; j < fields.count(); j++)
            bindJsonValue(qry, ":" + fields[j], data[fields[j]]);

        // 绑定 WHERE 值
        for (int j = 0; j < whereFileds.count(); j++)
            bindJsonValue(qry, ":w_" + whereFileds[j], data[whereFileds[j]]);

        if (!qry.exec())
        {
            setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
            return 1;
        }

        qry.finish();
    }

    guard.commit();
    return 0;
}

int DbManager::appendDatas(QList<QJsonObject> &datas, const QString &tableName, const QString &autoIncId)
{
    if (datas.count() == 0)
        return 0;

    if (tableName == "")
    {
        QString errorInfo = "The data table name is empty.";
        setLastError(MessageInfo(errorInfo, StatusCode::InvalidParameter));
        return 1;
    }

    QString trimmedAutoIncId = autoIncId.trimmed();
    QSqlDatabase *db = getDatabase();
    TransactionGuard guard(db);
    QSqlQuery qry = newQuery();
    for (int i = 0; i < datas.size(); i++)
    {
        QJsonObject data = datas[i];
        // 检查是否有自增字段,有就不添加自增字段值
        QStringList fields = datas[i].keys();
        if (!trimmedAutoIncId.isEmpty())
        {
            int idIndex = fields.indexOf(trimmedAutoIncId);
            if (idIndex > -1)
                fields.removeAt(idIndex);
        }

        // 构建占位符: "INSERT INTO table (col0, col1) VALUES (:val0, :val1)"
        QStringList placeholders;
        for (int j = 0; j < fields.count(); j++)
            placeholders.append(":" + fields[j]);

        QString sql = "INSERT INTO " + tableName + " (" + fields.join(",") + ") VALUES (" + placeholders.join(",") + ")";
        qry.prepare(sql);

        // 绑定值
        for (int j = 0; j < fields.count(); j++)
            bindJsonValue(qry, ":" + fields[j], data[fields[j]]);

        if (!qry.exec())
        {
            setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
            return static_cast<int>(StatusCode::DbExecuteFailed);
        }
        if (!trimmedAutoIncId.isEmpty())
            data[trimmedAutoIncId] = QString::number(qry.lastInsertId().toULongLong());

        datas[i] = data;
        qry.finish();
    }
    guard.commit();
    return 0;
}

int DbManager::execSql(const QString &sql)
{
    if (sql == "")
    {
        QString errorInfo = "The sql string is empty.";
        setLastError(MessageInfo(errorInfo, StatusCode::InvalidParameter));
        return 1;
    }

    QSqlDatabase *db = getDatabase();
    TransactionGuard guard(db);
    QSqlQuery qry = DbManager::newQuery();
    qry.prepare(sql);
    if (!qry.exec())
    {
        setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return 1;
    }
    qry.finish();
    guard.commit();
    return 0;
}

StatusCode DbManager::getDatas(const QString &sql, QList<QVariantMap> &datas)
{
    if (sql == "")
    {
        QString errorInfo = "The sql string is empty.";
        setLastError(MessageInfo(errorInfo, StatusCode::InvalidParameter));
        return StatusCode::InvalidParameter;
    }

    QSqlQuery qry = DbManager::newQuery();
    qry.prepare(sql);
    if (!qry.exec())
    {
        setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return StatusCode::DbExecuteFailed;
    }

    StatusCode status = getQueryDatas(qry, datas);
    if (status != StatusCode::Success)
    {
        setLastError(MessageInfo(qry.lastError().text(), status));
        return status;
    }
    return StatusCode::Success;
}

StatusCode DbManager::findDatas(const QVariantMap &data, QList<QVariantMap> &datas)
{
    // 提取表名
    QString tableName = data["TableName"].toString();
    if (tableName.isEmpty())
    {
        setLastError(MessageInfo("The table name is empty.", StatusCode::InvalidParameter));
        return StatusCode::InvalidParameter;
    }

    QString fieldName = data["FieldName"].toString();
    if (fieldName.isEmpty())
    {
        setLastError(MessageInfo("The field name is empty.", StatusCode::InvalidParameter));
        return StatusCode::InvalidParameter;
    }

    QVariant val = data["Value"];
    if (!val.isValid())
    {
        setLastError(MessageInfo("The value is invalid.", StatusCode::InvalidParameter));
        return StatusCode::InvalidParameter;
    }

    QString sql = QString("SELECT * FROM %1 WHERE %2=:f1").arg(tableName, fieldName);
    QSqlQuery qry = newQuery();
    qry.prepare(sql);

    BindInfo bindInfo;
    bindInfo.holder = ":f1";
    bindInfo.val = val;
    bindInfo.fieldInfo = m_dbSchema[tableName][fieldName];
    QList<BindInfo> bindInfos;
    bindInfos.append(bindInfo);
    StatusCode status = bindVariantValue(qry, bindInfos);
    if (status != StatusCode::Success)
    {
        setLastError(MessageInfo(qry.lastError().text(), status));
        return status;
    }

    if (!qry.exec())
    {
        setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return StatusCode::DbExecuteFailed;
    }

    status = getQueryDatas(qry, datas);
    if (status != StatusCode::Success)
    {
        setLastError(MessageInfo(qry.lastError().text(), status));
        return status;
    }
    return StatusCode::Success;
}

StatusCode DbManager::searchDatas(const QVariantMap &data, QList<QVariantMap> &datas)
{
    // 提取表名
    QString tableName = data["TableName"].toString();
    if (tableName.isEmpty())
    {
        setLastError(MessageInfo("The table name is empty.", StatusCode::InvalidParameter));
        return StatusCode::InvalidParameter;
    }

    // 创建查询副本，移除TableName
    QVariantMap condData = data;
    condData.remove("TableName");

    if (condData.isEmpty())
    {
        // 无查询条件，返回全部数据
        QString sql = QString("SELECT * FROM %1").arg(tableName);
        QSqlQuery qry = newQuery();
        if (!qry.exec(sql))
        {
            setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
            qry.finish();
            return StatusCode::DbExecuteFailed;
        }
        getQueryDatas(qry, datas);
        qry.finish();
        return StatusCode::Success;
    }

    // 定义操作符优先级（从长到短，避免匹配错误）
    const QList<QPair<QString, QString>> operators = {{">=", "_ge"}, {"<=", "_le"}, {">", "_gt"}, {"<", "_lt"}, {"=", "_eq"}};

    QStringList conditions;
    QList<BindInfo> bindInfos;

    // 解析查询条件
    for (const QString &key : condData.keys())
    {
        QString compareOp;
        QString fieldName = key;
        QString opSuffix;

        // 查找匹配的操作符
        bool found = false;
        for (const auto &op : operators)
        {
            if (key.contains(op.first))
            {
                compareOp = op.first;
                opSuffix = op.second;
                fieldName = key;
                fieldName.replace(compareOp, "");
                found = true;
                break;
            }
        }

        if (!found)
            continue;

        // 生成唯一的占位符名称
        QString placeholder = QString(":f_%1_%2").arg(fieldName, opSuffix);

        // 添加SQL条件
        conditions.append(QString("%1 %2 %3").arg(fieldName, compareOp, placeholder));

        BindInfo bindInfo;
        bindInfo.holder = placeholder;
        bindInfo.val = condData[key];
        bindInfo.fieldInfo = m_dbSchema[tableName][fieldName];
        // 存储参数值（使用原始key获取值）
        bindInfos.append(bindInfo);
    }

    // 构建SQL语句
    QString sql = QString("SELECT * FROM %1").arg(tableName);
    if (!conditions.isEmpty())
        sql += " WHERE " + conditions.join(" AND ");

    // 执行查询
    QSqlQuery qry = newQuery();
    qry.prepare(sql);
    // 绑定参数
    StatusCode status = bindVariantValue(qry, bindInfos);
    if (status != StatusCode::Success)
    {
        setLastError(MessageInfo(qry.lastError().text(), status));
        return status;
    }

    if (!qry.exec())
    {
        setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
        return StatusCode::DbExecuteFailed;
    }

    status = getQueryDatas(qry, datas);
    if (status != StatusCode::Success)
    {
        setLastError(MessageInfo(qry.lastError().text(), status));
        return status;
    }
    return StatusCode::Success;
}

// 查询条件结构体（可选，用于更复杂的查询场景）
struct QueryCondition
{
    QString fieldName;
    QString operatorType; // ">=", "<=", ">", "<", "=", "LIKE"
    QJsonValue value;
    QString valueType; // "String", "Number", "Date"

    QString toSqlCondition() const
    {
        QString opSuffix = operatorType;
        opSuffix.replace(">=", "_ge").replace("<=", "_le").replace(">", "_gt").replace("<", "_lt").replace("=", "_eq");
        QString placeholder = QString(":f_%1_%2").arg(fieldName, opSuffix);
        return QString("%1 %2 %3").arg(fieldName, operatorType, placeholder);
    }
};

void DbManager::getDbDatas(QSqlQuery &qry, QList<QJsonObject> &datas)
{
    if (!qry.isActive())
    {
        if (!qry.exec())
        {
            setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
            return;
        }
    }

    QList<QString> names;
    QList<int> types;
    for (int i = 0; i < qry.record().count(); i++)
    {
        names.append(qry.record().field(i).name());
        types.append(qry.record().field(i).metaType().id());
    }
    while (qry.next())
    {
        QJsonObject data;
        for (int i = 0; i < names.count(); i++)
        {
            switch (types[i])
            {
            case QMetaType::Bool:
                data.insert(names[i], qry.value(names[i]).toBool());
                break;
            case QMetaType::Int:
            case QMetaType::UInt:
                data.insert(names[i], qry.value(names[i]).toInt());
                break;
            case QMetaType::LongLong:
            case QMetaType::ULongLong:
                data.insert(names[i], qry.value(names[i]).toLongLong());
                break;
            case QMetaType::Float:
            case QMetaType::Double:
                data.insert(names[i], qry.value(names[i]).toDouble());
                break;
            case QMetaType::QString:
                data.insert(names[i], qry.value(names[i]).toString());
                break;
            default:
                break;
            }
        }
        datas.append(data);
    }
}

StatusCode DbManager::getQueryDatas(QSqlQuery &qry, QList<QVariantMap> &datas)
{
    if (!qry.isActive())
    {
        if (!qry.exec())
        {
            setLastError(MessageInfo(qry.lastError().text(), StatusCode::DbExecuteFailed));
            return StatusCode::DbExecuteFailed;
        }
    }

    while (qry.next())
    {
        QVariantMap map;
        const QSqlRecord &record = qry.record();
        for (int i = 0; i < record.count(); i++)
        {
            map.insert(record.field(i).name(), record.field(i).value());
        }
        datas.append(map);
    }
    return StatusCode::Success;
}

bool DbManager::takeLastError(MessageInfo &msg)
{
    quint64 id = quint64(QThread::currentThreadId());
    QMutexLocker locker(&m_logMutex);
    if (m_lastError.contains(id))
    {
        msg = m_lastError.take(id);
        return true;
    }
    else
    {
        return false;
    }
}

void DbManager::setLastError(const MessageInfo &msg)
{
    quint64 id = quint64(QThread::currentThreadId());
    {
        QMutexLocker locker(&m_logMutex);
        m_lastError[id] = msg;
    }
}
