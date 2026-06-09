#ifndef DATABASEMODEL_H
#define DATABASEMODEL_H

// 先包含所有 Qt 头文件，避免与后续 std::mutex 冲突
#include <QAbstractTableModel>
#include <QObject>
#include <QThread>
#include <QMutex>
#include <QMutexLocker>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QSqlError>
#include <QCoreApplication>

// 使用类型别名避免命名冲突
//using QtMutex = QMutex;
//using QtMutexLocker = QMutexLocker;

class DatabaseWorker : public QObject
{
    Q_OBJECT

public:
    explicit DatabaseWorker(QObject *parent = nullptr);
    ~DatabaseWorker();

public slots:
    void openDatabase(const QString &dbPath);
    void loadPatientInfo();
    void insertPatient(const QStringList &values);
    void updatePatient(int row, const QStringList &values, const QVariant &primaryKeyValue);
    void deletePatient(int row, const QVariant &primaryKeyValue);

signals:
    void databaseOpened(bool success, const QString &error = QString());
    void patientInfoLoaded(bool success, const QStringList &headers,
                          const QList<QList<QVariant>> &data, const QString &error = QString());
    void patientInserted(bool success, const QString &error = QString());
    void patientUpdated(bool success, const QString &error = QString());
    void patientDeleted(bool success, const QString &error = QString());
    void errorOccurred(const QString &error);

private:
    QSqlDatabase m_database;
    QStringList m_headers;
};

class DatabaseModel : public QAbstractTableModel
{
    Q_OBJECT
public:
    explicit DatabaseModel(QObject *parent = nullptr);
    ~DatabaseModel();

    Q_INVOKABLE bool openDatabaseByName(const QString &dbFileName);
    Q_INVOKABLE bool loadPatientInfo();
    Q_INVOKABLE bool insertPatient(const QStringList &values);
    Q_INVOKABLE bool updatePatient(int row, const QStringList &values);
    Q_INVOKABLE bool deletePatient(int row);
    Q_INVOKABLE QVariant getData(int row, int column);
    Q_INVOKABLE QString getHeader(int column);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const override;

signals:
    void openDatabaseRequested(const QString &dbPath);
    void loadPatientInfoRequested();
    void insertPatientRequested(const QStringList &values);
    void updatePatientRequested(int row, const QStringList &values, const QVariant &primaryKeyValue);
    void deletePatientRequested(int row, const QVariant &primaryKeyValue);
    void errorOccurred(const QString &error);

private slots:
    void onDatabaseOpened(bool success, const QString &error);
    void onPatientInfoLoaded(bool success, const QStringList &headers,
                            const QList<QList<QVariant>> &data, const QString &error);
    void onPatientInserted(bool success, const QString &error);
    void onPatientUpdated(bool success, const QString &error);
    void onPatientDeleted(bool success, const QString &error);
    void onErrorOccurred(const QString &error);

private:
    QThread *m_workerThread;
    DatabaseWorker *m_worker;

    QStringList m_headers;
    QList<QList<QVariant>> m_data;
    mutable QMutex m_dataMutex;
    int m_primaryKeyIndex = 0;
};

#endif
