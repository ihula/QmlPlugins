/****************************************************************************
 ** Qt for cross-platform series
 ** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
 ** This work is licensed under the Creative Commons
 ** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
 ** Author: Hula
 ** Web: www.123hula.com
 ** WeChat: ihula123
 ** Contact: benny1225@hotmail.com
 ** Date: 2022.11.25
 ** Brief: 病人信息类
 ** History:
 ****************************************************************************/
#ifndef USERINFO_H
#define USERINFO_H

#include "basemsgsender.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QMutex>
#include <QMutexLocker>
#include <QObject>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QtQml>

class UserInfo : public QObject
{
    Q_OBJECT
    QML_ELEMENT
  public:
    explicit UserInfo(QObject *parent = nullptr) : QObject(parent), m_sender(this)
    {
        connect(this, &UserInfo::messageEmitted, &m_sender, &BaseMsgSender::messageEmitted);
    }

    Q_INVOKABLE void loadDatas();

    /**
     *@brief 查找用户信息
     *@param[in] value:表字段值
     *@param[in] key:表字段名
     *@return 用户信息Json格式
     */
    Q_INVOKABLE QJsonObject find(const QString &value, const QString &key = "Id");

    /**
     *@brief 读取所有用户信息
     *@return 用户信息Json格式
     */
    Q_INVOKABLE QList<QVariantMap> getDatas();

    /**
     *@brief 新增用户信息
     *@param[in] data:用户信息Json格式
     *@return 0:失败;>0:用户id
     */
    Q_INVOKABLE quint64 appendData(QJsonObject data);

    /**
     *@brief 更新用户信息
     *@param[in] data:用户信息Json格式
     *@return 0:完成;1:失败
     */
    Q_INVOKABLE int updateData(QJsonObject data);

    /**
     *@brief 删除用户
     *@param[in] id:用户Id
     *@return 0:完成;1:失败
     */
    Q_INVOKABLE int deleteData(const QString &id);

    /**
     *@brief 用户账号是否已存在
     *@param[in] id:用户Id
     *@param[in] account:用户账号
     *@return 0:存在;1:不存在
     */
    Q_INVOKABLE int accountExisted(const QString &account, const QString &id = "");

    /**
     *@brief 验证用户密码是否正确
     *@param[in] account:用户账号
     *@param[in] pwd:用户密码
     *@return 0:正确;1:不正确
     */
    Q_INVOKABLE int checkPassword(const QString &account, const QString &pwd);

    /**
     *@brief 用户登录
     *@param[in] account 用户账号
     *@param[in] pwd 用户密码
     *@return true:成功;false:失败
     */
    Q_INVOKABLE bool login(const QString &account, const QString &pwd);

    /**
     *@brief 获取用户名
     *@param[in] account:用户账号
     *@return 返回用户名
     */
    Q_INVOKABLE QString getUserName(const QString &account);

    /**
     * @brief 哈希密码（用于新增/修改用户时自动处理）
     * @param password 明文密码
     * @return 格式为 "salt$hash" 的哈希字符串
     */
    Q_INVOKABLE QString hashPassword(const QString &password, const QString &salt);

  signals:
    /**
     * @brief 发送消息到消息中心
     * @param info 错误信息或提示信息
     * @param type 信息类型 (Toast/Confirmation)，默认为 Toast
     * @param code 错误码，默认为 NoError
     */
    void messageEmitted(MessageInfo msg);

    /**
     *@brief 发送已登录信息
     *@param[in] account:用户账号
     *@param[in] userName:用户名
     */
    void logined(QString account, QString userName);

  private:
    /** @brief 发送数据库错误消息 */
    void sendDbMessage();

    /** @brief 通过账号查找用户 */
    QJsonObject findUserByAccount(const QString &account);

    /** @brief 通过字段名查找用户
     */
    QVariantMap findUser(const QString &fieldName, const QString &val);

    /** @brief 验证密码 */
    bool verifyPassword(const QString &password, const QString &storedHash, const QString &salt);

    /** @brief 生成随机盐值 */
    QString generateSalt();

    /** @brief 不使用多重继承,定义类成员变量 */
    BaseMsgSender m_sender;

    /** @brief 表字段名 */
    QStringList m_headers;

    /** @brief 数据记录,QList<Row> */
    QList<QList<QVariant>> m_data;

    /** @brief 线程锁 */
    mutable QMutex m_dataMutex;

    /** @brief m_headers中的主键下标 */
    int m_primaryKeyIndex = 0;
};

#endif // USERINFO_H
