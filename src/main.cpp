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

    // 注册 MetaType，确保跨线程信号/槽可以正确传递自定义类型
    qRegisterMetaType<MessageInfo>("MessageInfo");

#if 0
    // 启用全局抗锯齿
    QQuickWindow::setDefaultAlphaBuffer(true);
    QSurfaceFormat format = QSurfaceFormat::defaultFormat();
    // 设置8倍多重采样抗锯齿
    format.setSamples(8);
    QSurfaceFormat::setDefaultFormat(format);
#endif

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

#ifdef DEPLOY_MODE
    engine.addImportPath(app.applicationDirPath() + "/qml");
#else
    QString buildPath = QCoreApplication::applicationDirPath();
    int binIdx = buildPath.lastIndexOf("/bin");
    if (binIdx > 0) {
        QString projectPath = buildPath.left(binIdx);
        engine.addImportPath(projectPath + "/build/Desktop_Qt_6_7_3-Debug");
    }
#endif

    StatusCode dbResult = DbManager::instance()->connectDb(DB_FILE);
    if (dbResult != StatusCode::Success)
    {
        qCritical() << "Failed to create database connection, error code:" << static_cast<int>(dbResult);
        return -1;
    }

    QString currLang = Configer::instance()->language();
    Translater::instance()->initialize("Languages/", engine.rootContext());
    Translater::instance()->setLanguage(currLang);
    app.setApplicationDisplayName(Translater::instance()->trans("AppName"));

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

    // 找到主窗口并在收到激活信号时唤起它
    QObject::connect(&appWatcher, &SingleAppWatcher::activateRequested, [&engine]() {
        auto rootObjects = engine.rootObjects();
        if (rootObjects.length() == 0)
            return;

        QObject *rootObj = rootObjects.first();
        QQuickWindow *window = rootObj->findChild<QQuickWindow *>("mainForm");
        if (window)
        {
            Qt::WindowFlags flags = window->flags();
            window->setFlags(window->flags() | Qt::WindowStaysOnTopHint);
            if (window->windowState() & Qt::WindowMinimized)
            {
                window->showNormal();
            }
            window->raise();
            window->requestActivate();
            window->setFlags(flags);
        }
        else
        {
            qDebug() << "未找到名为 mainForm 的窗口！";
        }
    });

    return app.exec();
}
