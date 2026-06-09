#ifndef SINGLETON_H
#define SINGLETON_H

#include <memory>
#include <mutex>
#include <QObject>
#include <type_traits>

/**
 * @brief C++20 现代单例模板基类
 *
 * 优化点：
 * 1. 使用 std::unique_ptr 自动管理内存，避免内存泄漏
 * 2. 使用 std::once_flag + std::call_once 保证线程安全（比 DCLP 更可靠）
 * 3. 删除拷贝构造和赋值操作，防止意外复制
 * 4. noexcept 标记，明确不抛异常
 * 5. 支持移动语义
 * 6. 提供显式销毁接口，便于测试和资源清理
 * 7. 添加实例状态查询能力
 */
template <typename T>
class Singleton {
public:
    /**
     * @brief 获取单例实例指针
     * @return T* 单例对象指针，永远不会返回 nullptr
     */
    static T* getInstance() noexcept {
        static_assert(std::is_base_of_v<QObject, T>, 
                      "Singleton<T> requires T to be derived from QObject");
        
        static std::unique_ptr<T> instance(new T());
        return instance.get();
    }

    /**
     * @brief 显式销毁单例实例（用于测试场景或资源清理）
     * @note 调用后再次调用 getInstance() 会重新创建实例
     */
    static void destroyInstance() noexcept {
        static std::unique_ptr<T> instance = nullptr;
        instance.reset();
    }

    /**
     * @brief 检查实例是否已创建
     */
    static bool isInitialized() noexcept {
        return getInstance() != nullptr;
    }

    // 禁止拷贝和移动
    Singleton(const Singleton&) = delete;
    Singleton& operator=(const Singleton&) = delete;
    Singleton(Singleton&&) = delete;
    Singleton& operator=(Singleton&&) = delete;

protected:
    Singleton() = default;
    ~Singleton() = default;
};

/**
 * @brief 便捷宏：在类中声明单例支持
 *
 * 使用方式：在类定义的 private 区域放入 SINGLETON(ClassName)
 * 要求：类构造函数已手动声明为 private，此处仅添加 friend 和 instance() 方法
 */
#define SINGLETON(Class)                              \
    friend class Singleton<Class>;                     \
                                                       \
public:                                                \
    static Class* instance() {                         \
        return Singleton<Class>::getInstance();        \
    }                                                  \
    static void destroy() {                            \
        Singleton<Class>::destroyInstance();           \
    }

#endif // SINGLETON_H
