#include "hulalogger.h"
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QIODevice>
#include <QMutex>
#include <QMutexLocker>
#include <QString>
#include <iostream>

HulaLogger::HulaLogger(QObject *parent) : QObject(parent), m_isInitialized(false)
{
    QString defaultDir = QGuiApplication::applicationDirPath() + QString(DEFAULT_LOG_SUBDIR);
    m_config.directory = defaultDir;

    QDir dir(defaultDir);
    if (!dir.exists())
    {
        dir.mkpath(defaultDir);
    }
}

HulaLogger::~HulaLogger()
{
    QMutexLocker locker(&m_fileMutex);
    if (m_logFile.isOpen())
    {
        m_logFile.close();
    }
}

void HulaLogger::initialize(const LoggerConfig &config)
{
    QMutexLocker locker(&m_fileMutex);

    m_config = config;

    if (m_config.directory.isEmpty())
    {
        m_config.directory = QGuiApplication::applicationDirPath() + QString(DEFAULT_LOG_SUBDIR);
    }

    QDir dir(m_config.directory);
    if (!dir.exists())
    {
        dir.mkpath(m_config.directory);
    }

    m_isInitialized = true;
    locker.unlock();

    cleanExpiredLogs();

    QString initMsg = QString("Logger initialized with level: %1, dir: %2").arg(static_cast<int>(m_config.level)).arg(m_config.directory);

    if (m_config.enableConsoleOutput)
    {
        std::cout << "[Logger] " << initMsg.toStdString() << std::endl;
    }

    qInstallMessageHandler([](QtMsgType type, const QMessageLogContext &context, const QString &msg) { HulaLogger::instance()->writeLog(type, msg, context); });
}

void HulaLogger::initialize(QtMsgType level, const QString &directory, int maxFileSizeMB, int maxDaysToKeep)
{
    LoggerConfig config;
    config.level = level;
    config.directory = directory;
    config.maxFileSizeKB = maxFileSizeMB * 1024;
    config.maxRetentionDays = maxDaysToKeep;

    initialize(config);
}

QtMsgType HulaLogger::logLevel() const
{
    return m_config.level;
}

void HulaLogger::setLogLevel(QtMsgType level)
{
    QMutexLocker locker(&m_fileMutex);
    if (m_config.level != level)
    {
        m_config.level = level;
    }
    QString msg = QString("Logger set level: %1").arg(static_cast<int>(m_config.level));

    if (m_config.enableConsoleOutput)
    {
        std::cout << "[Logger] " << msg.toStdString() << std::endl;
    }
}

QString HulaLogger::logDirectory() const
{
    return m_config.directory;
}

void HulaLogger::setLogDirectory(const QString &directory)
{
    QMutexLocker locker(&m_fileMutex);

    if (m_config.directory != directory)
    {
        m_config.directory = directory;

        QDir dir(m_config.directory);
        if (!dir.exists())
        {
            dir.mkpath(m_config.directory);
        }

        if (m_logFile.isOpen())
        {
            m_logFile.close();
        }
        m_currentFilePath.clear();
    }
}

QString HulaLogger::buildMessageHeader(QtMsgType level, const QMessageLogContext &context) const
{
#ifdef QT_DEBUG
#else
    Q_UNUSED(context)
#endif

    QString levelStr = levelToString(level);
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");

#ifdef QT_DEBUG
    return QString(LOG_MESSAGE_FORMAT_DEBUG).arg(levelStr, timestamp, QString(context.file).split("/").last(), QString::number(context.line), QString(context.function));
#else
    return QString(LOG_MESSAGE_FORMAT_RELEASE).arg(levelStr, timestamp);
#endif
}

void HulaLogger::writeLog(QtMsgType level, const QString &message, const QMessageLogContext &context)
{
    if (message.isEmpty())
    {
        return;
    }

    if (level < m_config.level)
    {
        return;
    }

    QString header = buildMessageHeader(level, context);

    QMutexLocker locker(&m_fileMutex);

    checkRotationInternal();

    if (!m_logFile.isOpen())
    {
        openFileInternal();
        if (!m_logFile.isOpen())
        {
            return;
        }
    }

    QString fullMessage = header + " " + message;
    m_textStream << fullMessage << Qt::endl;
    m_textStream.flush();

    locker.unlock();

    if (m_config.enableConsoleOutput)
    {
        std::cout << fullMessage.toStdString() << std::endl;
    }
}

void HulaLogger::rotateInternal()
{
    if (m_logFile.isOpen())
    {
        m_logFile.close();
    }

    QString basePath = generateFilePath();
    QString baseFileName = QFileInfo(basePath).fileName();

    QDir logDir(m_config.directory);
    QStringList filters;
    filters << baseFileName + ".*";
    logDir.setNameFilters(filters);
    QStringList existingBackups = logDir.entryList();

    int maxCounter = 0;
    const QStringList &backupsRef = existingBackups;
    for (int i = 0; i < backupsRef.size(); ++i)
    {
        const QString &backup = backupsRef.at(i);
        QString suffix = backup.mid(baseFileName.length() + 1);
        bool ok;
        int counter = suffix.toInt(&ok);
        if (ok && counter > maxCounter)
        {
            maxCounter = counter;
        }
    }

    QString backupPath = basePath + "." + QString::number(maxCounter + 1);

    if (!m_currentFilePath.isEmpty() && QFile::exists(m_currentFilePath))
    {
        QFile::rename(m_currentFilePath, backupPath);
    }

    m_currentFilePath.clear();
    openFileInternal();
}

void HulaLogger::triggerRotation()
{
    QMutexLocker locker(&m_fileMutex);
    rotateInternal();
}

void HulaLogger::checkRotationInternal()
{
    if (m_logFile.isOpen())
    {
        qint64 currentSize = m_logFile.size();
        qint64 maxSize = m_config.maxFileSizeKB * 1024;

        if (currentSize >= maxSize)
        {
            rotateInternal();
            return;
        }
    }

    QString expectedFilePath = generateFilePath();
    if (m_currentFilePath != expectedFilePath)
    {
        rotateInternal();
    }
}

void HulaLogger::cleanExpiredLogs()
{
    QMutexLocker locker(&m_fileMutex);

    QDir dir(m_config.directory);
    if (!dir.exists())
    {
        return;
    }

    QDateTime expireTime = QDateTime::currentDateTime().addDays(-m_config.maxRetentionDays);

    QStringList filters;
    filters << "*" << QString(LOG_FILE_SUFFIX) << "*" << QString(LOG_FILE_SUFFIX) << ".*";
    dir.setNameFilters(filters);

    QFileInfoList files = dir.entryInfoList(QDir::Files);

    const QFileInfoList &filesRef = files;
    for (int i = 0; i < filesRef.size(); ++i)
    {
        const QFileInfo &fileInfo = filesRef.at(i);
        if (fileInfo.lastModified() < expireTime && fileInfo.filePath() != m_currentFilePath)
        {
            dir.remove(fileInfo.fileName());
        }
    }
}

QString HulaLogger::generateFilePath() const
{
    return m_config.directory + QDate::currentDate().toString(QString(LOG_DATE_FORMAT)) + QString(LOG_FILE_SUFFIX);
}

bool HulaLogger::openFileInternal()
{
    m_currentFilePath = generateFilePath();

    m_logFile.setFileName(m_currentFilePath);
    bool opened = m_logFile.open(QIODevice::Text | QIODevice::WriteOnly | QIODevice::Append);

    if (opened)
    {
        m_textStream.setDevice(&m_logFile);
    }
    else
    {
        std::cerr << "[Logger] Failed to open log file: " << m_currentFilePath.toStdString() << ", error: " << m_logFile.errorString().toStdString() << std::endl;
    }

    return opened;
}

QString HulaLogger::levelToString(QtMsgType level) const
{
    switch (level)
    {
    case QtFatalMsg:
        return "Fatal";
    case QtCriticalMsg:
        return "Critical";
    case QtWarningMsg:
        return "Warning";
    case QtInfoMsg:
        return "Info";
    case QtDebugMsg:
        return "Debug";
    default:
        return "Unknown";
    }
}
