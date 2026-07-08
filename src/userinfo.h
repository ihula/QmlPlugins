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

#include "messagecenter.h"
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
    QML_SINGLETON

    // 模块字符串常量，供 QML 直接引用
    Q_PROPERTY(QString USERINFO MEMBER m_userInfoModule CONSTANT)
    Q_PROPERTY(QString DATADICT MEMBER m_dataDictModule CONSTANT)
    Q_PROPERTY(QString PATIENTS MEMBER m_patientsModule CONSTANT)
    Q_PROPERTY(QString PREFERENCES MEMBER m_preferencesModule CONSTANT)
    Q_PROPERTY(QString REPORT MEMBER m_reportModule CONSTANT)
    Q_PROPERTY(QString MESSAGECENTER MEMBER m_messageCenterModule CONSTANT)
    Q_PROPERTY(QString ROLEMANAGER MEMBER m_roleManagerModule CONSTANT)

    // 权限动作字符串常量，供 QML 直接引用
    Q_PROPERTY(QString READ MEMBER m_readAction CONSTANT)
    Q_PROPERTY(QString WRITE MEMBER m_writeAction CONSTANT)
    Q_PROPERTY(QString DELETE MEMBER m_deleteAction CONSTANT)
    Q_PROPERTY(QString REVIEW MEMBER m_reviewAction CONSTANT)
    Q_PROPERTY(QString PRINT MEMBER m_printAction CONSTANT)
    Q_PROPERTY(QString EXPORT MEMBER m_exportAction CONSTANT)

    // 数据库字段字符串常量，供 QML 直接引用
    Q_PROPERTY(QString ID MEMBER m_fieldId CONSTANT)
    Q_PROPERTY(QString NAME MEMBER m_fieldName CONSTANT)
    Q_PROPERTY(QString ACCOUNT MEMBER m_fieldAccount CONSTANT)
    Q_PROPERTY(QString PASSWORD MEMBER m_fieldPassWord CONSTANT)
    Q_PROPERTY(QString SALT MEMBER m_fieldSalt CONSTANT)
    Q_PROPERTY(QString STATUS MEMBER m_fieldStatus CONSTANT)
    Q_PROPERTY(QString CONTACT MEMBER m_fieldContact CONSTANT)
    Q_PROPERTY(QString ROLENAME MEMBER m_fieldRoleName CONSTANT)
    Q_PROPERTY(QString LASTLOGIN MEMBER m_fieldLastLogin CONSTANT)
    Q_PROPERTY(QString CREATETIME MEMBER m_fieldCreateTime CONSTANT)
    Q_PROPERTY(QString DELETETIME MEMBER m_fieldDeleteTime CONSTANT)

    Q_PROPERTY(QString userName MEMBER m_userName CONSTANT)
    Q_PROPERTY(QString userAccount MEMBER m_userAccount CONSTANT)

  private:
    explicit UserInfo(QObject *parent = nullptr) : QObject(parent)
    {
        MessageCenter *msgCenter = MessageCenter::instance();
        connect(this, &UserInfo::messageEmitted, msgCenter, &MessageCenter::handleMessage);
    }

  public:
    /** @brief 类单一实例 */
    SINGLETON(UserInfo)

    static UserInfo *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        //  在这里返回你的单例实例
        //  比如使用静态局;部变量实现经典的单例模式
        return instance();
    }

    /** @brief 获取当前登录用户名 */
    QString userName() const
    {
        return m_userName;
    }

    /** @brief 获取当前登录用户账号 */
    QString userAccount() const
    {
        return m_userAccount;
    }

    /**
     *@brief 用户账号是否已存在
     *@param[in] id:用户Id
     *@param[in] account:用户账号
     *@return 0:存在;1:不存在
     */
    Q_INVOKABLE int accountExisted(const QString &account, bool isUpdate);

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
    Q_INVOKABLE QString findUserName(const QString &account);

    /**
     *@brief 读取所有用户信息
     *@return 用户信息Json格式
     */
    Q_INVOKABLE QList<QVariantMap> getUsers();

    /**
     *@brief 新增角色
     *@param[in] data:QVariantMap格式角色信息
     *@return 0:失败;>0:样本id
     */
    Q_INVOKABLE quint64 appendUser(const QVariantMap &data);

    /** @brief 通过字段名查找角色
     *@return 0:成功；!=0:失败
     */
    Q_INVOKABLE int updateUser(const QVariantMap &data, const QVariantMap &condData);

    /**
     *@brief 删除用户
     *@param[in] idList:用户Id列表
     *@return 0:完成;1:失败
     */
    Q_INVOKABLE int deleteUsers(const QStringList &idList);

    /** @brief 加载角色权限 */
    void loadPermissions();

    /** @brief 检查指定模块是否包含某个动作权限 */
    Q_INVOKABLE bool hasModuleAction(const QString &module, const QString &action);

    /** @brief 检查是否包含某个模块 */
    Q_INVOKABLE bool hasModule(const QString &module);

  signals:
    /**
     * @brief 发送消息到消息中心
     * @param info 错误信息或提示信息
     * @param type 信息类型 (Toast/Confirmation)，默认为 Toast
     * @param code 错误码，默认为 NoError
     */
    void messageEmitted(const MessageInfo &msg);

    /**
     *@brief 发送已登录信息
     *@param[in] account:用户账号
     *@param[in] userName:用户名
     */
    void logined(const QString &account, const QString &userName);

  private:
    /** @brief 发送数据库错误消息 */
    void sendDbMessage();

    /** @brief 通过字段名查找用户 */
    QVariantMap findUser(const QString &fieldName, const QString &val);

    /** @brief 验证密码 */
    bool verifyPassword(const QString &password, const QString &storedHash, const QString &salt);

    /**
     * @brief 哈希密码（用于新增/修改用户时自动处理）
     * @param password 明文密码
     * @return 格式为 "salt$hash" 的哈希字符串
     */
    QString hashPassword(const QString &password, const QString &salt);

    /** @brief 生成随机盐值 */
    QString generateSalt();

    const QString m_tableName = "users";

    /** @brief 表字段名 */
    QStringList m_headers;

    /** @brief 数据记录,QList<Row> */
    QList<QList<QVariant>> m_data;

    /** @brief 线程锁 */
    mutable QMutex m_dataMutex;

    /** @brief m_headers中的主键下标 */
    int m_primaryKeyIndex = 0;

    /** @brief 登录的用户账号 */
    QString m_userAccount;

    /** @brief 登录的用户名 */
    QString m_userName;

    /** @brief 登录的用户角色ID */
    QString m_roleName;

    /** @brief 权限字典,module -> action set */
    QMap<QString, QSet<QString>> m_permissions;

    // --- 模块常量（直接访问成员变量） ---
    const QString m_userInfoModule = PermModule::UserInfo;
    const QString m_dataDictModule = PermModule::DataDict;
    const QString m_patientsModule = PermModule::Patients;
    const QString m_preferencesModule = PermModule::Preferences;
    const QString m_reportModule = PermModule::Report;
    const QString m_messageCenterModule = PermModule::MessageCenter;
    const QString m_roleManagerModule = PermModule::RoleManager;

    // --- 动作常量（直接访问成员变量） ---
    const QString m_readAction = PermAction::Read;
    const QString m_writeAction = PermAction::Write;
    const QString m_deleteAction = PermAction::Delete;
    const QString m_reviewAction = PermAction::Review;
    const QString m_printAction = PermAction::Print;
    const QString m_exportAction = PermAction::Export;

    // 数据库字段名
    const QString m_fieldId = "id";
    const QString m_fieldName = "name";
    const QString m_fieldAccount = "account";
    const QString m_fieldPassWord = "password";
    const QString m_fieldSalt = "salt";
    const QString m_fieldStatus = "status";
    const QString m_fieldContact = "contact";
    const QString m_fieldRoleName = "role_name";
    const QString m_fieldLastLogin = "last_login_at";
    const QString m_fieldCreateTime = "create_at";
    const QString m_fieldDeleteTime = "delete_at";
};

#endif // USERINFO_H
