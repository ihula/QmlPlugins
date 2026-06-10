#ifndef BASEINFOSENDER_H
#define BASEINFOSENDER_H

#include <QObject>
#include <QQmlContext>
#include <QtQml>
#include "common.h"


class BaseInfoSender : public QObject
{
    Q_OBJECT
public:
    explicit BaseInfoSender(QObject *parent = nullptr);

    BaseInfoSender(QQmlContext *ctx, const QString &name, QObject *parent = nullptr);

    ~BaseInfoSender();

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
    void messageEmitted(QString info, Enums::InfoType type = Enums::InfoType::Toast, Enums::ErrorCode code = Enums::ErrorCode::NoError);
};

#endif // BASEINFOSENDER_H
