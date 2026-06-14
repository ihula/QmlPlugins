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
** Brief: 消息管理类
** History:
****************************************************************************/
#ifndef MESSAGECENTER_H
#define MESSAGECENTER_H

#include "common.h"
#include "configer.h"
#include "singleton.h"
#include <QObject>
#include <QMutex>

class MessageCenter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
private:
    explicit MessageCenter(QObject *parent = nullptr);

public:
    SINGLETON(MessageCenter)

    static MessageCenter *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        return instance();
    }

    Q_INVOKABLE QList<QVariantMap> getDatas(const QString& date = QString());
    Q_INVOKABLE int deleteData(quint64 id);
    Q_INVOKABLE int deleteAllData();
    Q_INVOKABLE bool hasNewInfo();
    Q_INVOKABLE void appendData(const QVariantMap& data);

    template <typename SenderType> 
    static void connectRecv(SenderType *sender, Qt::ConnectionType type = Qt::AutoConnection)
    {
        if (!sender)
            return;
        connect(sender, &SenderType::messageEmitted, MessageCenter::instance(), &MessageCenter::handleMessage, type);
    }

    template <typename SenderType> 
    static void disconnectRecv(SenderType *sender)
    {
        if (!sender)
            return;
        disconnect(sender, &SenderType::messageEmitted, MessageCenter::instance(), &MessageCenter::handleMessage);
    }

public slots:
    Q_INVOKABLE void handleMessage(const MessageInfo &msg);

signals:
    void messageEmitted(MessageInfo msg);

private:
    QString getErrorInfoDir() const;
    QString getCurrentFileName(const QString& date) const;
    int generateNextId(const QString& fileName);

    bool m_hasNewInfo = false;
    QString m_currentDate;
    mutable QMutex m_mutex;
};

#endif // MESSAGECENTER_H
