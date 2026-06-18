#include "translater.h"
#include <QCoreApplication>
#include <QDir>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QSettings>

Translater::Translater(QObject *parent) : QTranslator(parent)
{
}

QString Translater::getAbsoluteFolder(const QString &folder) const
{
    if (folder.isEmpty())
    {
        return QGuiApplication::applicationDirPath() + DEFAULT_LANG_FOLDER;
    }

    if (QDir::isAbsolutePath(folder))
    {
        return folder;
    }

    return QGuiApplication::applicationDirPath() + "/" + folder;
}

void Translater::initialize(const QString &folder, QQmlContext *ctx)
{
    m_ctx = ctx;
    loadFolder(folder);
    qApp->installTranslator(this);
}

QString Translater::translate(const char *context, const char *sourceText, const char *disambiguation, int n) const
{
    Q_UNUSED(context)
    Q_UNUSED(disambiguation)
    Q_UNUSED(n)
    return trans(sourceText);
}

void Translater::loadFolder(const QString &folder)
{
    m_langFolder = getAbsoluteFolder(folder);
    QDir dir(m_langFolder);

    if (!dir.exists())
    {
        return;
    }

    m_map.clear();
    const QFileInfoList infos = dir.entryInfoList({"*.ini"}, QDir::Files);
    for (const QFileInfo &info : infos)
    {
        load(info.absoluteFilePath());
    }

    const QStringList langs = m_map.keys();
    QStringList orderedLangs = langs;
    if (orderedLangs.contains(DEFAULT_CHINESE_LANG))
    {
        orderedLangs.removeAll(DEFAULT_CHINESE_LANG);
        orderedLangs.push_front(DEFAULT_CHINESE_LANG);
    }
    setLanguages(orderedLangs);
    emit folderLoaded(m_langFolder);
}

void Translater::reLoadFolder()
{
    loadFolder(m_langFolder);
}

bool Translater::load(const QString &filePath)
{
    QSettings inifile(filePath, QSettings::IniFormat);
    QString langName = inifile.value("default/Language").toString();

    if (langName.isEmpty())
    {
        return false;
    }

    inifile.beginGroup("Translate");
    const QStringList keys = inifile.allKeys();
    for (const QString &key : keys)
    {
        m_map[langName][key] = inifile.value(key).toString();
    }

    emit langLoaded(langName);
    return true;
}

const QString &Translater::language() const
{
    return m_currentLang;
}

const QStringList &Translater::languages() const
{
    return m_languages;
}

const QString &Translater::change() const
{
    return m_transString;
}

QString Translater::trans(const QString &source) const
{
    auto it = m_map.find(m_currentLang);
    if (it != m_map.end())
    {
        auto valIt = it->find(source);
        if (valIt != it->end())
        {
            return *valIt;
        }
    }
    return source;
}

void Translater::setLanguage(const QString &currentLang)
{
    if (m_currentLang == currentLang)
    {
        return;
    }

    m_currentLang = currentLang;
    emit languageChanged(m_currentLang);
    // 不需要在QML中使用 qsTr("Mail.Host")
    m_ctx->engine()->retranslate();
    // emit changeChanged();
}

void Translater::setLanguages(const QStringList &languages)
{
    m_languages = languages;
    emit languagesChanged(m_languages);
}