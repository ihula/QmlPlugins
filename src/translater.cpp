#include "translater.h"
#include <QSettings>
#include <QCoreApplication>
#include <QDir>
#include <QLocale>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickView>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonArray>
#include <QWriteLocker>
#include <QReadLocker>


const static auto cChineseStr = "简体中文";

Translater::Translater(QObject* parent)
    : QTranslator(parent)
{
}

void Translater::init(const QString& folder, QQmlContext* ctx)
{
    if (ctx != nullptr)
    {
        m_ctx = ctx;
        ctx->setContextProperty("translater", this);
    }
    if (folder.isEmpty())
        loadFolder("/Languages");
    else
        loadFolder(folder);

    qApp->installTranslator(this);
}

QString Translater::translate(const char* context, const char* sourceText, const char* disambiguation, int n) const
{
    Q_UNUSED(context)
    Q_UNUSED(disambiguation)
    Q_UNUSED(n)

    return trans(sourceText);
}

void Translater::loadFolder(const QString& folder)
{
    m_langFolder = folder;
    QDir dir(m_langFolder);
    const auto infos = dir.entryInfoList({ "*.ini" }, QDir::Files);
    QString lang;
    for (const auto& info : infos)
    {
        load(info.absoluteFilePath());
    }

    // 将<简体中文>放到最前面
    const auto langs = m_map.keys();
    QStringList orderedLangs = langs;
    if (orderedLangs.contains(cChineseStr))
    {
        orderedLangs.removeAll(cChineseStr);
        orderedLangs.push_front(cChineseStr);
    }

    setLanguages(orderedLangs);

    emit folderLoaded(m_langFolder);
}

void Translater::reLoadFolder()
{
    loadFolder(m_langFolder);
}

bool Translater::load(const QString& filePath)
{
    QSettings inifile(filePath, QSettings::IniFormat);
    QString langName = inifile.value("default/Language").toString();
    inifile.beginGroup("Translate");
    QStringList keys = inifile.allKeys();

    QWriteLocker locker(&m_mapLock);
    for (int i = 0; i < keys.size(); i++)
    {
        m_map[langName][keys[i]] = inifile.value(keys[i]).toString();
    }
    locker.unlock();

    emit langLoaded(langName);
    return true;
}

const QString& Translater::currentLang() const
{
    return m_currentLang;
}

const QStringList& Translater::languages() const
{
    return m_languages;
}

const QString& Translater::change() const
{
    return m_transString;
}

QString Translater::trans(const QString& source) const
{
    QReadLocker locker(&m_mapLock);
    auto it = m_map.find(m_currentLang);
    if (it != m_map.end()) {
        auto valIt = it->find(source);
        if (valIt != it->end())
            return *valIt;
    }
    return source;
}

void Translater::setCurrentLang(const QString& currentLang)
{
    if (m_currentLang == currentLang)
        return;

    m_currentLang = currentLang;
    emit currentLangChanged(m_currentLang);

#if QT_VERSION >= QT_VERSION_CHECK(5, 10, 0)
    m_ctx->engine()->retranslate();
#else
    emit changeChanged();
#endif
}

void Translater::setLanguages(const QStringList& languages)
{
    if (m_languages == languages)
        return;

    m_languages = languages;
    emit languagesChanged(m_languages);
}
