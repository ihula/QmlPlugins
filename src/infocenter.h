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
** Brief: 信息管理类
** History:
****************************************************************************/
#ifndef INFOCENTER_H
#define INFOCENTER_H

#include "singleton.h"
#include "configer.h"
#include "common.h"
#include <QObject>
#include <QSettings>
#include <QJsonObject>
#include <QJsonArray>
#include <QSqlQuery>


class InfoCenter : public QObject
{
    Q_OBJECT
    QML_ELEMENT // 注册到QML
    QML_SINGLETON // QML单例

private:
    explicit InfoCenter(QObject *parent = nullptr);

public:
    /** @brief 类单一实例 */
    SINGLETON(InfoCenter)

    // 提供一个特定签名的静态 create 方法，QML单例用
    // 参数必须是 QQmlEngine*, QJSEngine*，返回值是 Configer*
    static InfoCenter *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine) {
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
    Q_INVOKABLE QJsonArray getDatas(QString date = "");

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
    Q_INVOKABLE void appendData(QJsonObject data);

    /**
    * @brief 连接具有messageEmitted信号的发送者到InfoCenter的receiveMessage槽 (函数指针语法)
    * @tparam SenderType 发送者类型，必须有messageEmitted(InfoType, QString, ErrorCode)信号
    * @param sender 发送者对象指针
    * @param connectionType 连接类型，默认为Qt::AutoConnection
    */
    template<typename SenderType>
    static void connectRecv(SenderType* sender, Qt::ConnectionType type = Qt::AutoConnection)
    {
        if (!sender)
            return;

        // 使用函数指针语法连接信号和槽，提供编译时类型检查
        connect(sender, &SenderType::messageEmitted, InfoCenter::instance(), &InfoCenter::receiveMessage, type);
    }

    template<typename SenderType>
    static void disconnectRecv(SenderType* sender)
    {
        if (!sender)
            return;

        disconnect(sender, &SenderType::messageEmitted, InfoCenter::instance(), &InfoCenter::receiveMessage);
    }

public slots:
    /**
    * @brief 保存错误信息/提示信息
    * @param info 错误信息或提示信息
    * @param type 信息类型 (Toast/Confirmation)，默认为 Toast
    * @param code 错误码，默认为 NoError
    */
    Q_INVOKABLE void receiveMessage(QString info, Enums::InfoType type = Enums::InfoType::Toast, Enums::ErrorCode code = Enums::ErrorCode::NoError);

signals:
    /** @brief 发送提示/错误信息到界面 */
    void messageEmitted(QString info, Enums::InfoType type = Enums::InfoType::Toast, Enums::ErrorCode code = Enums::ErrorCode::NoError);

private:
    bool m_hasNewInfo;
    QString m_currFileName;
    mutable QMutex m_fileMutex;

};

#endif // INFOCENTER_H
