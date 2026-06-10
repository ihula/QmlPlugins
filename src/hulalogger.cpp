#include "hulalogger.h"
#include <QString>
#include <QLoggingCategory>
#include <QIODevice>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QDateTime>
#include <QMutex>
#include <QMutexLocker>
#include <QGuiApplication>
#include <QFileInfo>
#ifdef QT_DEBUG
#include <iostream>
#endif

// 静态成员初始化
HulaLogger* HulaLogger::s_instance = nullptr;
QMutex HulaLogger::s_instanceMutex;

// ========== HulaLogger 实现 ==========

HulaLogger::HulaLogger(QObject* parent) 
    : QObject(parent),
      m_logLevel(LogLevel::Debug),
      m_maxFileSizeMB(10),
      m_maxDaysToKeep(30)
{
}

HulaLogger::~HulaLogger() {
    if (m_file.isOpen()) {
        m_file.close();
    }
}

HulaLogger* HulaLogger::instance() {
    QMutexLocker locker(&s_instanceMutex);
    if (!s_instance) {
        s_instance = new HulaLogger();
    }
    return s_instance;
}

void HulaLogger::init(LogLevel level, const QString& logDir, int maxFileSizeMB, int maxDaysToKeep) {
    m_logLevel = level;
    m_maxFileSizeMB = maxFileSizeMB;
    m_maxDaysToKeep = maxDaysToKeep;

    // 设置日志目录
    if (logDir.isEmpty()) {
        m_logDir = QGuiApplication::applicationDirPath() + "/Log/";
    } else {
        m_logDir = logDir;
    }

    // 确保日志目录存在
    QDir dir(m_logDir);
    if (!dir.exists()) {
        dir.mkpath(m_logDir);
    }

    // 清理过期日志
    cleanupOldLogs();

    // 先记录初始化信息到控制台（在安装消息处理器之前）
    QString initMsg = QString("Logger initialized with level: %1, dir: %2")
                          .arg(static_cast<int>(level)).arg(m_logDir);
    
    // 使用 std::cout 避免触发 Qt 消息系统
#ifdef QT_DEBUG
    std::cout << "[Logger] " << initMsg.toStdString() << std::endl;
#endif

    // 安装消息处理器
    qInstallMessageHandler([](QtMsgType type, const QMessageLogContext& context, const QString& msg) {
        HulaLogger::instance()->log(type, msg, context);
    });
}

LogLevel HulaLogger::logLevel() const {
    return m_logLevel;
}

void HulaLogger::setLogLevel(LogLevel level) {
    if (m_logLevel != level) {
        m_logLevel = level;
        emit logLevelChanged(level);
        // 注意：不要使用 qDebug()，会导致递归调用
    }
}

QString HulaLogger::logDir() const {
    return m_logDir;
}

void HulaLogger::setLogDir(const QString& dir) {
    if (m_logDir != dir) {
        m_logDir = dir;
        
        // 确保新目录存在
        QDir d(m_logDir);
        if (!d.exists()) {
            d.mkpath(m_logDir);
        }
        
        // 关闭当前文件，下次写入时会使用新目录
        if (m_file.isOpen()) {
            m_file.close();
        }
        m_currentFileName.clear();
        
        emit logDirChanged(dir);
        // 注意：不要使用 qDebug()，会导致递归调用
    }
}

void HulaLogger::log(QtMsgType type, const QString& msg, const QMessageLogContext& context) {
    // 检查空消息
    if (msg.isEmpty()) {
        return;
    }

    // 检查日志级别
    LogLevel msgLevel = qtMsgTypeToLevel(type);
    if (msgLevel > m_logLevel) {
        return; // 低于当前级别，不记录
    }

    // 构建日志消息
    QString text;
    QString levelStr = levelToString(msgLevel);
    
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");
    
#ifdef QT_DEBUG
    // 调试模式：包含详细信息
    text = QString("[%1] [%2] [%3:%4] [%5]").arg(
        levelStr,
        timestamp,
        QString(context.file).split("/").last(),
        QString::number(context.line),
        QString(context.function)
    );
#else
    // 发布模式：简化格式
    text = QString("[%1] [%2]").arg(levelStr, timestamp);
#endif

    // 检查日志轮转（内部已处理线程安全）
    checkAndRotateLog();
    
    // 确保文件已打开（内部已处理线程安全）
    {
        QMutexLocker locker(&m_fileMutex);
        if (!m_file.isOpen()) {
            // 不要在此调用 openLogFile()，避免死锁
            return;
        }

        // 写入日志
        m_textStream << text << " " << msg << Qt::endl;
        m_textStream.flush();
    }

#ifdef QT_DEBUG
    // 同时输出到控制台
    std::cout << text.toStdString() << " " << msg.toStdString() << std::endl;
#endif

    emit logWritten(text + " " + msg);
}

void HulaLogger::rotateLog() {
    // 检查是否已经持有锁（递归调用时）
    if (m_fileMutex.tryLock()) {
        if (m_file.isOpen()) {
            m_file.close();
        }
        
        // 生成基础文件名
        QString baseName = generateLogFileName();
        
        // 优化：使用目录扫描查找最大序号，避免多次文件系统访问
        QDir logDir(m_logDir);
        QStringList filters;
        filters << QFileInfo(baseName).fileName() + ".*";
        logDir.setNameFilters(filters);
        QStringList existingBackups = logDir.entryList();
        
        int maxCounter = 0;
        for (const QString& backup : existingBackups) {
            // 提取序号部分（文件名.baseName.序号）
            QString suffix = backup.mid(baseName.length() + 1);
            bool ok;
            int counter = suffix.toInt(&ok);
            if (ok && counter > maxCounter) {
                maxCounter = counter;
            }
        }
        
        // 生成新的备份文件名
        QString backupName = baseName + "." + QString::number(maxCounter + 1);
        
        // 如果当前文件存在，重命名为备份文件
        if (!m_currentFileName.isEmpty() && QFile::exists(m_currentFileName)) {
            QFile::rename(m_currentFileName, backupName);
        }
        
        m_currentFileName.clear();
        // 重新打开日志文件
        openLogFileInternal();
        
        m_fileMutex.unlock();
    }
    // 注意：不要使用 qDebug()，会导致递归调用
}

void HulaLogger::cleanupOldLogs() {
    QDir dir(m_logDir);
    if (!dir.exists()) {
        return;
    }

    QDateTime expireTime = QDateTime::currentDateTime().addDays(-m_maxDaysToKeep);
    
    QStringList filters;
    filters << "*.log" << "*.log.*";
    dir.setNameFilters(filters);
    
    QFileInfoList files = dir.entryInfoList(QDir::Files);
    
    for (const QFileInfo& fileInfo : files) {
        if (fileInfo.lastModified() < expireTime) {
            dir.remove(fileInfo.fileName());
            // 注意：不要使用 qDebug()，会导致递归调用
        }
    }
}

QString HulaLogger::generateLogFileName() const {
    return m_logDir + QDate::currentDate().toString("yyyyMMdd") + ".log";
}

void HulaLogger::checkAndRotateLog() {
    // 获取锁保护
    QMutexLocker locker(&m_fileMutex);
    
    // 检查文件大小是否超过限制
    if (m_file.isOpen()) {
        qint64 currentSize = m_file.size();
        qint64 maxSize = m_maxFileSizeMB * 1024 * 1024;
        
        if (currentSize >= maxSize) {
            // 释放锁后再调用 rotateLog()，避免死锁
            locker.unlock();
            rotateLog();
            return;
        }
    }
    
    // 检查日期是否变化
    QString expectedFileName = generateLogFileName();
    if (m_currentFileName != expectedFileName) {
        locker.unlock();
        rotateLog();
    }
}

/**
 * @brief 内部版本：打开日志文件（假设已持有锁）
 */
bool HulaLogger::openLogFileInternal() {
    m_currentFileName = generateLogFileName();
    
    m_file.setFileName(m_currentFileName);
    bool opened = m_file.open(QIODevice::Text | QIODevice::WriteOnly | QIODevice::Append);
    
    if (opened) {
        m_textStream.setDevice(&m_file);
        // Qt 6 中默认使用 UTF-8 编码，无需显式设置
    } else {
        // 使用 std::cerr 输出错误，避免递归
        std::cerr << "[Logger] Failed to open log file: " 
                  << m_currentFileName.toStdString() 
                  << ", error: " << m_file.errorString().toStdString() 
                  << std::endl;
    }
    
    return opened;
}

/**
 * @brief 外部版本：打开日志文件（带锁保护）
 */
bool HulaLogger::openLogFile() {
    QMutexLocker locker(&m_fileMutex);
    return openLogFileInternal();
}

QString HulaLogger::levelToString(LogLevel level) const {
    switch (level) {
    case LogLevel::Fatal: return "Fatal";
    case LogLevel::Critical: return "Critical";
    case LogLevel::Warning: return "Warning";
    case LogLevel::Info: return "Info";
    case LogLevel::Debug: return "Debug";
    default: return "Unknown";
    }
}

LogLevel HulaLogger::qtMsgTypeToLevel(QtMsgType type) const {
    switch (type) {
    case QtFatalMsg: return LogLevel::Fatal;
    case QtCriticalMsg: return LogLevel::Critical;
    case QtWarningMsg: return LogLevel::Warning;
    case QtInfoMsg: return LogLevel::Info;
    case QtDebugMsg: return LogLevel::Debug;
    default: return LogLevel::Debug;
    }
}

// ========== 全局兼容函数 ==========

void logInit(int type) {
    LogLevel level = static_cast<LogLevel>(type);
    HulaLogger::instance()->init(level);
}


