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

#include "singleton.h"
#include "baseinfosender.h"
#include <QObject>
#include <QMap>
#include <QJsonObject>
#include <QSqlQuery>
#include <QMutex>
#include <QMutexLocker>
#include <map>
#include <memory>

/**
 * @brief 数据库错误码枚举
 */
enum class DbErrorCode {
    Success = 0,
    OpenFailed = 1201,
    BackupFailed = 1202,
    RecoverFailed = 1203,
    ExecuteFailed = 1204,
    InvalidParameter = 1001,
    FileOperationFailed = 2001
};

/**
 * @brief RAII 事务守卫类
 *
 * 构造时开启事务，析构时若未提交则自动回滚。
 * 使用 commit() 显式提交事务。
 */
class TransactionGuard {
    QSqlDatabase* m_db;
    bool m_committed = false;
public:
    explicit TransactionGuard(QSqlDatabase* db);
    ~TransactionGuard();
    void commit();
    bool isCommitted() const { return m_committed; }
};

class DbManager : public BaseInfoSender
{
    Q_OBJECT
private:
    explicit DbManager(QObject *parent = nullptr);

public:
    /** @brief 类单一实例 */
    SINGLETON(DbManager)

    ~DbManager() override;

    /** @brief 创建数据库连接 */
    int createConnection(const QString &dbname);

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

    /** @brief 读取所有表信息 */
    void readTableInfo();

    /** @brief 获取所有表信息 */
    QMap<QString, QStringList> getTableInfo() const;

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
    QList<QJsonObject> getDatas(const QString &sql);

    /**
    *@brief 更新表数据
    *@param[in] datas:待更新的数据集及where字段的值
    *@param[in] whereFileds:where字段名
    *@param[in] tableName:待更新的表名
    */
    QList<QJsonObject> findDatas(const QJsonObject &data);

    /**
    *@brief 读取数据集记录到QJsonArray
    *@param[in] qry:数据集
    *@param[in] records:读取的数据
    */
    void getDbDatas(QSqlQuery &qry, QList<QJsonObject> &datas);

    /**
    *@brief 所在线程的最后错误信息
    *@param[in] errNum:错误号
    *@param[in] errInfo:错误信息
    */
    bool lastErrorInfo(int &errNum, QString &errInfo);

    /** @brief 设置所在线程的最后错误信息 */
    void setLastErrorInfo(int errNum, const QString &errInfo);

private:
    /** @brief 数据库名称 */
    QString m_dbName;

    /** @brief 保存所在线程的数据库连接 */
    std::map<QString, std::unique_ptr<QSqlDatabase>> m_dbList;
    mutable QMutex m_dbMutex;

    /** @brief 保存数据表信息 */
    QMap<QString, QStringList> m_tableInfo;
    mutable QMutex m_tableInfoMutex;

    /** @brief 保存所在线程的最后错误信息 */
    QHash<quint64, QPair<int, QString>> m_lastError;
    mutable QMutex m_errorMutex;
};

#endif // DBMANAGER_H
