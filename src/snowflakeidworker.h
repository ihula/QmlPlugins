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
** @Brief: 雪花ID类
** @History:
****************************************************************************/
#ifndef IDWORKER_H
#define IDWORKER_H

#include <mutex>
#include <atomic>
#include <chrono>
#include <exception>
#include <sstream>

// 如果不使用 mutex, 则开启下面这个定义, 但是我发现, 还是开启 mutex 功能, 速度比较快
// #define SNOWFLAKE_ID_WORKER_NO_LOCK
/**
* @brief 分布式id生成类
* 64bit id: 0000  0000  0000  0000  0000  0000  0000  0000  0000  0000  0000  0000  0000  0000  0000  0000
*           ||                                                           ||     ||     |  |              |
*           |└------------------------41bit-时间戳------------------------┘└中心5┘ └机器5┘  └----序列号12---┘
*           |
*         不用
* 整体上按照时间自增排序, 并且整个分布式系统内不会产生ID碰撞(由数据中心ID和机器ID作区分), 并且效率较高, 经测试, 每秒能够产生26万ID左右.
*/
class IdFactory
{
public:
    IdFactory(uint32_t workerId, uint32_t datacenterId);

#ifdef SNOWFLAKE_ID_WORKER_NO_LOCK
    typedef std::atomic<uint32_t> AtomicUInt;
    typedef std::atomic<uint64_t> AtomicUInt64;
#else
    typedef uint32_t atomic_uint32;
    typedef uint64_t atomic_uint64;
#endif
    uint32_t getMaxWorkerId() const;
    void setWorkerId(uint32_t workerId);
    uint32_t getMaxDatacenterId() const;
    void setDatacenterId(uint32_t datacenterId);
    uint32_t getWorkerId(uint64_t id);
    uint32_t getDatacenterId(uint64_t id);

    uint64_t getId();
    /**
     * 获得下一个ID (该方法是线程安全的)
     *
     * @return SnowflakeId
     */
    uint64_t nextId();

protected:
    /**
     * 返回以毫秒为单位的当前时间
     *
     * @return 当前时间(毫秒)
     */
    uint64_t timeGen() const;

    /**
     * 阻塞到下一个毫秒，直到获得新的时间戳
     *
     * @param lastTimestamp 上次生成ID的时间截
     * @return 当前时间戳
     */
    uint64_t tilNextMillis(uint64_t lastTimestamp) const;

private:
#ifndef SNOWFLAKE_ID_WORKER_NO_LOCK
    std::mutex mutex;
#endif

    /**
     * 开始时间截 (2020-04-08 00:00:00.000)
     */
    const uint64_t twepoch = 1586275200000;

    /**
     * 机器id所占的位数
     */
    const uint32_t workerIdBits = 5;

    /**
     * 数据中心id所占的位数
     */
    const uint32_t datacenterIdBits = 5;

    /**
     * 序列所占的位数
     */
    const uint32_t sequenceBits = 12;

    /**
     * 机器ID向左移12位
     */
    const uint32_t workerIdShift = sequenceBits;

    /**
     * 数据标识id向左移17位
     */
    const uint32_t datacenterIdShift = workerIdShift + workerIdBits;
    /**
     * 时间截向左移22位
     */
    const uint32_t timestampLeftShift = datacenterIdShift + datacenterIdBits;

    /**
     * 支持的最大机器id，结果是31
     */
    const uint32_t maxWorkerId = static_cast<uint32_t>(-1) ^ (static_cast<uint32_t>(-1) << workerIdBits);

    /**
     * 支持的最大数据中心id，结果是31
     */
    const uint32_t maxDatacenterId = static_cast<uint32_t>(-1) ^ (static_cast<uint32_t>(-1) << datacenterIdBits);

    /**
     * 生成序列的掩码，这里为4095
     */
    const uint32_t sequenceMask = static_cast<uint32_t>(-1) ^ (static_cast<uint32_t>(-1) << sequenceBits);

    /**
     * 工作机器id(0~31)
     */
    uint32_t workerId{ 0 };

    /**
     * 数据中心id(0~31)
     */
    uint32_t datacenterId{ 0 };

    /**
     * 毫秒内序列(0~4095)
     */
    atomic_uint32 sequence{ 0 };
    /**
     * 上次生成ID的时间截
     */
    atomic_uint64 lastTimestamp{ 0 };

};



#endif // IDWORKER_H
