#include "dbmanager.h"
#include "configer.h"
#include <QSqlDatabase>
#include <QSqlError>
#include <QPluginLoader>
#include <QJsonArray>
#include <QThread>
#include <QDebug>
#include <QSqlRecord>
#include <QSqlField>
#include <QFile>
#include <QFileInfo>


// ========== TransactionGuard 实现 ==========

TransactionGuard::TransactionGuard(QSqlDatabase* db) : m_db(db)
{
    if (m_db) {
        m_db->transaction();
    }
}

TransactionGuard::~TransactionGuard()
{
    if (m_db && !m_committed) {
        m_db->rollback();
    }
}

void TransactionGuard::commit()
{
    if (m_db) {
        m_db->commit();
        m_committed = true;
    }
}


// ========== DbManager 实现 ==========

DbManager::DbManager(QObject *parent) : BaseInfoSender(parent)
{

}

DbManager::~DbManager()
{

}

int DbManager::connect(const QString &dbname)
{
    if (dbname.isEmpty())
    {
        setLastErrorInfo("Database name is empty", Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return static_cast<int>(Enums::ErrorCode::InvalidParameter);
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
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::DbOpenFailed);
        return static_cast<int>(Enums::ErrorCode::DbOpenFailed);
    }
    QSqlQuery query(db);
    // 开启 WAL 模式
    if (!query.exec("PRAGMA journal_mode=WAL"))
    {
        QString err = QString("Failed to enable WAL mode: %1").arg(db.lastError().text());
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::DbOpenFailed);
    }
    else
    {
        // 设置繁忙等待超时（5000毫秒）
        // 防止多线程并发写入时因锁冲突立即抛出 "database is locked" 错误
        query.exec("PRAGMA busy_timeout=5000");
    }

    m_dbList.setLocalData(db);
    return static_cast<int>(Enums::ErrorCode::Success);
}

QSqlDatabase *DbManager::getDatabase()
{
    if (!m_dbList.hasLocalData())
    {
        int result = connect(m_dbName);
        if (result != static_cast<int>(Enums::ErrorCode::Success))
        {
            return nullptr;
        }
    }

    QSqlDatabase& db = m_dbList.localData();
    if (!db.isOpen())
    {
        // 连接已断开，尝试重新连接
        int result = connect(m_dbName);
        if (result != static_cast<int>(Enums::ErrorCode::Success))
        {
            return nullptr;
        }
        db = m_dbList.localData();
    }

    return &db;
}

int DbManager::backupDb(const QString &fileName)
{
    if (fileName.isEmpty()) {
        QString err = "Backup file name is empty";
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return static_cast<int>(Enums::ErrorCode::InvalidParameter);
    }

    // 确保数据库文件存在
    QFileInfo dbFileInfo(m_dbName);
    if (!dbFileInfo.exists()) {
        QString err = QString("Database file not found: %1").arg(m_dbName);
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::FileWriteFailed);
        return static_cast<int>(Enums::ErrorCode::FileWriteFailed);
    }

    // 先删除目标文件（如果存在）
    QFile::remove(fileName);
    
    // 执行备份
    QFile sourceFile(m_dbName);
    if (sourceFile.copy(fileName)) {
        qDebug() << "Database backup successful: " << fileName;
        return static_cast<int>(Enums::ErrorCode::Success);
    } else {
        QString err = QString("Failed to backup database: %1").arg(sourceFile.errorString());
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::DbBackupFailed);
        return static_cast<int>(Enums::ErrorCode::DbBackupFailed);
    }
}

int DbManager::recoverDb(const QString &fileName)
{
    QFileInfo backupFileInfo(fileName);
    if (!backupFileInfo.exists()) {
        QString err = QString("Backup file not found: %1").arg(fileName);
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return static_cast<int>(Enums::ErrorCode::InvalidParameter);
    }

    QSqlDatabase *db = getDatabase();
    QString originalDbName = m_dbName;
    
    // 先关闭连接
    db->close();
    
    // 备份当前数据库文件（用于回滚）
    QString backupPath = originalDbName + ".bak";
    QFile::remove(backupPath);
    if (!QFile::copy(originalDbName, backupPath)) {
        db->open(); // 恢复原连接
        QString err = "Failed to backup current database";
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::DbBackupFailed);
        return static_cast<int>(Enums::ErrorCode::DbBackupFailed);
    }
    
    // 执行恢复
    if (!QFile::remove(originalDbName)) {
        db->open();
        QString err = "Failed to remove original database file";
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::FileWriteFailed);
        return static_cast<int>(Enums::ErrorCode::FileWriteFailed);
    }
    
    if (!QFile::copy(fileName, originalDbName)) {
        // 回滚：恢复原文件
        QFile::copy(backupPath, originalDbName);
        db->open();
        QString err = "Failed to copy backup file";
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::DbRecoverFailed);
        return static_cast<int>(Enums::ErrorCode::DbRecoverFailed);
    }
    
    // 重新打开连接
    if (!db->open()) {
        // 回滚
        QFile::copy(backupPath, originalDbName);
        db->open();
        QString err = "Failed to reopen database after recovery";
        qCritical() << err;
        setLastErrorInfo(err, Enums::InfoType::Toast, Enums::ErrorCode::DbOpenFailed);
        return static_cast<int>(Enums::ErrorCode::DbOpenFailed);
    }
    
    // 清理备份文件
    QFile::remove(backupPath);
    qDebug() << "Database recovery successful";
    return static_cast<int>(Enums::ErrorCode::Success);
}

void DbManager::readTableInfo()
{
    QMutexLocker locker(&m_tableInfoMutex);
    m_tableInfo.clear();

    QSqlQuery query;
    QString strSql = "select name from sqlite_master where type='table'";
    query.prepare(strSql);
    if (!query.exec())
    {
        qDebug() << query.lastError();
        return;
    }

    QStringList tableNameList = {};
    while (query.next())
    {
        QString tableName = query.value(0).toString();
        if (tableName.indexOf("sqlite") >= 0)
            continue;
        tableNameList.append(query.value(0).toString());
    }

    if (tableNameList.isEmpty())
        return;

    for (int i = 0; i < tableNameList.size(); i++)
    {
        strSql = "PRAGMA table_info(" + tableNameList[i] + ")";
        query.clear();
        query.prepare(strSql);
        if (!query.exec())
        {
            qDebug() << query.lastError();
            return;
        }

        QStringList fieldNameList;
        QStringList fieldTypeList;
        QStringList fieldDfltValList;
        while (query.next())
        {
            fieldNameList.append(query.value("name").toString());
            fieldDfltValList.append(query.value("dflt_value").toString());

            QString fieldType = query.value("type").toString();
            if ( (fieldType.indexOf("char") > -1) || (fieldType.indexOf("text") > -1) )
                fieldTypeList.append("string");
            else if ( (fieldType.indexOf("real") > -1)
                     || (fieldType.indexOf("double") > -1) || (fieldType.indexOf("float") > -1) )
                fieldTypeList.append("float");
            else if ( (fieldType.indexOf("int") > -1) || (fieldType.indexOf("INT") > -1) )
                fieldTypeList.append("int");
            else if (fieldType.indexOf("bool") > -1)
                fieldTypeList.append("bool");
            else
                fieldTypeList.append("unknow");
        }
        m_tableInfo.insert(tableNameList[i]+"FieldsName", fieldNameList);
        m_tableInfo.insert(tableNameList[i]+"FieldsType", fieldTypeList);
        m_tableInfo.insert(tableNameList[i]+"FieldsDfltVal", fieldDfltValList);
    }
}

QMap<QString, QStringList> DbManager::getTableInfo() const
{
    QMutexLocker locker(&m_tableInfoMutex);
    return m_tableInfo;
}

QSqlQuery DbManager::newQuery()
{
    QSqlDatabase *db = getDatabase();
    QSqlQuery qry(*db);
    //qDebug() << "newQuery threadId: " << QThread::currentThreadId();
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
            setLastErrorInfo(errorInfo, Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
            return datas;
        }
    }

    QStringList fieldNames = {};
    QSqlRecord rec = qry.record();
    for (int i = 0; i < rec.count(); i++)
    {
        fieldNames.append(rec.fieldName(i));
    }

    while(qry.next())
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
    for(auto &key: data.keys())
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

int DbManager::updateDatas(const QList<QJsonObject> &datas, const QStringList &whereFileds, const QString &tableName)
{
    if (datas.count() == 0)
        return 0;

    if (tableName == "")
    {
        QString errorInfo = "The table name is empty.";
        setLastErrorInfo(errorInfo, Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return 1;
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

        QString sql = "UPDATE " + tableName + " SET " + setPlaceholders.join(",")
                      + " WHERE " + wherePlaceholders.join(" and ");
        qry.prepare(sql);

        // 绑定 SET 值
        for (int j = 0; j < fields.count(); j++)
            bindJsonValue(qry, ":" + fields[j], data[fields[j]]);

        // 绑定 WHERE 值
        for (int j = 0; j < whereFileds.count(); j++)
            bindJsonValue(qry, ":w_" + whereFileds[j], data[whereFileds[j]]);

        if ( !qry.exec() )
        {
            setLastErrorInfo(qry.lastError().text(), Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
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
        setLastErrorInfo(errorInfo, Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
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

        QString sql = "INSERT INTO " + tableName + " (" + fields.join(",")
                      + ") VALUES (" + placeholders.join(",") + ")";
        qry.prepare(sql);

        // 绑定值
        for (int j = 0; j < fields.count(); j++)
            bindJsonValue(qry, ":" + fields[j], data[fields[j]]);

        if ( !qry.exec() )
        {
            setLastErrorInfo(qry.lastError().text(), Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
            return static_cast<int>(Enums::ErrorCode::DbExecuteFailed);
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
        setLastErrorInfo(errorInfo, Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return 1;
    }

    QSqlDatabase *db = getDatabase();
    TransactionGuard guard(db);
    QSqlQuery qry = DbManager::newQuery();
    qry.prepare(sql);
    if ( !qry.exec() )
    {
        setLastErrorInfo(qry.lastError().text(), Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
        return 1;
    }
    qry.finish();
    guard.commit();
    return 0;
}

QList<QJsonObject> DbManager::getDatas(const QString &sql)
{
    QList<QJsonObject> datas = {};
    if (sql == "")
    {
        QString errorInfo = "The sql string is empty.";
        setLastErrorInfo(errorInfo, Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return datas;
    }

    QSqlQuery qry = DbManager::newQuery();
    qry.prepare(sql);
    if ( !qry.exec() )
    {
        qry.finish();
        setLastErrorInfo(qry.lastError().text(), Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
        return datas;
    }
    getDbDatas(qry, datas);
    qry.finish();
    return datas;
}

QList<QJsonObject> DbManager::findDatas(const QJsonObject &data)
{
    QList<QJsonObject> datas = {};
    
    // 1. 提取表名
    QString tableName = data.value("TableName").toString();
    if (tableName.isEmpty())
    {
        setLastErrorInfo("The table name is empty.", Enums::InfoType::Toast, Enums::ErrorCode::InvalidParameter);
        return datas;
    }

    // 2. 创建查询副本，移除TableName
    QJsonObject queryData = data;
    queryData.remove("TableName");
    
    if (queryData.isEmpty())
    {
        // 无查询条件，返回全部数据
        QString sql = QString("SELECT * FROM %1").arg(tableName);
        QSqlQuery qry = newQuery();
        if (!qry.exec(sql))
        {
            setLastErrorInfo(qry.lastError().text(), Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
            qry.finish();
            return datas;
        }
        getDbDatas(qry, datas);
        qry.finish();
        return datas;
    }

    // 3. 定义操作符优先级（从长到短，避免匹配错误）
    const QList<QPair<QString, QString>> operators = {
        {">=", "_ge"}, {"<=", "_le"}, 
        {">", "_gt"}, {"<", "_lt"}, {"=", "_eq"}
    };

    QStringList conditions;
    QMap<QString, QJsonValue> bindValues;

    // 4. 解析查询条件
    for (const QString& key : queryData.keys())
    {
        QString compareOp;
        QString fieldName = key;
        QString opSuffix;

        // 查找匹配的操作符
        bool found = false;
        for (const auto& op : operators)
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
        
        // 存储参数值（使用原始key获取值）
        bindValues.insert(placeholder, queryData.value(key));
    }

    // 5. 构建SQL语句
    QString sql = QString("SELECT * FROM %1").arg(tableName);
    if (!conditions.isEmpty())
        sql += " WHERE " + conditions.join(" AND ");

    // 6. 执行查询
    QSqlQuery qry = newQuery();
    qry.prepare(sql);

    // 绑定参数
    for (auto it = bindValues.constBegin(); it != bindValues.constEnd(); ++it)
    {
        bindJsonValue(qry, it.key(), it.value());
    }

    if (!qry.exec())
    {
        setLastErrorInfo(qry.lastError().text(), Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
        qry.finish();
        return datas;
    }

    getDbDatas(qry, datas);
    qry.finish();
    return datas;
}

// 查询条件结构体（可选，用于更复杂的查询场景）
struct QueryCondition {
    QString fieldName;
    QString operatorType;  // ">=", "<=", ">", "<", "=", "LIKE"
    QJsonValue value;
    QString valueType;     // "String", "Number", "Date"
    
    QString toSqlCondition() const {
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
            QString errorInfo = "DbManager::getQueryResult call error:" + qry.lastError().text();
            setLastErrorInfo(errorInfo, Enums::InfoType::Toast, Enums::ErrorCode::DbExecuteFailed);
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

bool DbManager::lastErrorInfo(int &errNum, QString &errInfo)
{
    quint64 id = quint64(QThread::currentThreadId());
    QMutexLocker locker(&m_errorMutex);
    if(m_lastError.contains(id))
    {
        QPair<int, QString> pair = m_lastError[id];
        errNum = pair.first;
        errInfo = pair.second;
        return true;
    }
    else
    {
        return false;
    }
}

void DbManager::setLastErrorInfo(const QString &errInfo, Enums::InfoType type, Enums::ErrorCode code)
{
    quint64 id = quint64(QThread::currentThreadId());
    {
        QMutexLocker locker(&m_errorMutex);
        m_lastError[id] = QPair<int, QString>(static_cast<int>(code), errInfo);
    }
    qCritical() << errInfo;
    emit messageEmitted(errInfo, type, code);
}

void DbManager::loadTableInfo(const QString &tableName)
{
    QSqlDatabase *db = getDatabase();
    if (!db) {
        qCritical() << "Failed to get database connection";
        return;
    }
    QSqlQuery query(*db);
    QString sql = QString("PRAGMA table_info(%1)").arg(tableName);

    if (query.exec(sql))
    {
        while (query.next()) {
            // query.value(0): 列ID (cid)
            // query.value(1): 字段名 (name)
            // query.value(2): 数据类型 (type)
            // query.value(3): 是否非空 (notnull)
            // query.value(4): 默认值 (dflt_value)
            // query.value(5): 是否主键 (pk)
            qDebug() << "字段名:" << query.value(1).toString()
                     << "类型:" << query.value(2).toString();
        }
    }
    else
    {
        qDebug() << "查询失败:" << query.lastError().text();
    }
}

