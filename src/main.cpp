#include "common.h"
#include "configer.h"
#include "dbmanager.h"
#include "hulalogger.h"
#include "singleappwatcher.h"
#include "translater.h"
#include "utils.h"
#include <QApplication>
#include <QDebug>
#include <QFont>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    // 强制 Qt 使用 XCB (X11) 协议，解决 Wayland 下窗口无法移动的问题
    qputenv("QT_QPA_PLATFORM", "xcb");

    QApplication app(argc, argv);

    // 先初始化日志系统
    HulaLogger::instance()->initialize(QtMsgType::QtDebugMsg); // 使用默认级别
    // 然后再初始化其他模块
    QtMsgType level = static_cast<QtMsgType>(Configer::instance()->logLevel());
    HulaLogger::instance()->setLogLevel(level);

#if (!DEPLOY_MODE)
    // Utils::syncDir("./", "../resources");
#endif
    const QString SERVER_NAME = "com.hula.HulaPlugins";
    SingleAppWatcher appWatcher(SERVER_NAME);
    // 检测单实例,已有实例，直接退出
    if (appWatcher.checkInstance())
    {
        return 0;
    }

    app.setWindowIcon(QIcon("Images/icon.png"));

    QFont font;
    font.setFamily(Configer::instance()->fontName());
    int fontSize = Configer::instance()->fontSize();
    font.setPixelSize(fontSize > 0 ? fontSize : 18);
    app.setFont(font);

    QQmlApplicationEngine engine;
#ifdef Q_OS_MACOS
    engine.rootContext()->setContextProperty("OS_TYPE", "macos");
#elif defined(Q_OS_WIN) // 修正：使用 Q_OS_WIN 代替 Q_OS_WIN64
    engine.rootContext()->setContextProperty("OS_TYPE", "windows");
#elif defined(Q_OS_LINUX)
    engine.rootContext()->setContextProperty("OS_TYPE", "linux");
#else
    engine.rootContext()->setContextProperty("OS_TYPE", "unknown");
#endif

    engine.rootContext()->setContextProperty("APP_PATH", app.applicationDirPath());
    engine.rootContext()->setContextProperty("CUSTOM_PATH", app.applicationDirPath() + "/Custom/");

    StatusCode dbResult = DbManager::instance()->connect(DB_FILE);
    if (dbResult != StatusCode::Success)
    {
        qCritical() << "Failed to create database connection, error code:" << static_cast<int>(dbResult);
        return -1;
    }

    QString currLang = Configer::instance()->language();
    Translater::instance()->initialize("Languages/", engine.rootContext());
    Translater::instance()->setLanguage(currLang);
    app.setApplicationDisplayName(Translater::instance()->trans("AppName"));

    // 找到主窗口并在收到激活信号时唤起它
    QObject::connect(&appWatcher, &SingleAppWatcher::activateRequested, [&engine]() {
        qDebug() << "appwatcher";
        auto rootObjects = engine.rootObjects();
        if (rootObjects.isEmpty())
            return;
        QQuickWindow *window = qobject_cast<QQuickWindow *>(rootObjects.first());
        if (window)
        {
            window->objectName();
            window->show();
            window->raise();
            window->requestActivate();
        }
    });

    // 响应QML中的关机命令
    QObject::connect(&engine, &QQmlApplicationEngine::exit, [=](int retCode) {
        if (retCode == 100)
        {
            qApp->quit();
#ifdef Q_OS_WIN
            system("shutdown -s -t 0");
#else
            QProcess::startDetached("shutdown", QStringList() << "-h" << "now");
#endif
        }
    });

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.loadFromModule(MODULE_URI, "Main");

    return app.exec();
}
