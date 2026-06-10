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
** Brief: 日志类 - 优化版
** History:
**   2024.XX.XX: 重构为面向对象设计，添加日志轮转、级别控制、线程安全
****************************************************************************/

#ifndef HULALOGGER_H
#define HULALOGGER_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QMutex>
#include <QDateTime>

/**
 * @brief 日志级别枚举
 */
enum class LogLevel {
    Fatal = 0,
    Critical,
    Warning,
    Info,
    Debug
};

Q_DECLARE_METATYPE(LogLevel)

/**
 * @brief 日志系统类
 * 
 * 优化特性：
 * 1. 面向对象设计，避免全局变量
 * 2. 支持日志轮转（按大小和日期）
 * 3. 线程安全的日志写入
 * 4. 灵活的日志级别控制
 * 5. 支持调试和发布模式
 * 6. 自动清理过期日志
 */
class HulaLogger : public QObject {
    Q_OBJECT
    Q_PROPERTY(LogLevel logLevel READ logLevel WRITE setLogLevel NOTIFY logLevelChanged)
    Q_PROPERTY(QString logDir READ logDir WRITE setLogDir NOTIFY logDirChanged)

public:
    /**
     * @brief 获取单例实例
     */
    static HulaLogger* instance();

    /**
     * @brief 初始化日志系统
     * @param level 日志级别
     * @param logDir 日志目录（默认为应用程序目录下的Log文件夹）
     * @param maxFileSizeMB 单个日志文件最大大小（MB），默认10MB
     * @param maxDaysToKeep 日志保留天数，默认30天
     */
    Q_INVOKABLE void init(LogLevel level = LogLevel::Debug, 
                          const QString& logDir = QString(),
                          int maxFileSizeMB = 10,
                          int maxDaysToKeep = 30);

    /**
     * @brief 获取当前日志级别
     */
    LogLevel logLevel() const;

    /**
     * @brief 设置日志级别
     */
    Q_INVOKABLE void setLogLevel(LogLevel level);

    /**
     * @brief 获取日志目录
     */
    QString logDir() const;

    /**
     * @brief 设置日志目录
     */
    Q_INVOKABLE void setLogDir(const QString& dir);

    /**
     * @brief 写入日志消息
     */
    void log(QtMsgType type, const QString& msg, const QMessageLogContext& context);

    /**
     * @brief 手动触发日志轮转
     */
    Q_INVOKABLE void rotateLog();

    /**
     * @brief 清理过期日志文件
     */
    Q_INVOKABLE void cleanupOldLogs();

signals:
    void logLevelChanged(LogLevel level);
    void logDirChanged(const QString& dir);
    void logWritten(const QString& message);

private:
    explicit HulaLogger(QObject* parent = nullptr);
    ~HulaLogger() override;

    /**
     * @brief 生成日志文件名
     */
    QString generateLogFileName() const;

    /**
     * @brief 检查并执行日志轮转
     */
    void checkAndRotateLog();

    /**
     * @brief 打开日志文件（带锁保护）
     */
    bool openLogFile();

    /**
     * @brief 打开日志文件（内部版本，假设已持有锁）
     */
    bool openLogFileInternal();

    /**
     * @brief 获取日志级别对应的字符串
     */
    QString levelToString(LogLevel level) const;

    /**
     * @brief 获取Qt消息类型对应的日志级别
     */
    LogLevel qtMsgTypeToLevel(QtMsgType type) const;

    // 单例相关
    static HulaLogger* s_instance;
    static QMutex s_instanceMutex;

    // 配置参数
    QString m_logDir;
    QString m_currentFileName;
    LogLevel m_logLevel;
    int m_maxFileSizeMB;      // 单个文件最大大小（MB）
    int m_maxDaysToKeep;      // 日志保留天数

    // 文件操作相关
    QFile m_file;
    QTextStream m_textStream;
    QMutex m_fileMutex;

    // 禁止拷贝和移动
    HulaLogger(const HulaLogger&) = delete;
    HulaLogger& operator=(const HulaLogger&) = delete;
    HulaLogger(HulaLogger&&) = delete;
    HulaLogger& operator=(HulaLogger&&) = delete;
};

/**
 * @brief 全局日志初始化函数（保持向后兼容）
 */
void logInit(int type);

#endif // HULALOGGER_H
