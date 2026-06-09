/****************************************************************************
** C++ for MultiPlatform series
** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
** This work is licensed under the Creative Commons
** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
** @Author: Hula
** @Web: www.123hula.com
** @WeChat: ihula123
** @Contact: benny1225@hotmail.com
** @Date: 2023.10.20
** @Brief: 多语言翻译器
** @History:
****************************************************************************/
#ifndef TRANSLATER_H
#define TRANSLATER_H

#include <QHash>
#include <QList>
#include <QObject>
#include <QString>
#include <QTranslator>
#include <QReadWriteLock>

class QQmlContext;


class Translater: public QTranslator
{
    Q_OBJECT

    Q_PROPERTY(QString currentLang READ currentLang WRITE setCurrentLang NOTIFY currentLangChanged)
    Q_PROPERTY(QStringList languages READ languages NOTIFY languagesChanged)
    Q_PROPERTY(QString change READ change NOTIFY changeChanged)
public:
    Translater(QObject* parent = nullptr);

    /**
    *@brief 加载多语言目录中的多语言信息
    *@param[in] folder:多语言目录名
    */
    Q_INVOKABLE void loadFolder(const QString& folder);

    /** @brief 重新加载多语言目录中的资源 */
    Q_INVOKABLE void reLoadFolder();

    /**
    *@brief 加载语言文件的翻译信息
    *@param[in] lang:语言名
    *@param[in] filePath:语言文件路径
    */
    Q_INVOKABLE bool load(const QString& filePath);

    /**
    *@brief 安装程序翻译器并加载多语言资源
    *@param[in] ctx:安装qml翻译器
    *@param[in] folder:多语言目录
    */
    void init(const QString& folder, QQmlContext* ctx = nullptr);

    QString translate(const char* context, const char* sourceText, const char* disambiguation = nullptr, int n = -1) const override;

    /** @brief 当前语言 */
    const QString& currentLang() const;

    /** @brief 多语言目录中所有语言名称列表 */
    const QStringList& languages() const;

    /** @brief 更换语言时通过此方法的信号来理新语言翻译值 */
    const QString& change() const;

    /** @brief 翻译语言值 */
    QString trans(const QString& source) const;

public slots:
    /** @brief 设置当前语言 */
    void setCurrentLang(const QString& currentLang);

signals:
    void currentLangChanged(const QString& currentLang);

    void languagesChanged(const QStringList& languages);

    void langLoaded(const QString& lang);

    void folderLoaded(const QString& folder);

    /** @brief 更换语言时通过此信号来理新语言翻译值 */
    void changeChanged();

protected:
    void setLanguages(const QStringList& languages);

private:
    QString m_currentLang;

    // <"English", <"key", "value">>
    mutable QReadWriteLock m_mapLock;
    QHash<QString, QHash<QString, QString>> m_map;

    QStringList m_languages;

    QString m_transString;

    QString m_langFolder;

    QQmlContext *m_ctx = nullptr;
};

#endif // TRANSLATER_H


