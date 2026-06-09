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
** @Brief: 更新文件类
** @History:
****************************************************************************/
#ifndef UTILS_H
#define UTILS_H

#include <QObject>
#include <QDir>
#include <QtQml>

class Utils : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    // 必须提供带默认参数的构造函数
    explicit Utils(QObject *parent = nullptr) : QObject(parent) {}

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
    *@param[in] cover:是覆盖目标目录中存在的同名文件
    */
    static bool copyDir(const QString &sourceDir, const QString &toDir, bool cover);

    /**
    *@brief 将源目录中新修改或新创建的文件更新到目标目录
    *@param[in] fromDir:源目录
    *@param[in] toDir:目标目录
    *@param[in] cover:是覆盖目标目录中存在的同名文件
    */
    static bool updateDirFiles(const QString &fromDir, const QString &toDir, bool cover);

    /**
    *@brief 将新修改的源文件更新到目标位置
    *@param[in] src:源文件
    *@param[in] dst:目标文件
    *@param[in] cover:是覆盖已存在的同名文件
    */
    static bool updateFile(const QString &src, const QString &dst, bool cover);
};

#endif // PUBLICFUNC_H
