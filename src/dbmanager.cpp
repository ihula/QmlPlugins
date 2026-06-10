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

// 错误码定义
constexpr int DB_ERROR_SUCCESS = 0;
constexpr int DB_ERROR_OPEN_FAILED = 1201;
constexpr int DB_ERROR_BACKUP_FAILED = 1202;
constexpr int DB_ERROR_RECOVER_FAILED = 1203;
constexpr int DB_ERROR_EXEC_FAILED = 1204;
constexpr int DB_ERROR_INVALID_PARAM = 1001;
constexpr int DB_ERROR_FILE_OPERATION = 2001;


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
    QMutexLocker locker(&m_dbMutex);
    for (auto& [key, db] : m_dbList)
    {
        if (db) {
            db->close();
        }
    }
    // std::unique_ptr 会在 std::map 销毁时自动释放内存
}

int DbManager::createConnection(const QString &dbname)
{
    if (dbname.isEmpty()) {
        QString err = "Database name is empty";
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_INVALID_PARAM, err);
        return DB_ERROR_INVALID_PARAM;
    }

    QMutexLocker locker(&m_dbMutex);
    m_dbName = dbname;
    QString threadId = QString("%1").arg(quintptr(QThread::currentThreadId()));
    
    // 使用线程ID作为连接名称，避免冲突
    auto db = std::make_unique<QSqlDatabase>(QSqlDatabase::addDatabase("QSQLITE", threadId));
    db->setDatabaseName(m_dbName);
    
    if (!db->open()) {
        QString err = QString("Failed to open database: %1").arg(db->lastError().text());
        qCritical().noquote() << err;
        setLastErrorInfo(DB_ERROR_OPEN_FAILED, err);
        return DB_ERROR_OPEN_FAILED;
    }

    m_dbList[threadId] = std::move(db);
    //readTablesInfo();
    return DB_ERROR_SUCCESS;
}

QSqlDatabase *DbManager::getDatabase()
{
    QString threadId = QString("%1").arg(quintptr(QThread::currentThreadId()));
    
    // 先检查是否已有连接（快速路径，不加锁）
    {
        QMutexLocker locker(&m_dbMutex);
        auto it = m_dbList.find(threadId);
        if (it != m_dbList.end() && it->second && it->second->isOpen()) {
            return it->second.get();
        }
    }
    
    // 需要创建新连接
    auto newDb = std::make_unique<QSqlDatabase>(QSqlDatabase::addDatabase("QSQLITE", threadId));
    newDb->setDatabaseName(m_dbName);
    if (!newDb->open()) {
        QString err = newDb->lastError().text();
        qCritical() << "Failed to open database:" << err;
        setLastErrorInfo(DB_ERROR_OPEN_FAILED, err);
        return nullptr;
    }
    
    // 添加到连接列表
    QMutexLocker locker(&m_dbMutex);
    m_dbList[threadId] = std::move(newDb);
    return m_dbList[threadId].get();
}

int DbManager::backupDb(const QString &fileName)
{
    if (fileName.isEmpty()) {
        QString err = "Backup file name is empty";
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_INVALID_PARAM, err);
        return DB_ERROR_INVALID_PARAM;
    }

    // 确保数据库文件存在
    QFileInfo dbFileInfo(m_dbName);
    if (!dbFileInfo.exists()) {
        QString err = QString("Database file not found: %1").arg(m_dbName);
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_FILE_OPERATION, err);
        return DB_ERROR_FILE_OPERATION;
    }

    // 先删除目标文件（如果存在）
    QFile::remove(fileName);
    
    // 执行备份
    QFile sourceFile(m_dbName);
    if (sourceFile.copy(fileName)) {
        qDebug() << "Database backup successful: " << fileName;
        return DB_ERROR_SUCCESS;
    } else {
        QString err = QString("Failed to backup database: %1").arg(sourceFile.errorString());
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_BACKUP_FAILED, err);
        return DB_ERROR_BACKUP_FAILED;
    }
}

int DbManager::recoverDb(const QString &fileName)
{
    QFileInfo backupFileInfo(fileName);
    if (!backupFileInfo.exists()) {
        QString err = QString("Backup file not found: %1").arg(fileName);
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_INVALID_PARAM, err);
        return DB_ERROR_INVALID_PARAM;
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
        setLastErrorInfo(DB_ERROR_BACKUP_FAILED, err);
        return DB_ERROR_BACKUP_FAILED;
    }
    
    // 执行恢复
    if (!QFile::remove(originalDbName)) {
        db->open();
        QString err = "Failed to remove original database file";
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_FILE_OPERATION, err);
        return DB_ERROR_FILE_OPERATION;
    }
    
    if (!QFile::copy(fileName, originalDbName)) {
        // 回滚：恢复原文件
        QFile::copy(backupPath, originalDbName);
        db->open();
        QString err = "Failed to copy backup file";
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_RECOVER_FAILED, err);
        return DB_ERROR_RECOVER_FAILED;
    }
    
    // 重新打开连接
    if (!db->open()) {
        // 回滚
        QFile::copy(backupPath, originalDbName);
        db->open();
        QString err = "Failed to reopen database after recovery";
        qCritical() << err;
        setLastErrorInfo(DB_ERROR_OPEN_FAILED, err);
        return DB_ERROR_OPEN_FAILED;
    }
    
    // 清理备份文件
    QFile::remove(backupPath);
    qDebug() << "Database recovery successful";
    return DB_ERROR_SUCCESS;
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
            setLastErrorInfo(1, errorInfo);
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
        setLastErrorInfo(1, errorInfo);
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
            setLastErrorInfo(12, qry.lastError().text());
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
        setLastErrorInfo(1, errorInfo);
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
            setLastErrorInfo(13, qry.lastError().text());
            return 13;
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
        setLastErrorInfo(1, errorInfo);
        return 1;
    }

    QSqlDatabase *db = getDatabase();
    TransactionGuard guard(db);
    QSqlQuery qry = DbManager::newQuery();
    qry.prepare(sql);
    if ( !qry.exec() )
    {
        setLastErrorInfo(1, qry.lastError().text());
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
        setLastErrorInfo(1, errorInfo);
        return datas;
    }

    QSqlQuery qry = DbManager::newQuery();
    qry.prepare(sql);
    if ( !qry.exec() )
    {
        qry.finish();
        setLastErrorInfo(1, qry.lastError().text());
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
        setLastErrorInfo(1, "The table name is empty.");
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
            setLastErrorInfo(1, qry.lastError().text());
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
        setLastErrorInfo(1, qry.lastError().text());
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
            setLastErrorInfo(1, errorInfo);
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

void DbManager::setLastErrorInfo(int errNum, const QString &errInfo)
{
    quint64 id = quint64(QThread::currentThreadId());
    {
        QMutexLocker locker(&m_errorMutex);
        m_lastError[id] = QPair<int, QString>(errNum, errInfo);
    }
    qDebug() << errInfo;
    emit DbManager::instance()->sendInfo(errNum, errInfo);
}

