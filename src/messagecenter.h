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
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QSettings>
#include <QSqlQuery>

class MessageCenter : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
  private:
    explicit MessageCenter(QObject *parent = nullptr);

  public:
    /** @brief 类单一实例 */
    SINGLETON(MessageCenter)

    // 提供一个特定签名的静态 create 方法，QML单例用
    // 参数必须是 QQmlEngine*, QJSEngine*，返回值是 Configer*
    static MessageCenter *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)

        // 在这里返回你的单例实例
        // 比如使用静态局部变量实现经典的单例模式
        return instance();
    }

    /**
     *@brief 获取指定日期的错误信息
     *@param[in] date:选择的日期字符串值(yyyymmdd),空表示当天
     *@retval QJsonArray: 返回所选择日期的错误信息
     */
    Q_INVOKABLE QList<QVariantMap> getDatas(QString date = "");

    /**
     *@brief 删除指定Id的错误信息
     *@param[in] id:错误信息的Id
     *@retval int: 0,删除成功
     */
    Q_INVOKABLE int deleteData(quint64 id);

    /**
     *@brief 删除之前所选日期的所有错误信息
     *@retval int: 0,删除成功
     */
    Q_INVOKABLE int deleteAllData();

    /**
     *@brief 当天是否有新的错误信息
     *@retval bool: true,有错误新信息
     */
    Q_INVOKABLE bool hasNewInfo();

    /**
     *@brief 添加新错误信息
     *@param[in] data:错误信息数据
     */
    Q_INVOKABLE void appendData(QVariantMap data);

    /**
     * @brief 连接具有messageEmitted信号的发送者到MessageCenter的receiveMessage槽 (函数指针语法)
     * @tparam SenderType 发送者类型，必须有messageEmitted(MessageInfo)信号
     * @param sender 发送者对象指针
     * @param connectionType 连接类型，默认为Qt::AutoConnection
     */
    template <typename SenderType> static void connectRecv(SenderType *sender, Qt::ConnectionType type = Qt::AutoConnection)
    {
        if (!sender)
            return;

        // 使用函数指针语法连接信号和槽，提供编译时类型检查
        connect(sender, &SenderType::messageEmitted, MessageCenter::instance(), &MessageCenter::handleMessage, type);
    }

    template <typename SenderType> static void disconnectRecv(SenderType *sender)
    {
        if (!sender)
            return;

        disconnect(sender, &SenderType::messageEmitted, MessageCenter::instance(), &MessageCenter::handleMessage);
    }

  public slots:
    /**
     * @brief 将系统消息保存并转发到UI
     * @param msg 系统消息
     */
    Q_INVOKABLE void handleMessage(const MessageInfo &msg);

  signals:
    /** @brief 发送消息到界面 */
    void messageEmitted(MessageInfo msg);

  private:
    bool m_hasNewInfo;
    QString m_currFileName;
    mutable QMutex m_fileMutex;
};

#endif // MESSAGECENTER_H
