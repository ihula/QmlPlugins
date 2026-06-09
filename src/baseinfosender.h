#ifndef BASEINFOSENDER_H
#define BASEINFOSENDER_H

#include <QObject>
#include <QQmlContext>
#include <QtQml>


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
    *@brief 发送错误信息/提示信息到信息中心
    *@param[in] num:错误信息号,>0:保存并转发弹窗提示;
                -1:表示非错误信息,仅用于转发弹窗提示;
                0:仅用于转发浮窗提示
    *@param[in] text:错误信息或提示信息
    */
    void sendInfo(int num, QString info);
};

#endif // BASEINFOSENDER_H
