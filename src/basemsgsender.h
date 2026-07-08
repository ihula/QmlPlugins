#ifndef BASEMSGSENDER_H
#define BASEMSGSENDER_H

#include <QObject>
#include <QQmlContext>
#include <QtQml>
#include "common.h"


class BaseMsgSender : public QObject
{
    Q_OBJECT
public:
    explicit BaseMsgSender(QObject *parent = nullptr);

    BaseMsgSender(QQmlContext *ctx, const QString &name, QObject *parent = nullptr);

    ~BaseMsgSender();

    /**
    * @brief 向 QML 注册类
    * @tparam ctx QQmlApplicationEngine::rootContext()
    * @param name 注册模块名
    */
    void setQmlContext(QQmlContext *ctx, const QString &name);

signals:
    /**
    * @brief 发送消息到信息中心
    * @param info 错误信息或提示信息
    * @param type 信息类型 (Toast/Confirmation)，默认为 Toast
    * @param code 错误码，默认为 NoError
    */
    void messageEmitted(const MessageInfo &msg);
};

#endif // BASEMSGSENDER_H
