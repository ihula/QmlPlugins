#include "basemsgsender.h"
#include "messagecenter.h"
#include <QDebug>

BaseMsgSender::BaseMsgSender(QObject *parent)
    : QObject{parent}
{
    MessageCenter::connectRecv(this);
    //connect(this, &BaseMsgSender::sendInfo, MessageCenter::instance(), &MessageCenter::receiveInfo);
}

BaseMsgSender::BaseMsgSender(QQmlContext *ctx, const QString &name, QObject *parent)
    : QObject{parent}
{
    setQmlContext(ctx, name);
}

BaseMsgSender::~BaseMsgSender()
{
    MessageCenter::disconnectRecv(this);
}

void BaseMsgSender::setQmlContext(QQmlContext *ctx, const QString &name)
{
    ctx->setContextProperty(name, this);
}
