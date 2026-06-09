#include "DatabaseModel.h"
#include <QDebug>

DatabaseWorker::DatabaseWorker(QObject *parent)
    : QObject(parent)
{
}

DatabaseWorker::~DatabaseWorker()
{
    if (m_database.isOpen()) {
        m_database.close();
    }
}

void DatabaseWorker::openDatabase(const QString &dbPath)
{
    QString connectionName = QString("worker_db_connection_%1").arg(reinterpret_cast<quint64>(QThread::currentThreadId()));

    if (QSqlDatabase::contains(connectionName)) {
        m_database = QSqlDatabase::database(connectionName);
    } else {
        m_database = QSqlDatabase::addDatabase("QSQLITE", connectionName);
    }

    if (m_database.isOpen()) {
        m_database.close();
    }

    m_database.setDatabaseName(dbPath);

    if (!m_database.open()) {
        QString error = m_database.lastError().text();
        qWarning() << "Failed to open database:" << error;
        emit databaseOpened(false, error);
        return;
    }

    qDebug() << "Database opened successfully:" << dbPath << "in thread" << QThread::currentThreadId();
    emit databaseOpened(true);
}

void DatabaseWorker::loadPatientInfo()
{
    if (!m_database.isOpen()) {
        qWarning() << "Database not opened";
        emit patientInfoLoaded(false, QStringList(), QList<QList<QVariant>>(), "Database not opened");
        return;
    }

    QStringList headers;
    QList<QList<QVariant>> data;

    QSqlQuery query(m_database);
    if (!query.exec("SELECT * FROM PatientInfo")) {
        QString error = query.lastError().text();
        qWarning() << "Query failed:" << error;
        emit patientInfoLoaded(false, QStringList(), QList<QList<QVariant>>(), error);
        return;
    }

    QSqlRecord record = query.record();
    int columnCount = record.count();

    for (int i = 0; i < columnCount; ++i) {
        headers << record.fieldName(i);
    }

    m_headers = headers;

    while (query.next()) {
        QList<QVariant> row;
        for (int i = 0; i < columnCount; ++i) {
            row << query.value(i);
        }
        data << row;
    }

    qDebug() << "Worker: Loaded" << data.size() << "rows from PatientInfo in thread" << QThread::currentThreadId();
    emit patientInfoLoaded(true, headers, data);
}

void DatabaseWorker::insertPatient(const QStringList &values)
{
    if (!m_database.isOpen() || values.size() != m_headers.size()) {
        QString error = "Cannot insert: database not open or value count mismatch";
        qWarning() << error;
        emit patientInserted(false, error);
        return;
    }

    QString placeholders;
    for (int i = 0; i < values.size(); ++i) {
        placeholders += "?";
        if (i < values.size() - 1) placeholders += ",";
    }

    QString queryStr = QString("INSERT INTO PatientInfo VALUES (%1)").arg(placeholders);
    QSqlQuery query(m_database);
    query.prepare(queryStr);

    for (int i = 0; i < values.size(); ++i) {
        query.bindValue(i, values[i]);
    }

    if (!query.exec()) {
        QString error = query.lastError().text();
        qWarning() << "Insert failed:" << error;
        emit patientInserted(false, error);
        return;
    }

    qDebug() << "Worker: Inserted new row in thread" << QThread::currentThreadId();
    emit patientInserted(true);
}

void DatabaseWorker::updatePatient(int row, const QStringList &values, const QVariant &primaryKeyValue)
{
    Q_UNUSED(row)

    if (!m_database.isOpen() || values.size() != m_headers.size()) {
        QString error = "Cannot update: invalid parameters";
        qWarning() << error;
        emit patientUpdated(false, error);
        return;
    }

    QString setClause;
    for (int i = 0; i < m_headers.size(); ++i) {
        setClause += QString("%1 = ?").arg(m_headers[i]);
        if (i < m_headers.size() - 1) setClause += ",";
    }

    QString queryStr = QString("UPDATE PatientInfo SET %1 WHERE %2 = ?").arg(setClause, m_headers[0]);
    QSqlQuery query(m_database);
    query.prepare(queryStr);

    for (int i = 0; i < values.size(); ++i) {
        query.bindValue(i, values[i]);
    }
    query.bindValue(values.size(), primaryKeyValue);

    if (!query.exec()) {
        QString error = query.lastError().text();
        qWarning() << "Update failed:" << error;
        emit patientUpdated(false, error);
        return;
    }

    qDebug() << "Worker: Updated row in thread" << QThread::currentThreadId();
    emit patientUpdated(true);
}

void DatabaseWorker::deletePatient(int row, const QVariant &primaryKeyValue)
{
    Q_UNUSED(row)

    if (!m_database.isOpen()) {
        QString error = "Cannot delete: database not open";
        qWarning() << error;
        emit patientDeleted(false, error);
        return;
    }

    QString queryStr = QString("DELETE FROM PatientInfo WHERE %1 = ?").arg(m_headers[0]);
    QSqlQuery query(m_database);
    query.prepare(queryStr);
    query.bindValue(0, primaryKeyValue);

    if (!query.exec()) {
        QString error = query.lastError().text();
        qWarning() << "Delete failed:" << error;
        emit patientDeleted(false, error);
        return;
    }

    qDebug() << "Worker: Deleted row in thread" << QThread::currentThreadId();
    emit patientDeleted(true);
}

DatabaseModel::DatabaseModel(QObject *parent)
    : QAbstractTableModel(parent)
    , m_workerThread(new QThread(this))
    , m_worker(new DatabaseWorker())
{
    m_worker->moveToThread(m_workerThread);

    connect(this, &DatabaseModel::openDatabaseRequested, m_worker, &DatabaseWorker::openDatabase);
    connect(this, &DatabaseModel::loadPatientInfoRequested, m_worker, &DatabaseWorker::loadPatientInfo);
    connect(this, &DatabaseModel::insertPatientRequested, m_worker, &DatabaseWorker::insertPatient);
    connect(this, &DatabaseModel::updatePatientRequested, m_worker, &DatabaseWorker::updatePatient);
    connect(this, &DatabaseModel::deletePatientRequested, m_worker, &DatabaseWorker::deletePatient);

    connect(m_worker, &DatabaseWorker::databaseOpened, this, &DatabaseModel::onDatabaseOpened);
    connect(m_worker, &DatabaseWorker::patientInfoLoaded, this, &DatabaseModel::onPatientInfoLoaded);
    connect(m_worker, &DatabaseWorker::patientInserted, this, &DatabaseModel::onPatientInserted);
    connect(m_worker, &DatabaseWorker::patientUpdated, this, &DatabaseModel::onPatientUpdated);
    connect(m_worker, &DatabaseWorker::patientDeleted, this, &DatabaseModel::onPatientDeleted);

    m_workerThread->start();
    qDebug() << "DatabaseModel: Worker thread started" << m_workerThread;
}

DatabaseModel::~DatabaseModel()
{
    m_workerThread->quit();
    m_workerThread->wait();
    delete m_worker;
}

bool DatabaseModel::openDatabaseByName(const QString &dbFileName)
{
    QString dbPath = QCoreApplication::applicationDirPath() + "/" + dbFileName;
    qDebug() << "Opening database at:" << dbPath;
    emit openDatabaseRequested(dbPath);
    return true;
}

bool DatabaseModel::loadPatientInfo()
{
    qDebug() << "Model: loadPatientInfoRequested in main thread" << QThread::currentThreadId();
    emit loadPatientInfoRequested();
    return true;
}

bool DatabaseModel::insertPatient(const QStringList &values)
{
    emit insertPatientRequested(values);
    return true;
}

bool DatabaseModel::updatePatient(int row, const QStringList &values)
{
    QMutexLocker locker(&m_dataMutex);
    if (row < 0 || row >= m_data.size()) {
        return false;
    }
    QVariant primaryKeyValue = m_data[row][m_primaryKeyIndex];
    locker.unlock();

    emit updatePatientRequested(row, values, primaryKeyValue);
    return true;
}

bool DatabaseModel::deletePatient(int row)
{
    QMutexLocker locker(&m_dataMutex);
    if (row < 0 || row >= m_data.size()) {
        return false;
    }
    QVariant primaryKeyValue = m_data[row][m_primaryKeyIndex];
    locker.unlock();

    emit deletePatientRequested(row, primaryKeyValue);
    return true;
}

QVariant DatabaseModel::getData(int row, int column)
{
    QMutexLocker locker(&m_dataMutex);
    if (row < 0 || row >= m_data.size() || column < 0 || column >= m_headers.size()) {
        return QVariant();
    }
    return m_data[row][column];
}

QString DatabaseModel::getHeader(int column)
{
    QMutexLocker locker(&m_dataMutex);
    if (column < 0 || column >= m_headers.size()) {
        return QString();
    }
    return m_headers[column];
}

void DatabaseModel::onDatabaseOpened(bool success, const QString &error)
{
    if (!success) {
        qWarning() << "Database open failed:" << error;
        emit errorOccurred(error);
    } else {
        qDebug() << "Database open success";
    }
}

void DatabaseModel::onPatientInfoLoaded(bool success, const QStringList &headers,
                                        const QList<QList<QVariant>> &data, const QString &error)
{
    if (success) {
        QMutexLocker locker(&m_dataMutex);
        beginResetModel();
        m_headers = headers;
        m_data = data;
        endResetModel();
        qDebug() << "Model: Updated" << m_data.size() << "rows in main thread" << QThread::currentThreadId();
    } else {
        qWarning() << "Load patient info failed:" << error;
        emit errorOccurred(error);
    }
}

void DatabaseModel::onPatientInserted(bool success, const QString &error)
{
    if (success) {
        loadPatientInfo();
    } else {
        qWarning() << "Insert failed:" << error;
        emit errorOccurred(error);
    }
}

void DatabaseModel::onPatientUpdated(bool success, const QString &error)
{
    if (success) {
        loadPatientInfo();
    } else {
        qWarning() << "Update failed:" << error;
        emit errorOccurred(error);
    }
}

void DatabaseModel::onPatientDeleted(bool success, const QString &error)
{
    if (success) {
        loadPatientInfo();
    } else {
        qWarning() << "Delete failed:" << error;
        emit errorOccurred(error);
    }
}

void DatabaseModel::onErrorOccurred(const QString &error)
{
    qWarning() << "Database error:" << error;
}

int DatabaseModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_data.size();
}

int DatabaseModel::columnCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_headers.size();
}

QVariant DatabaseModel::data(const QModelIndex &index, int role) const
{
    QMutexLocker locker(&m_dataMutex);

    if (!index.isValid() || index.row() >= m_data.size() || index.column() >= m_headers.size()) {
        return QVariant();
    }

    if (role == Qt::DisplayRole) {
        return m_data[index.row()][index.column()];
    }

    return QVariant();
}

QVariant DatabaseModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    QMutexLocker locker(&m_dataMutex);

    if (role != Qt::DisplayRole) {
        return QVariant();
    }

    if (orientation == Qt::Horizontal) {
        if (section >= 0 && section < m_headers.size()) {
            return m_headers[section];
        }
    } else {
        return QString("Row %1").arg(section);
    }

    return QVariant();
}
