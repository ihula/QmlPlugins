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
** Brief: 日志类
** History:
****************************************************************************/

#ifndef HULALOGGER_H
#define HULALOGGER_H

#include <QObject>
#include <QFile>


typedef enum tagLogLevel{
    Fatal = 0,
    Critical,
    Warning,
    Info,
    Debug
} LogLevel;


void logInit(int type);


#endif // HULALOGGER_H
