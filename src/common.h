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
** Brief: 全局错误码定义
** History:
**   2022.9.25 - 初始版本，定义全局错误码枚举
**   2022.xx.xx - 分离成功状态，添加错误类型枚举和错误信息结构体
****************************************************************************/
#ifndef ERRORS_H
#define ERRORS_H

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

namespace Enums
{
Q_NAMESPACE
QML_ELEMENT

/**
 * @brief 提示类型枚举
 */
enum class PromptType
{
    Toast,        ///< 提示，不记录：轻量级反馈，自动消失
    Log,          ///< 不提示，仅记录
    Confirmation, ///< 确认并记录（弹窗）：模态对话框，提示用户
    Error         ///< 错误并记录（弹窗）：模态对话框，警告用户
};

/**
 * @brief 设备状态枚举
 */
enum class DeviceStatus
{
    Disconnected, ///< 断开：设备未连接
    Connected,    ///< 已连接：设备已连接
    Aging,        ///< 老化：设备老化测试中
    Debugging,    ///< 调试：设备调试中
    Standby,      ///< 待机：设备待机状态
    Running,      ///< 运行中：设备正常运行
    Paused,       ///< 暂停：设备主动暂停运行，可恢复
    Completed,    ///< 完成：任务已完成
    Interrupted,  ///< 中断：任务被异常中断，可恢复
    Faulted,      ///< 停止：停止设备运行，发生了无法恢复的严重错误
};

/**
 * @brief 全局状态码枚举
 *
 * 状态码分配规则：
 * - 0: 成功
 * - 1-999: 通用错误
 * - 1000-1099: 参数错误
 * - 1200-1299: 数据库模块错误
 * - 1300-1399: 网络模块错误
 * - 1400-1499: 文件操作错误
 * - 1500-1599: 配置模块错误
 * - 1600-1699: 业务逻辑错误
 * - 2000-2999: 外部依赖错误
 */
enum class StatusCode
{
    NoError = 0,        ///< 无错误
    Success = 0,        ///< 成功
    UnknownError = 1,   ///< 未知错误
    NotImplemented = 2, ///< 未实现

    // 参数错误 (1000-1099)
    InvalidParameter = 1001,    ///< 参数无效
    ParameterMissing = 1002,    ///< 参数缺失
    ParameterOutOfRange = 1003, ///< 参数超出范围
    InvalidFormat = 1004,       ///< 格式无效

    TypeConvFailed = 1101, ///< 格式转换失败

    // 数据库模块错误 (1200-1299)
    DbOpenFailed = 1201,     ///< 数据库打开失败
    DbBackupFailed = 1202,   ///< 数据库备份失败
    DbRecoverFailed = 1203,  ///< 数据库恢复失败
    DbExecuteFailed = 1204,  ///< 数据库执行失败
    DbConnectionLost = 1205, ///< 数据库连接丢失
    DbTableNotFound = 1206,  ///< 表不存在
    DbRecordNotFound = 1207, ///< 记录不存在
    DbDuplicateKey = 1208,   ///< 主键冲突

    // 网络模块错误 (1300-1399)
    NetworkError = 1301,       ///< 网络错误
    ConnectionTimeout = 1302,  ///< 连接超时
    ConnectionRefused = 1303,  ///< 连接被拒绝
    HostNotFound = 1304,       ///< 主机未找到
    SSLHandshakeFailed = 1305, ///< SSL握手失败

    // 文件操作错误 (1400-1499)
    FileNotFound = 1401,         ///< 文件不存在
    FileReadFailed = 1402,       ///< 文件读取失败
    FileWriteFailed = 1403,      ///< 文件写入失败
    FilePermissionDenied = 1404, ///< 文件权限不足
    FileExists = 1405,           ///< 文件已存在
    FileSizeExceeded = 1406,     ///< 文件大小超限

    // 配置模块错误 (1500-1599)
    ConfigNotFound = 1501,    ///< 配置文件不存在
    ConfigParseFailed = 1502, ///< 配置解析失败
    ConfigInvalid = 1503,     ///< 配置无效

    // 业务逻辑错误 (1600-1699)
    BusinessError = 1601,       ///< 业务逻辑错误
    InvalidState = 1602,        ///< 无效状态
    OperationNotAllowed = 1603, ///< 操作不允许
    ResourceBusy = 1604,        ///< 资源忙
    QuotaExceeded = 1605,       ///< 配额超限

    // 外部依赖错误 (2000-2999)
    ExternalServiceError = 2001, ///< 外部服务错误
    AuthenticationFailed = 2002, ///< 认证失败
    AuthorizationFailed = 2003,  ///< 授权失败
    RateLimitExceeded = 2004,    ///< 请求频率超限
};

Q_ENUM_NS(PromptType)
Q_ENUM_NS(DeviceStatus)
Q_ENUM_NS(StatusCode)
} // namespace Enums

using Enums::DeviceStatus;
using Enums::PromptType;
using Enums::StatusCode;

Q_DECLARE_METATYPE(Enums::PromptType)
Q_DECLARE_METATYPE(Enums::DeviceStatus)
Q_DECLARE_METATYPE(Enums::StatusCode)

/**
 * @brief 消息信息结构体
 */
struct MessageInfo
{
    Q_GADGET
    Q_PROPERTY(QString text MEMBER text)
    Q_PROPERTY(int statusCode READ getStatusCode)
    Q_PROPERTY(int promptType READ getPromptType)
  public:
    QString text;                 ///< 信息
    Enums::StatusCode statusCode; ///< 状态码
    Enums::PromptType promptType; ///< 提示类型

    int getStatusCode() const
    {
        return static_cast<int>(statusCode);
    }
    int getPromptType() const
    {
        return static_cast<int>(promptType);
    }

    /**
     * @brief 构造函数
     */
    MessageInfo() : text(""), statusCode(Enums::StatusCode::UnknownError), promptType(Enums::PromptType::Error)
    {
    }

    /**
     * @brief 构造函数
     * @param t 信息类型
     * @param s 状态码
     * @param msg 信息
     */
    MessageInfo(const QString &msg, Enums::StatusCode s, Enums::PromptType t = Enums::PromptType::Error) : text(msg), statusCode(s), promptType(t)
    {
    }

    /**
     * @brief 判断是否为错误（非成功状态）
     */
    bool isError() const
    {
        return statusCode != StatusCode::Success;
    }
};

Q_DECLARE_METATYPE(MessageInfo)

#endif // ERRORS_H
