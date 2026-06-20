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
** Brief: 文件配置类
** History:
****************************************************************************/
#ifndef CONFIGER_H
#define CONFIGER_H

#include "singleton.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QQmlEngine>
#include <QVector>
#include <QtQml>

#define APP_NAME "HulaQml"
#define APP_DOMAIN "hula.com"
#define APP_ORG "United Prosperity Studio"
#define APP_VER "1.0.0.0"

#ifdef Q_OS_WIN
#define WIN_OS 1
#endif

#define DEPLOY_WIN 1

#ifdef Q_OS_MACOS // macOS下开发目录
#define PATH_PRE QString("../../../src/")
#elif DEPLOY_WIN // 源码时将每三方库放到目录下
#define PATH_PRE /*QCoreApplication::applicationFilePath()*/
#elif WIN_OS     // windows下开发目录
#define PATH_PRE QString("../src/")
#endif

// Qml使用的图片目录
#define QML_RES_PATH "../Images/"

// Qml使用的保存拍摄图片目录
#define QML_CAP_PATH "Capture/"

// Qml使用的Splash界面图片目录
#define QML_SPLASH_PATH "../Splash/"

// 多语言文件目录
#define LANG_PATH PATH_PRE + "Languages/"

// 主题配置文件目录
#define THEME_PATH PATH_PRE + "Theme/"

// 配置文件
#define CFG_FILE PATH_PRE + "Config.ini"

// 个性化配置文件
#define CFG_CUSTOM_FILE PATH_PRE + "Custom.ini"

// Qt使用的Splash界面图片目录
#define SPLASH_PATH PATH_PRE + "Splash/"

// Qt使用的图片目录
#define RES_PATH PATH_PRE + "Images/"

// 数据库文件
#define DB_FILE PATH_PRE + "anydata.db"

// Qt使用的保存拍摄图片目录
#define CAP_PATH PATH_PRE + "Capture/"

// 默认的报表文件
#ifdef USE_LIMER_RPT // 工程文件中定义
#define REPORT_FILE QString(PATH_PRE) + "Report.lrxml"
#endif

// 配置文件默认组名
#define CFG_ROOT "default"

// 日期格式
#define DATE_FMT "yyyy-MM-dd"

// 时间格式
#define TIME_FMT "yyyy-MM-dd hh:mm:ss"

// 时间毫秒格式
#define TIME_MSEC_FMT "yyyy-MM-dd hh:mm:ss.zzz"

class Configer : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  private:
    explicit Configer(QObject *parent = nullptr);

  public:
    /** @brief 类单一实例 */
    SINGLETON(Configer)

    // 提供一个特定签名的静态 create 方法，QML单例用
    // 参数必须是 QQmlEngine*, QJSEngine*，返回值是 Configer*
    static Configer *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
    {
        Q_UNUSED(qmlEngine)
        Q_UNUSED(jsEngine)
        //  在这里返回你的单例实例
        //  比如使用静态局;部变量实现经典的单例模式
        return instance();
    }

    ~Configer();

    /** @brief 用户名 */
    Q_INVOKABLE QString userName();
    Q_INVOKABLE void setUserName(const QString &userName);

    /** @brief 用户账号 */
    Q_INVOKABLE QString userAccount();
    Q_INVOKABLE void setUserAccount(const QString &userAccount);

    /** @brief 是否启用日志 */
    Q_INVOKABLE int logLevel();
    Q_INVOKABLE void setLogLevel(int level);

    /** @brief 当前使用的语言 */
    Q_INVOKABLE QString language();
    Q_INVOKABLE void setLanguage(const QString &langName);

    /** @brief 字体 */
    Q_INVOKABLE QString fontName();
    Q_INVOKABLE void setFontName(const QString &font);

    /** @brief 字体大小 */
    Q_INVOKABLE int fontSize();
    Q_INVOKABLE void setFontSize(int size);

    /** @brief 软件主题配置文件名 */
    Q_INVOKABLE QString theme();
    Q_INVOKABLE void setTheme(const QString &style);

    /** @brief 加载主题配置为QVariantMap */
    Q_INVOKABLE QVariantMap loadTheme(const QString &themeName);

    /** @brief 保存主题对象到配置文件 */
    Q_INVOKABLE void saveTheme(const QVariantMap &datas, const QString &themeName);

    /** @brief 报警对话框自动关闭时间 */
    Q_INVOKABLE int warnDialogCloseTime();
    Q_INVOKABLE void setWarnDialogCloseTime(int sec);

    /** @brief 是否启用Splash界面 */
    Q_INVOKABLE bool enableSplash();
    Q_INVOKABLE void setEnableSplash(bool sure);

    /** @brief Splash界面显示模式:0=普通,1=最大化,2=全屏 */
    Q_INVOKABLE int splashFormShowMode();
    Q_INVOKABLE void setSplashFormShowMode(int mode);

    /** @brief Splash界面是否显示关闭按钮 */
    Q_INVOKABLE bool splashCanClose();
    Q_INVOKABLE void setSplashCanClose(bool sure);

    /** @brief 是否启用Login界面 */
    Q_INVOKABLE bool enableLogin();
    Q_INVOKABLE void setEnableLogin(bool sure);

    /** @brief login界面显示模式:0=普通,1=最大化,2=全屏 */
    Q_INVOKABLE int loginFormShowMode();
    Q_INVOKABLE void setLoginFormShowMode(int mode);

    /** @brief main界面显示模式:0=普通,1=最大化,2=全屏 */
    Q_INVOKABLE int mainFormShowMode();
    Q_INVOKABLE void setMainFormShowMode(int mode);

    /** @brief 使用程序背景图片 */
    Q_INVOKABLE bool useWallPaper();
    Q_INVOKABLE void setUseWallPaper(bool used);

    /** @brief 使用动态程序背景图片 */
    Q_INVOKABLE bool liveWallPaper();
    Q_INVOKABLE void setLiveWallPaper(bool used);

    /** @brief 文件是否存在 */
    Q_INVOKABLE bool fileExisted(const QString &fileName);

    /** @brief 心跳包时间 */
    Q_INVOKABLE int heartbeatTime();
    Q_INVOKABLE void setHeartbeatTime(int num);

    /** @brief 报表打印前是否预览 */
    Q_INVOKABLE bool reportPreviewed();
    Q_INVOKABLE void setReportPreviewed(bool sure);

    /** @brief 设置报表打印前设计 */
    Q_INVOKABLE bool reportDesigned();
    Q_INVOKABLE void setReportDesigned(bool sure);

    /** @brief 所有报表模板 */
    Q_INVOKABLE QStringList reportTemplateList();

    /** @brief 当前默认报表 */
    Q_INVOKABLE QString reportTemplate();
    Q_INVOKABLE void setReportTemplate(const QString &text);

    // LTSCamera扩展
    /** @brief 报表标题 */
    Q_INVOKABLE QString reportTitel(const QString &reportNo);
    Q_INVOKABLE void setReportTitel(const QString &reportNo, const QString &text);

    /** @brief 报表标题字体颜色 */
    Q_INVOKABLE QString reportTitelColor(const QString &reportNo);
    Q_INVOKABLE void setReportTitelColor(const QString &reportNo, const QString &text);

    /** @brief 报表标题字体大小 */
    Q_INVOKABLE int reportTitelSize(const QString &reportNo);
    Q_INVOKABLE void setReportTitelSize(const QString &reportNo, int size);

    /** @brief 医院名称 */
    Q_INVOKABLE QString hospitalName(const QString &reportNo);
    Q_INVOKABLE void setHospitalName(const QString &reportNo, const QString &text);

    /** @brief 医院名称字体颜色 */
    Q_INVOKABLE QString hospitalNameColor(const QString &reportNo);
    Q_INVOKABLE void setHospitalNameColor(const QString &reportNo, const QString &text);

    /** @brief 医院名称字体大小 */
    Q_INVOKABLE int hospitalNameSize(const QString &reportNo);
    Q_INVOKABLE void setHospitalNameSize(const QString &reportNo, int size);

    /** @brief 医院名称字体颜色 */
    Q_INVOKABLE QString hospitalLogo(const QString &reportNo);
    Q_INVOKABLE void setHospitalLogo(const QString &reportNo, const QString &path);

    /** @brief 图片存储路径 */
    Q_INVOKABLE QString imagePath();
    Q_INVOKABLE void setImagePath(const QString &path);

    /** @brief 相机名称 */
    Q_INVOKABLE QString cameraName();
    Q_INVOKABLE void setCameraName(const QString &camera);

    /** @brief 相机分辨率 */
    Q_INVOKABLE QString cameraSize();
    Q_INVOKABLE void setCameraSize(const QString &r);

    /** @brief 相机Hue等参数 */
    Q_INVOKABLE QList<int> cameraHues();
    Q_INVOKABLE void setCameraHues(int h, int s, int l, int c);

    /** @brief 相机ROI参数 */
    Q_INVOKABLE QList<int> cameraRoi();
    Q_INVOKABLE void setCameraRoi(int x, int y, int w, int h);

  signals:
    /** @brief 通知有配置更新 */
    void wallPaperUpdated();

  private:
    /** @brief 读取key的值到配置文件 */
    QVariant readValue(const QString &key, const QString &group = CFG_ROOT, const QString &file = CFG_FILE);

    /** @brief 保存key的值到配置文件 */
    void writeValue(const QString &key, const QVariant &value, const QString &group = CFG_ROOT, const QString &file = CFG_FILE);

  private:
    QString m_userName = "";
    QString m_userAccount = "";
};

#endif // CONFIGER_H
