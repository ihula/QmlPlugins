#include "common.h"
#include "messagecenter.h"
#include "singleton.h"
#include <QJsonArray>
#include <QMap>
#include <QObject>
#include <QSet>
#include <QStringList>
#include <QtQml>

/**
 * @brief 权限管理器 - 基于动作的多选权限模型
 *
 * 权限 JSON 格式: {"customers": ["read","write","delete","export"], ...}
 * 每个模块可组合多个动作: read/write/delete/review/print/export
 */
class RoleManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // 数据库字段字符串常量，供 QML 直接引用
    Q_PROPERTY(QString ID MEMBER m_fieldId CONSTANT)
    Q_PROPERTY(QString NAME MEMBER m_fieldName CONSTANT)
    Q_PROPERTY(QString PERMS MEMBER m_fieldPrems CONSTANT)
    Q_PROPERTY(QString DESC MEMBER m_fieldDesc CONSTANT)
    Q_PROPERTY(QString STATUS MEMBER m_fieldStatus CONSTANT)
    Q_PROPERTY(QString CREATETIME MEMBER m_fieldCreateTime CONSTANT)

  private:
    explicit RoleManager(QObject *parent = nullptr) : QObject(parent)
    {
        MessageCenter *msgCenter = MessageCenter::instance();
        connect(this, &RoleManager::messageEmitted, msgCenter, &MessageCenter::handleMessage);
    }

  public:
    /** @brief 类单一实例 */
    SINGLETON(RoleManager)

    static RoleManager *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        //  在这里返回你的单例实例
        //  比如使用静态局;部变量实现经典的单例模式
        return instance();
    }

    /// 获取所有模块定义（含 key、name、actions），供 QML 构建 UI 使用
    /// 返回格式: [{key:"customers", name:"客户管理", actions:["read",...]}, ...]
    Q_INVOKABLE static QJsonArray getModuleDefines();

    /**
     *@brief 读取所有角色
     *@return QList<QVariantMap>格式
     */
    Q_INVOKABLE static QList<QVariantMap> getRoles();

    /** @brief 通过字段名查找角色 */
    Q_INVOKABLE static QVariantMap findRole(const QVariantMap &data);

    /**
     *@brief 新增角色
     *@param[in] data:QVariantMap格式角色信息
     *@return 0:失败;>0:样本id
     */
    Q_INVOKABLE static quint64 appendRole(const QVariantMap &data);

    /** @brief 检查角色名称是否存在
     *@return 0:不存在；!=0:存在
     */
    Q_INVOKABLE static int roleNameExisted(const QString &roleName, bool isUpdate);

    /** @brief 通过字段名查找角色
     *@return 0:成功；!=0:失败
     */
    Q_INVOKABLE static int updateRole(const QVariantMap &data, const QVariantMap &condData);

    /** @brief 删除角色
     *@return 0:成功；!=0:失败
     */
    Q_INVOKABLE static int deleteRoles(const QStringList &idlist);

    static QMap<QString, QSet<QString>> loadPermissions(const QString &roleName);

  signals:
    /**
     * @brief 发送消息到消息中心
     * @param info 错误信息或提示信息
     * @param type 信息类型 (Toast/Confirmation)，默认为 Toast
     * @param code 错误码，默认为 NoError
     */
    void messageEmitted(const MessageInfo &msg);

  private:
    static inline const QString m_tableName = "roles";
    /** @brief 字段常量访问 */
    static inline const QString m_fieldId = "id";
    static inline const QString m_fieldName = "name";
    static inline const QString m_fieldPrems = "permissions";
    static inline const QString m_fieldDesc = "description";
    static inline const QString m_fieldStatus = "status";
    static inline const QString m_fieldCreateTime = "create_at";

    /** @brief 各模块支持的权限动作定义 */
    static inline QMap<QString, QStringList> m_moduleDefines = {{PermModule::DataDict, {PermAction::Read, PermAction::Write, PermAction::Delete}}, {PermModule::MessageCenter, {PermAction::Read, PermAction::Write, PermAction::Delete}}, {PermModule::Patients, {PermAction::Read, PermAction::Write, PermAction::Delete, PermAction::Review, PermAction::Print, PermAction::Export}}, {PermModule::Preferences, {PermAction::Read, PermAction::Write}}, {PermModule::Report, {PermAction::Write, PermAction::Print, PermAction::Export}}, {PermModule::RoleManager, {PermAction::Read, PermAction::Write, PermAction::Delete}}, {PermModule::UserInfo, {PermAction::Read, PermAction::Write, PermAction::Delete}}};
};
