#include "common.h"
#include "configer.h"
#include "dbmanager.h"
#include "hulalogger.h"
#include "singleappwatcher.h"
#include "translater.h"
#include "utils.h"
#include <QDebug>
#include <QFont>
#include <QGuiApplication>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    // 强制 Qt 使用 XCB (X11) 协议，解决 Wayland 下窗口无法移动的问题
    qputenv("QT_QPA_PLATFORM", "xcb");

    QGuiApplication app(argc, argv);

    // 必须设置这两项，否则 Settings 无法确定存储路径
    app.setOrganizationName("Hula");
    app.setApplicationName("CE");

    // 先初始化日志系统
    HulaLogger::instance()->initialize(LogLevel::Debug); // 使用默认级别
    // 然后再初始化其他模块
    LogLevel level = static_cast<LogLevel>(Configer::instance()->logLevel());
    HulaLogger::instance()->initialize(level);

#if (DEPLOY_MODE)
    Utils::syncDir("../resources/Images", "./Images");
    Utils::syncDir("../resources/Languages", "./Languages");
    Utils::syncDir("../resources/Splash", "./Splash");
    Utils::syncDir("../resources/wallpaper", "./wallpaper");
    Utils::syncFile("../resources/anydata.db", "./anydata.db");
    Utils::syncFile("../resources/Config.ini", "./Config.ini");
#endif
    const QString SERVER_NAME = "com.hula.QmlPlugins";
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
    engine.loadFromModule(APP_URI, "Main");

    return app.exec();
}
