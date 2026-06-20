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
** Brief: 日志系统类 - 优化版
** History:
**   2024.XX.XX: 重构为面向对象设计，添加日志轮转、级别控制、线程安全
**   2026.06.14: 优化命名规范和类架构
****************************************************************************/

#ifndef HULALOGGER_H
#define HULALOGGER_H

#include "singleton.h"
#include <QFile>
#include <QMutex>
#include <QObject>
#include <QTextStream>

/**
 * @brief 日志系统配置结构体
 */
struct LoggerConfig
{
    QtMsgType level = QtMsgType::QtDebugMsg; // 日志级别
    QString directory = QString();           // 日志目录
    int maxFileSizeKB = 10240;               // 单个文件最大大小（KB），默认10MB
    int maxRetentionDays = 30;               // 日志保留天数
    bool enableConsoleOutput = true;         // 是否输出到控制台
};

/**
 * @brief 日志系统类
 *
 * 核心特性：
 * - 线程安全的日志写入
 * - 支持按大小和日期轮转
 * - 自动清理过期日志
 * - 灵活的日志级别控制
 * - 支持调试和发布模式
 */
class HulaLogger : public QObject
{
    Q_OBJECT

  public:
    SINGLETON(HulaLogger)

    /**
     * @brief 初始化日志系统
     * @param config 日志配置参数
     */
    Q_INVOKABLE void initialize(const LoggerConfig &config = LoggerConfig());

    /**
     * @brief 初始化日志系统（重载，保持向后兼容）
     * @param level 日志级别
     * @param directory 日志目录
     * @param maxFileSizeMB 单个日志文件最大大小（MB）
     * @param maxDaysToKeep 日志保留天数
     */
    Q_INVOKABLE void initialize(QtMsgType level, const QString &directory = QString(), int maxFileSizeMB = 10, int maxDaysToKeep = 30);

    /**
     * @brief 获取当前日志级别
     */
    QtMsgType logLevel() const;

    /**
     * @brief 设置日志级别
     * @param level 新的日志级别
     */
    Q_INVOKABLE void setLogLevel(QtMsgType level);

    /**
     * @brief 获取日志目录
     */
    QString logDirectory() const;

    /**
     * @brief 设置日志目录
     * @param directory 新的日志目录路径
     */
    Q_INVOKABLE void setLogDirectory(const QString &directory);

    /**
     * @brief 写入日志消息
     * @param type Qt消息类型
     * @param message 日志消息内容
     * @param context 日志上下文信息
     */
    void writeLog(QtMsgType level, const QString &message, const QMessageLogContext &context);

    /**
     * @brief 手动触发日志轮转
     */
    Q_INVOKABLE void triggerRotation();

    /**
     * @brief 清理过期日志文件
     */
    Q_INVOKABLE void cleanExpiredLogs();

  private:
    explicit HulaLogger(QObject *parent = nullptr);
    ~HulaLogger() override;

    /**
     * @brief 生成日志文件完整路径
     */
    QString generateFilePath() const;

    /**
     * @brief 检查并执行日志轮转（内部版本，假设已持有锁）
     */
    void checkRotationInternal();

    /**
     * @brief 执行日志轮转（内部版本，假设已持有锁）
     */
    void rotateInternal();

    /**
     * @brief 打开日志文件（内部版本，假设已持有锁）
     * @return 是否成功打开
     */
    bool openFileInternal();

    /**
     * @brief 构建日志消息字符串
     * @param level 日志级别
     * @param context 日志上下文
     * @return 格式化后的日志消息头
     */
    QString buildMessageHeader(QtMsgType level, const QMessageLogContext &context) const;

    /**
     * @brief 将日志级别转换为字符串
     * @param level 日志级别
     * @return 级别对应的字符串
     */
    QString levelToString(QtMsgType level) const;

    // 配置参数
    LoggerConfig m_config;

    // 运行时状态
    QString m_currentFilePath; // 当前日志文件路径
    bool m_isInitialized;      // 是否已初始化

    // 文件操作相关
    QFile m_logFile;          // 日志文件对象
    QTextStream m_textStream; // 文本流
    QMutex m_fileMutex;       // 文件操作互斥锁

    // 常量
    static constexpr const char *DEFAULT_LOG_SUBDIR = "/Log/";
    static constexpr const char *LOG_FILE_SUFFIX = ".log";
    static constexpr const char *LOG_DATE_FORMAT = "yyyyMMdd";
    static constexpr const char *LOG_MESSAGE_FORMAT_DEBUG = "[%1] [%2] [%3:%4] [%5]";
    static constexpr const char *LOG_MESSAGE_FORMAT_RELEASE = "[%1] [%2]";
};

#endif // HULALOGGER_H
