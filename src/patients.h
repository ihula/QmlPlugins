 /****************************************************************************
** Qt for cross-platform series
** Copyright (c) 2016 UP(United Prosperity Studio). All rights reserved.
** This work is licensed under the Creative Commons
** Attribution-NonCommercial-ShareAlike 3.0 Unported License.
** Author: Hula
** Web: www.123hula.com
** WeChat: ihula123
** Contact: benny1225@hotmail.com
** Date: 2025.7.12
** Brief: 病人信息类
** History:
****************************************************************************/
#ifndef PATIENTINFO_H
#define PATIENTINFO_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include "baseinfosender.h"


 class Patients : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit Patients(QObject *parent = nullptr);

    /**
    *@brief 查找样本信息
    *@param[in] value:表字段值;key:表字段名
    *@return 样本信息Json格式
    */
    Q_INVOKABLE QJsonObject findPatient(const QString &value, const QString &key = "Id");

    /**
    *@brief 根据条件查找样本信息
    *@param[in] data:json格式条件,key=字段名+比较符,(Age>,Date>=,Date<=);
    *key=字段名+"-Type"，表示字段值的类型(Age-Type=Int,即整型,无类型说明默认为字符型)
    *@return 样本信息列表Json格式
    */
    Q_INVOKABLE QList<QJsonObject> findPatients(const QJsonObject &data);

    /**
    *@brief 读取所有样本信息
    *@return 样本信息Json格式
    */
    Q_INVOKABLE QList<QJsonObject> getAllPatients();

    /**
    *@brief 新增样本信息
    *@param[in] data:样本信息Json格式
    *@return 0:失败;>0:样本id
    */
    Q_INVOKABLE quint64 appendPatient(const QJsonObject &data);

    /**
    *@brief 更新样本信息
    *@param[in] data:样本信息Json格式
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int updatePatient(const QJsonObject &data);

    /**
    *@brief 删除样本
    *@param[in] pids:样本Id字符串(id,id,...)
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int deletePatients(const QString &pids);

    /**
    *@brief 删除样本图片目录
    *@param[in] path:图片目录
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int deleteDir(const QString &path);

    /** @brief 取最大流水号:TestId */
    Q_INVOKABLE QString getNextTestId();

    /**
    *@brief 查找报告信息
    *@param[in] value:表字段值;key:表字段名
    *@return 报告信息Json格式
    */
    Q_INVOKABLE QJsonObject findReport(const QString &value, const QString &key = "Id");

    /**
    *@brief 新增报告信息
    *@param[in] value:表字段值;key:表字段名
    *@return 0:失败;>0:样本id
    */
    Q_INVOKABLE quint64 appendReport(const QJsonObject &data);

    /**
    *@brief 更新报告信息
    *@param[in] data:报告信息Json格式
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int updateReport(const QJsonObject &data);

    /**
    *@brief 删除报告
    *@param[in] rid:报告ID
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int deleteReport(const QString &rid);

    /**
    *@brief 备份数据记录
    *@param[in] fileName:保存的文件名
    *@param[in] datas:保存的数据
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int backupRecords(const QString &fileName, const QList<QJsonObject> &datas);

    /**
    *@brief 恢复数据记录
    *@param[in] fileName:数据文件名
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int recoverRecords(const QString &fileName);

    /**
    *@brief 导出到excel
    *@param[in] fileName:数据文件名
    *@return 0:完成;1:失败
    */
    Q_INVOKABLE int exportXlsx(const QString &fileName, const QList<QJsonObject> &datas, const QList<QString> &fields);

signals:
    /**
    *@brief 发送错误信息/提示信息到信息中心
    *@param[in] num:错误信息号,>0:保存并转发弹窗提示;
                -1:表示非错误信息,仅用于转发弹窗提示;
                0:仅用于转发浮窗提示
    *@param[in] text:错误信息或提示信息
    */
    void sendInfo(int num, QString info);

private:
    /** @brief 不使用多重继承,定义类成员变量 */
    BaseInfoSender m_sender;

};

#endif // PATIENTINFO_H
