/****************************************************************************
** Qt for cross-platform series
** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
** This work is licensed under the Creative Commons
** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
** Author: Hula
** Web: www.123hula.com
** WeChat: ihula123
** Contact: benny1225@hotmail.com
** Date: 2022.9.25
** Brief: 数据库管理类
** History:
****************************************************************************/
#ifndef DBMANAGER_H
#define DBMANAGER_H

class QSqlDatabase;

#include "basemsgsender.h"
#include "common.h"
#include "singleton.h"
#include <QJsonObject>
#include <QMap>
#include <QMutex>
#include <QMutexLocker>
#include <QObject>
#include <QSqlQuery>
#include <map>
#include <memory>

/**
 * @brief RAII 事务守卫类
 *
 * 构造时开启事务，析构时若未提交则自动回滚。
 * 使用 commit() 显式提交事务。
 */
class TransactionGuard
{
    QSqlDatabase *m_db;
    bool m_committed = false;

  public:
    explicit TransactionGuard(QSqlDatabase *db);
    ~TransactionGuard();
    void commit();
    bool isCommitted() const
    {
        return m_committed;
    }
};

class DbManager : public QObject
{
    Q_OBJECT
  private:
    explicit DbManager(QObject *parent = nullptr);

  public:
    /**
     * @brief 数据库字段属性
     */
    struct FieldInfo
    {
        QString name;                                           // 字段名称
        QMetaType metaType = QMetaType(QMetaType::UnknownType); // 数据类型
        int length = 0;                                         // 字段长度
        int precision = 0;                                      // 精度 (常用于浮点数或定点数)
        QVariant defaultValue;                                  // 默认值
        bool isAutoInc = false;                                 // 是否自增
        bool isNullable = true;                                 // 是否允许为 NULL
        bool isPrimaryKey = false;                              // 是否为主键
    };

    /** @brief 类单一实例 */
    SINGLETON(DbManager)

    ~DbManager();

    /** @brief 连接数据库 */
    StatusCode connect(const QString &dbname);

    /** @brief 获取所在线程的数据库连接 */
    QSqlDatabase *getDatabase();

    /**
     *@brief 备份数据
     *@param[in] fileName:保存的文件名
     *@param[in] datas:保存的数据
     *@return 0:完成;1:失败
     */
    Q_INVOKABLE int backupDb(const QString &fileName);

    /**
     *@brief 恢复数据
     *@param[in] fileName:数据文件名
     *@return 0:完成;1:失败
     */
    Q_INVOKABLE int recoverDb(const QString &fileName);

    /** @brief 读取所有表的字段信息 */
    StatusCode loadDbSchema();

    /** @brief 获取所在线程的QSqlQuery类 */
    QSqlQuery newQuery();

    /** @brief 获取数据集的记录数 */
    int queryCount(QSqlQuery &qry) const;

    /** @brief 获取数据集的数据 */
    QJsonArray getQueryResult(QSqlQuery &qry);

    /** @brief 获取Json的keys和values */
    void getJsonKeyValues(const QJsonObject &data, QString &keys, QString &values, const QString &sep = ";");

    /**
     *@brief 更新表数据
     *@param[in] datas:待更新的数据集及where字段的值
     *@param[in] whereFileds:where字段名
     *@param[in] tableName:待更新的表名
     */
    int updateDatas(const QList<QJsonObject> &datas, const QStringList &whereFileds, const QString &tableName);

    /**
     *@brief 新增表数据
     *@param[in] datas:待添加的数据集及返回的自增ID值
     *@param[in] tableName:待更新的表名
     *@param[in] autoIncId:自增ID值字段名
     */
    int appendDatas(QList<QJsonObject> &datas, const QString &tableName, const QString &autoIncId = "Id");

    /**
     *@brief 执行SQL语句
     *@param[in] sql:执行SQL语句
     */
    int execSql(const QString &sql);

    /**
     *@brief 获取数据
     *@param[in] sql:执行SQL语句
     */
    StatusCode getDatas(const QString &sql, QList<QVariantMap> &datas);

    /**
     *@brief 更新表数据
     *@param[in] datas:待更新的数据集及where字段的值
     *@param[in] whereFileds:where字段名
     *@param[in] tableName:待更新的表名
     */
    QList<QJsonObject> findDatas(const QJsonObject &data);

    /**
     *@brief 查询表数据
     *@param[in] data:待查询的表名及条件
     *@param[out] datas:查询结果
     *@return 执行状态
     */
    StatusCode searchDatas(const QVariantMap &data, QList<QVariantMap> &datas);

    /**
     *@brief 读取数据集记录到QJsonArray
     *@param[in] qry:数据集
     *@param[in] records:读取的数据
     */
    void getDbDatas(QSqlQuery &qry, QList<QJsonObject> &datas);

    /**
     *@brief 读取数据集记录到QList<QVariantMap>
     *@param[in] qry 数据集
     *@param[out] datas 读取的数据
     */
    StatusCode getQueryDatas(QSqlQuery &qry, QList<QVariantMap> &datas);

    /**
     *@brief 所在线程的最后错误消息
     *@param[in] msg 错误消息
     *@return bool true表示有错误消息，false表示无错误消息
     */
    bool takeLastError(MessageInfo &msg);

    /** @brief 设置所在线程的最后错误信息 */
    void setLastError(const MessageInfo &msg);

  private:
    /**
     * @brief QSqlQuery::bindValue 用到的信息
     */
    struct BindInfo
    {
        QString holder;      // bindValue中的占位符
        FieldInfo fieldInfo; // 绑定字段的信息
        QVariant val;        // 绑定的值
    };

    StatusCode bindVariantValue(QSqlQuery &qry, const QList<BindInfo> &bindInfos);

    /** @brief 数据库名称 */
    QString m_dbName;

    /** @brief 保存所在线程的数据库连接 */
    QThreadStorage<QSqlDatabase> m_dbList;
    mutable QMutex m_dbMutex;

    /** @brief 保存数据表信息 */
    // 定义字段信息的哈希表别名
    using TableSchema = QHash<QString, FieldInfo>;
    // 定义整个数据库的元数据映射
    using DatabaseSchema = QHash<QString, TableSchema>;
    DatabaseSchema m_dbSchema;

    /** @brief 保存所在线程的最后错误信息 */
    QHash<quint64, MessageInfo> m_lastError;
    mutable QMutex m_logMutex;
};

#endif // DBMANAGER_H
