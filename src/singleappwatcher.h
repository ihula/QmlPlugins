#ifndef SINGLEAPPWATCHER_H
#define SINGLEAPPWATCHER_H

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QPointer>

class SingleAppWatcher : public QObject
{
    Q_OBJECT
public:
    explicit SingleAppWatcher(const QString &serverName, QObject *parent = nullptr)
        : QObject(parent), m_serverName(serverName) {}

    // 检查是否已有实例运行。返回 true 表示已有实例（当前应退出），false 表示是首个实例。
    bool checkInstance() {
        QLocalSocket socket;
        socket.connectToServer(m_serverName);
        if (socket.waitForConnected(500)) {
            // 已有实例在运行，向它发送激活指令
            socket.write("ACTIVATE");
            socket.waitForBytesWritten();
            return true;
        }

        // 没有实例运行，当前程序作为服务端
        QLocalServer::removeServer(m_serverName);
        m_server = new QLocalServer(this);
        if (m_server->listen(m_serverName))
        {
            connect(m_server, &QLocalServer::newConnection, this, &SingleAppWatcher::handleNewConnection);
            return false;
        }
        return true; // 启动服务端失败，视作已有实例
    }

signals:
    // 当接收到其他实例发来的激活指令时，触发此信号
    void activateRequested();

private slots:
    void handleNewConnection()
    {
        QLocalSocket *client = m_server->nextPendingConnection();
        connect(client, &QLocalSocket::readyRead, this, [=, this]() {
            QByteArray message = client->readAll();
            if (message == "ACTIVATE")
            {
                emit activateRequested(); // 发射信号通知
            }
            client->deleteLater();
        });
    }

private:
    QString m_serverName;
    QPointer<QLocalServer> m_server;
};

#endif // SINGLEAPPWATCHER_H
