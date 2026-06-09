#include "baseinfosender.h"
#include "infocenter.h"
#include <QDebug>

BaseInfoSender::BaseInfoSender(QObject *parent)
    : QObject{parent}
{
    InfoCenter::connectRecv(this);
    //connect(this, &BaseInfoSender::sendInfo, InfoCenter::instance(), &InfoCenter::receiveInfo);
}

BaseInfoSender::BaseInfoSender(QQmlContext *ctx, const QString &name, QObject *parent)
    : QObject{parent}
{
    setQmlContext(ctx, name);
}

BaseInfoSender::~BaseInfoSender()
{
    InfoCenter::disconnectRecv(this);
}

void BaseInfoSender::setQmlContext(QQmlContext *ctx, const QString &name)
{
    ctx->setContextProperty(name, this);
}
