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
#ifndef DATADICT_H
#define DATADICT_H

#include "common.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QObject>
#include <QTimer>
#include <QtQml>

/* @brief 数据字典Json格式
    "ID"-id qint64
    "Key"-编号 string
    "Value"-值 string
    "Type"-值类型(DictType) int
*/

class DataDict : public QObject
{
    Q_OBJECT
    QML_ELEMENT

  public:
    DataDict(QObject *parent = nullptr);

    /** @brief 数据字典的类型 */
    enum DictType
    {
        /** @brief 性别 */
        Sex = 1,

        /** @brief 送检科室 */
        Dept = 4,

        /** @brief 送检医生 */
        Doctor = 5,

        /** @brief 标本状态 */
        SpecimenQuality = 6,

        /** @brief 标本类型 */
        SpecimenType = 7,

        /** @brief 诊断 */
        Diagnosis = 8
    };
    Q_ENUM(DictType)

    /** @brief 取类型所有字典值，Json格式 */
    Q_INVOKABLE QList<QJsonObject> getDatas(DictType type);

    /** @brief 取类型所有字典值，字符列表格式,供Qml了Combobox用 */
    Q_INVOKABLE QStringList getValues(DictType type);

    /** @brief 新增字典值
     *@param[in] data: json格式
     *@return id
     */
    Q_INVOKABLE quint64 appendData(const QJsonObject &data);

    /** @brief 根据Json中的Id更新字典值 */
    Q_INVOKABLE int updateData(const QJsonObject &data);

    /** @brief 删除字典值 */
    Q_INVOKABLE int deleteData(quint64 id);

    /** @brief 最后一次产生的错误信息 */
    Q_INVOKABLE MessageInfo lastError();

    /** @brief 编号是否已存在 */
    Q_INVOKABLE int codeExisted(quint64 id, const QString &code);

  signals:
    /**
     * @brief 发送消息到信息中心
     * @param info 错误信息或提示信息
     * @param type 信息类型 (Toast/Confirmation)，默认为 Toast
     * @param code 错误码，默认为 NoError
     */
    void messageEmitted(const MessageInfo &msg);

  private:
    /** @brief 最后一次错误信息 */
    MessageInfo m_lastError;
};

#endif // DATADICT_H
