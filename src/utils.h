/****************************************************************************
** C++ for MultiPlatform series
** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
** This work is licensed under the Creative Commons
** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
** @Author: Hula
** @Web: www.123hula.com
** @WeChat: ihula123
** @Contact: benny1225@hotmail.com
** @Date: 2022.10.20
** @Brief: 工具类
** @History:
****************************************************************************/
#ifndef UTILS_H
#define UTILS_H

#include <QDir>
#include <QObject>
#include <QtQml>

class Utils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
  public:
    // 必须提供带默认参数的构造函数
    explicit Utils(QObject *parent = nullptr) : QObject(parent)
    {
    }

    /**
     *@brief 读取目录下文件
     *@param[in] path:路径
     *@param[in] filter:文件类型:"*.jpeg"...
     *@return QStringList:返回目录下文件列表
     */
    Q_INVOKABLE static QStringList getDirFiles(const QString &path, const QStringList &filter);

    /**
     *@brief 复制目录
     *@param[in] sourceDir:源目录
     *@param[in] toDir:目标目录
     *@param[in] overwrite 是否覆盖目标目录中已存在的同名文件
     */
    static bool copyDir(const QString &sourceDir, const QString &toDir, bool overwrite = true);

    /**
     *@brief 条件复制文件（仅当源文件更新时）
     *@param[in] src 源文件
     *@param[in] dst 目标文件
     *@param[in] overwrite 是否强制覆盖（若为 true，则忽略时间戳直接覆盖）
     *@return bool 复制是否成功（源文件不存在时返回true）
     */
    static bool updateFile(const QString &src, const QString &dst, bool overwrite = true);

    /**
     * @brief 获取目录的最新修改时间
     *@param[in] dirPath 目标目录
     *@return QDateTime 最新修改时间
     */
    static QDateTime getDirLatestTime(const QString &dirPath);

    /**
     *@brief 同步两个目录（将最新目录同步到另一个目录）
     *@param[in] dir1 目录1
     *@param[in] dir2 目录2
     *@param[in] deleteOrphaned 是否删除目标目录中在源目录不存在的孤立文件
     *@return bool 同步是否成功
     */
    static bool syncDir(const QString &dir1, const QString &dir2, bool deleteOrphaned = true);

    /**
     *@brief 同步单个文件
     *@param[in] src:源文件
     *@param[in] dst:目标文件
     *@param[in] deleteOrphaned 是否删除目标目录中在源目录不存在的孤立文件
     *@return bool:同步是否成功
     */
    static bool syncFile(const QString &src, const QString &dst);

    /** @brief 获取对象所有属性 */
    Q_INVOKABLE QStringList getCustomProperties(QObject *obj);

    /** @brief 获取对象所有自定义属性 */
    Q_INVOKABLE static QStringList getCustomProps(QObject *obj);

    /** @brief 将QVariantMap保存为Json文件 */
    Q_INVOKABLE void saveToJson(const QVariantMap &datas, const QString &filePath);
};

#endif // UTILS_H
