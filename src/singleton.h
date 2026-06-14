#ifndef SINGLETON_H
#define SINGLETON_H

#include <QMutex>
#include <QScopedPointer>
#include <mutex>

template <typename T>
class Singleton {
public:
    static T* getInstance();

    Singleton(const Singleton& other) = delete;
    Singleton<T>& operator=(const Singleton<T>& other) = delete;

private:
    static QMutex mutex;
    static T* m_instance;
};

template <typename T>
QMutex Singleton<T>::mutex;

template <typename T>
T* Singleton<T>::m_instance = nullptr;

template <typename T>
T* Singleton<T>::getInstance() {
    if (m_instance == nullptr) {
        QMutexLocker locker(&mutex);
        if (m_instance == nullptr) {
            m_instance = new T();
        }
    }
    return m_instance;
}

#define SINGLETON(Class)                           \
private:                                            \
    friend class Singleton<Class>;                  \
    friend struct QScopedPointerDeleter<Class>;     \
                                                       \
    public:                                         \
    static Class* instance() {                      \
        return Singleton<Class>::getInstance();     \
    }

#endif // SINGLETON_H
