#include "snowflakeidworker.h"
#include <QDebug>


IdFactory::IdFactory(uint32_t workerId, uint32_t datacenterId): workerId(0), datacenterId(0), sequence(0), lastTimestamp(0)
{
    this->datacenterId = datacenterId;
    this->workerId = workerId;
}

uint32_t IdFactory::getMaxWorkerId() const
{
    return this->maxWorkerId;
}

void IdFactory::setWorkerId(uint32_t workerId)
{
    this->workerId = workerId;
}

uint32_t IdFactory::getMaxDatacenterId() const
{
    return this->maxDatacenterId;
}

void IdFactory::setDatacenterId(uint32_t datacenterId)
{
    this->datacenterId = datacenterId;
}

uint32_t IdFactory::getWorkerId(uint64_t id)
{
    return id >> workerIdShift & static_cast<uint32_t>(~(static_cast<uint32_t>(-1L) << workerIdBits));
}

uint32_t IdFactory::getDatacenterId(uint64_t id)
{
    return id >> datacenterIdShift & static_cast<uint32_t>(~(static_cast<uint32_t>(-1L) << datacenterIdBits));
}

uint64_t IdFactory::getId()
{
    return nextId();
}

uint64_t IdFactory::nextId()
{
#ifndef SNOWFLAKE_ID_WORKER_NO_LOCK
    std::unique_lock<std::mutex> lock{ mutex };
    atomic_uint64 timestamp{ 0 };
#else
    static atomic_uint64 timestamp{ 0 };
#endif
    timestamp = timeGen();

    // 如果当前时间小于上一次ID生成的时间戳，说明系统时钟回退过这个时候应当抛出异常
    if (timestamp < lastTimestamp)
    {
        std::ostringstream s;
        s << "clock moved backwards.  Refusing to generate id for " << lastTimestamp - timestamp << " milliseconds";
        throw std::exception(std::runtime_error(s.str()));
    }

    if (lastTimestamp == timestamp)
    {
        // 如果是同一时间生成的，则进行毫秒内序列
        sequence = (sequence + 1) & sequenceMask;
        if (0 == sequence)
        {
            // 毫秒内序列溢出, 阻塞到下一个毫秒,获得新的时间戳
            timestamp = tilNextMillis(lastTimestamp);
        }
    }
    else
    {
        sequence = 0;
    }
#ifndef SNOWFLAKE_ID_WORKER_NO_LOCK
    lastTimestamp = timestamp;
#else
    lastTimestamp = timestamp.load();
#endif

    // 移位并通过或运算拼到一起组成64位的ID
    return ((timestamp - twepoch) << timestampLeftShift)
            | (datacenterId << datacenterIdShift)
            | (workerId << workerIdShift)
            | sequence;
}

uint64_t IdFactory::timeGen() const
{
//    auto t = std::chrono::time_point_cast<std::chrono::milliseconds>(std::chrono::high_resolution_clock::now());
    auto t = std::chrono::time_point_cast<std::chrono::milliseconds>(std::chrono::system_clock::now());
    return static_cast<uint64_t>(t.time_since_epoch().count());
}

uint64_t IdFactory::tilNextMillis(uint64_t lastTimestamp) const
{
    uint64_t timestamp = timeGen();
    while (timestamp <= lastTimestamp) {
        timestamp = timeGen();
    }
    return timestamp;
}
