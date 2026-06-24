#include "configer.h"
#include "utils.h"
#include <QColor>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QMap>
#include <QMetaObject>
#include <QMetaProperty>
#include <QQuickItem>
#include <QSettings>

Configer::~Configer()
{
}

Configer::Configer(QObject *parent) : QObject(parent)
{
}

QString Configer::userName()
{
    return m_userName;
}

void Configer::setUserName(const QString &userName)
{
    m_userName = userName;
}

QString Configer::userAccount()
{
    return m_userAccount;
}

void Configer::setUserAccount(const QString &userAccount)
{
    m_userAccount = userAccount;
}

int Configer::logLevel()
{
    return readValue("TraceLevel", "Log").toInt();
}

void Configer::setLogLevel(int level)
{
    writeValue("TraceLevel", level, "Log");
}

QString Configer::language()
{
    return readValue("Language").toString();
}

void Configer::setLanguage(const QString &langName)
{
    writeValue("Language", langName);
}

QString Configer::fontName()
{
    return readValue("FontName").toString();
}

void Configer::setFontName(const QString &font)
{
    writeValue("FontName", font);
}

int Configer::fontSize()
{
    return readValue("FontSize").toInt();
}

void Configer::setFontSize(int size)
{
    writeValue("FontSize", size);
}

QString Configer::theme()
{
    return readValue("Theme").toString();
}

void Configer::setTheme(const QString &style)
{
    writeValue("Theme", style);
}

QVariantMap Configer::loadTheme(const QString &themeName)
{
    QVariantMap datas;
    QString themeFile = THEME_PATH + themeName + ".ini";

    QSettings settings(themeFile, QSettings::IniFormat);
    const QStringList groups = settings.childGroups();
    for (const QString &group : groups)
    {
        settings.beginGroup(group);
        const QStringList keys = settings.childKeys();
        for (const QString &key : keys)
        {
            datas[group + "/" + key] = settings.value(key);
        }
        settings.endGroup();
    }

    return datas;
}

void Configer::saveTheme(const QVariantMap &datas, const QString &themeName)
{
    qDebug() << 1 << themeName;
    if (datas.isEmpty())
        return;

    // 分类存储：颜色、字体(数值)、渐变
    QMap<QString, QVariant> strings;
    QMap<QString, QVariant> ints;
    QMap<QString, QVariant> numbers;
    QMap<QString, QVariant> gradients;

    // 获取主题对象的自定义属性
    const QStringList keys = datas.keys();
    for (const QString &key : keys)
    {
        QVariant value = datas[key];
        if (!value.isValid())
            continue;

        // 获取类型名称
        int type = value.typeId();
        // qDebug() << "Property:" << key << "type:" << value.typeName() << "value:" << value.toString();

        // 字符类型
        if (type == QMetaType::QColor)
        {
            QColor color = value.value<QColor>();
            if (color.isValid())
                strings[key] = color.name();
        }
        else if (type == QMetaType::QString)
        {
            qDebug() << 23 << type;
            if (value.toString().indexOf("|") > -1)
                gradients[key] = value;
            else
                strings[key] = value;
        }
        else if (type == QMetaType::Int)
        {
            // 整数类型
            ints[key] = value;
        }
        else if (type == QMetaType::Double || type == QMetaType::Float || type == QMetaType::QReal)
        {
            // 数值类型
            numbers[key] = value;
        }
    }

    // 写入 ini 文件
    QString themeFile = THEME_PATH + themeName + ".ini";
    QSettings settings(themeFile, QSettings::IniFormat);

    // 保存 strings
    settings.beginGroup("String");
    for (auto it = strings.constBegin(); it != strings.constEnd(); ++it)
    {
        settings.setValue(it.key(), it.value());
    }
    settings.endGroup();

    // 保存 ints
    settings.beginGroup("Int");
    for (auto it = ints.constBegin(); it != ints.constEnd(); ++it)
    {
        settings.setValue(it.key(), it.value());
    }
    settings.endGroup();

    // 保存 numbers
    settings.beginGroup("Number");
    for (auto it = numbers.constBegin(); it != numbers.constEnd(); ++it)
    {
        settings.setValue(it.key(), it.value());
    }
    settings.endGroup();

    // 保存 Gradients
    settings.beginGroup("Gradient");
    for (auto it = gradients.constBegin(); it != gradients.constEnd(); ++it)
    {
        settings.setValue(it.key(), it.value());
    }
    settings.endGroup();
}

int Configer::dialogAutoCloseTime()
{
    return readValue("DialogAutoCloseTime").toInt();
}

void Configer::setDialogAutoCloseTime(int sec)
{
    writeValue("DialogAutoCloseTime", sec);
}

bool Configer::enableSplash()
{
    int ret = readValue("EnableSplash").toInt();
    return (ret == 1);
}

void Configer::setEnableSplash(bool sure)
{
    int val = sure ? 1 : 0;
    writeValue("EnableSplash", val);
}

int Configer::splashFormShowMode()
{
    return readValue("SplashFormShowMode").toInt();
}

void Configer::setSplashFormShowMode(int mode)
{
    writeValue("SplashFormShowMode", mode);
}

bool Configer::splashCanClose()
{
    int ret = readValue("SplashCanClose").toInt();
    return (ret == 1);
}

void Configer::setSplashCanClose(bool sure)
{
    int val = sure ? 1 : 0;
    writeValue("SplashCanClose", val);
}

bool Configer::enableLogin()
{
    int ret = readValue("EnableLogin").toInt();
    return (ret == 1);
}

void Configer::setEnableLogin(bool sure)
{
    int val = sure ? 1 : 0;
    writeValue("EnableLogin", val);
}

int Configer::loginFormShowMode()
{
    return readValue("LoginFormShowMode").toInt();
}

void Configer::setLoginFormShowMode(int mode)
{
    writeValue("LoginFormShowMode", mode);
}

int Configer::mainFormShowMode()
{
    return readValue("MainFormShowMode").toInt();
}

void Configer::setMainFormShowMode(int mode)
{
    writeValue("MainFormShowMode", mode);
}

bool Configer::useWallPaper()
{
    int ret = readValue("UseWallPaper").toInt();
    return (ret == 1);
}

void Configer::setUseWallPaper(bool used)
{
    int val = used ? 1 : 0;
    writeValue("UseWallPaper", val);
    emit wallPaperUpdated();
}

bool Configer::liveWallPaper()
{
    int ret = readValue("LiveWallPaper").toInt();
    return (ret == 1);
}

void Configer::setLiveWallPaper(bool used)
{
    int val = used ? 1 : 0;
    writeValue("LiveWallPaper", val);
    emit wallPaperUpdated();
}

bool Configer::fileExisted(const QString &fileName)
{
    return QFileInfo::exists(fileName);
}

int Configer::heartbeatTime()
{
    return readValue("HeartbeatTime").toInt();
}

void Configer::setHeartbeatTime(int num)
{
    writeValue("HeartbeatTime", num);
}

bool Configer::reportPreviewed()
{
    int ret = readValue("ReportPreviewed").toInt();
    return (ret == 1);
}

void Configer::setReportPreviewed(bool sure)
{
    int reportPreviewed = sure ? 1 : 0;
    writeValue("ReportPreviewed", reportPreviewed);
}

bool Configer::reportDesigned()
{
    int ret = readValue("ReportDesigned").toInt();
    return (ret == 1);
}

void Configer::setReportDesigned(bool sure)
{
    int reportDesigned = sure ? 1 : 0;
    writeValue("ReportDesigned", reportDesigned);
}

QStringList Configer::reportTemplateList()
{
    QStringList list = {};
    QDir dir("./");
    const auto infos = dir.entryInfoList({"*.lrxml"}, QDir::Files);
    for (const auto &info : infos)
    {
        list.append(info.baseName());
    }
    return list;
}

QString Configer::reportTemplate()
{
    return readValue("ReportTemplate").toString();
}

void Configer::setReportTemplate(const QString &text)
{
    writeValue("ReportTemplate", text);
}

QString Configer::reportTitel(const QString &reportNo)
{
    return readValue("ReportTitle" + reportNo).toString();
}

void Configer::setReportTitel(const QString &reportNo, const QString &text)
{
    writeValue("ReportTitle" + reportNo, text);
}

QString Configer::reportTitelColor(const QString &reportNo)
{
    QString str = readValue("ReportTitleColor" + reportNo).toString();
    if (str == "")
        str = "black";
    return str;
}

void Configer::setReportTitelColor(const QString &reportNo, const QString &text)
{
    writeValue("ReportTitleColor" + reportNo, text);
}

int Configer::reportTitelSize(const QString &reportNo)
{
    return readValue("ReportTitleSize" + reportNo).toInt();
}

void Configer::setReportTitelSize(const QString &reportNo, int size)
{
    writeValue("ReportTitleSize" + reportNo, size);
}

QString Configer::hospitalName(const QString &reportNo)
{

    return readValue("HospitalName" + reportNo).toString();
}

void Configer::setHospitalName(const QString &reportNo, const QString &text)
{
    writeValue("HospitalName" + reportNo, text);
}

QString Configer::hospitalNameColor(const QString &reportNo)
{
    QString str = readValue("HospitalNameColor" + reportNo).toString();
    if (str == "")
        str = "black";
    return str;
}

void Configer::setHospitalNameColor(const QString &reportNo, const QString &text)
{
    writeValue("HospitalNameColor" + reportNo, text);
}

int Configer::hospitalNameSize(const QString &reportNo)
{
    return readValue("HospitalNameSize" + reportNo).toInt();
}

void Configer::setHospitalNameSize(const QString &reportNo, int size)
{
    writeValue("HospitalNameSize" + reportNo, size);
}

QString Configer::hospitalLogo(const QString &reportNo)
{
    return readValue("HospitalLogo" + reportNo).toString();
}

void Configer::setHospitalLogo(const QString &reportNo, const QString &path)
{
    writeValue("HospitalLogo" + reportNo, path);
}

QString Configer::imagePath()
{
    return readValue("ImagePath").toString();
}

void Configer::setImagePath(const QString &path)
{
    writeValue("ImagePath", path);
}

QString Configer::cameraName()
{
    return readValue("CameraName").toString();
}

void Configer::setCameraName(const QString &camera)
{
    writeValue("CameraName", camera);
}

QString Configer::cameraSize()
{
    return readValue("CameraSize").toString();
}

void Configer::setCameraSize(const QString &r)
{
    writeValue("CameraSize", r);
}

QList<int> Configer::cameraHues()
{
    int h = readValue("CameraHuesH").toInt();
    int s = readValue("CameraHuesS").toInt();
    int l = readValue("CameraHuesL").toInt();
    int c = readValue("CameraHuesC").toInt();
    QList<int> hues;
    hues.append(h);
    hues.append(s);
    hues.append(l);
    hues.append(c);
    return hues;
}

void Configer::setCameraHues(int h, int s, int l, int c)
{
    writeValue("CameraHuesH", h);
    writeValue("CameraHuesS", s);
    writeValue("CameraHuesL", l);
    writeValue("CameraHuesC", c);
}

QList<int> Configer::cameraRoi()
{
    int x = readValue("CameraRoiX").toInt();
    int y = readValue("CameraRoiY").toInt();
    int w = readValue("CameraRoiW").toInt();
    int h = readValue("CameraRoiH").toInt();
    QList<int> roi;
    roi.append(x);
    roi.append(y);
    roi.append(w);
    roi.append(h);
    return roi;
}

void Configer::setCameraRoi(int x, int y, int w, int h)
{
    writeValue("CameraRoiX", x);
    writeValue("CameraRoiY", y);
    writeValue("CameraRoiW", w);
    writeValue("CameraRoiH", h);
}

void Configer::writeValue(const QString &key, const QVariant &value, const QString &group, const QString &file)
{
    QSettings settings(file, QSettings::IniFormat);
    settings.beginGroup(group);
    settings.setValue(key, value);
    settings.endGroup();
}

QVariant Configer::readValue(const QString &key, const QString &group, const QString &file)
{
    QSettings settings(file, QSettings::IniFormat);
    settings.beginGroup(group);
    QVariant val = settings.value(key);
    settings.endGroup();
    return val;
}
