#ifndef TRANSLATER_H
#define TRANSLATER_H

#include "singleton.h"
#include <QHash>
#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QTranslator>
#include <QtQml>

class QQmlContext;

class Translater : public QTranslator
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY LanguageChanged)
    Q_PROPERTY(QStringList languages READ languages NOTIFY languagesChanged)
    Q_PROPERTY(QString change READ change NOTIFY changeChanged)

  private:
    explicit Translater(QObject *parent = nullptr);

  public:
    SINGLETON(Translater)

    static Translater *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        // Translater *inst = instance();
        // qmlEngine->setObjectOwnership(inst, QQmlEngine::CppOwnership);
        return instance();
    }

    Q_INVOKABLE void loadFolder(const QString &folder);
    Q_INVOKABLE void reLoadFolder();
    Q_INVOKABLE bool load(const QString &filePath);
    Q_INVOKABLE QString debugInstance() const
    {
        return QString::number(reinterpret_cast<qint64>(this), 16);
    }

    void initialize(const QString &folder);

    QString translate(const char *context, const char *sourceText, const char *disambiguation = nullptr, int n = -1) const override;

    const QString &language() const;
    const QStringList &languages() const;
    const QString &change() const;
    QString trans(const QString &source) const;

  public slots:
    void setLanguage(const QString &currentLang);

  signals:
    void LanguageChanged(const QString &currentLang);
    void languagesChanged(const QStringList &languages);
    void langLoaded(const QString &lang);
    void folderLoaded(const QString &folder);
    void changeChanged();

  private:
    void setLanguages(const QStringList &languages);
    QString getAbsoluteFolder(const QString &folder) const;

    static constexpr const char *DEFAULT_CHINESE_LANG = "简体中文";
    static constexpr const char *DEFAULT_LANG_FOLDER = "/Languages";

    QString m_currentLang;
    QHash<QString, QHash<QString, QString>> m_map;
    QStringList m_languages;
    QString m_transString;
    QString m_langFolder;
    QQmlContext *m_ctx = nullptr;
};

#endif // TRANSLATER_H
