#include "qAQMS.h"
#include "qAQMSConst.h"

#include <QDebug>
#include <QDateTime>
#include <QTcpSocket>
#include <QTcpServer>
#include <QHostAddress>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QFile>
#include <QSaveFile>

QAQMS::QAQMS(QObject* parent)
    : QObject(parent)
    , m_pServer(NULL)
{
}

QAQMS::~QAQMS()
{
    if (m_pServer)
        delete m_pServer;
}

bool QAQMS::Init()
{
    LoadReadings();

    m_pServer = new QTcpServer(this);

    if (!m_pServer->listen(QHostAddress::Any, QAQMS_PORT))
    {
        qDebug() << "ERROR :: Server did not start. It may already be running.";
        delete m_pServer;
        m_pServer = NULL;
        return false;
    }

    qDebug() << "Server started on port" << QAQMS_PORT;
    qDebug() << "Loaded readings:" << m_readings.size();

    connect(m_pServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));

    return true;
}

void QAQMS::NewConnection()
{
    QTcpSocket* pSocket = m_pServer->nextPendingConnection();

    qDebug() << "New connection from" << pSocket->peerAddress().toString();

    connect(pSocket, SIGNAL(readyRead()), this, SLOT(ReadClientData()));
    connect(pSocket, SIGNAL(disconnected()), pSocket, SLOT(deleteLater()));
}

void QAQMS::ReadClientData()
{
    QTcpSocket* pSocket = qobject_cast<QTcpSocket*>(sender());

    if (!pSocket)
        return;

    QByteArray requestData = pSocket->readAll();
    QByteArray responseData = HandleRequest(requestData);

    pSocket->write(responseData);
    pSocket->flush();
    pSocket->disconnectFromHost();
}

QByteArray QAQMS::HandleRequest(const QByteArray& data)
{
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError)
        return MakeError("Invalid JSON");

    if (!doc.isObject())
        return MakeError("JSON must be an object");

    QJsonObject obj = doc.object();

    if (!obj.contains("type"))
        return MakeError("Missing type");

    QString type = obj["type"].toString();

    if (type == "upload")
        return HandleUpload(obj);

    if (type == "get_all")
        return HandleGetAll();

    if (type == "clear_all")
        return HandleClearAll();

    return MakeError("Unknown request type");
}

QByteArray QAQMS::HandleUpload(const QJsonObject& obj)
{
    if (!obj.contains("device_id"))
        return MakeError("Missing device_id");

    if (!obj.contains("latitude"))
        return MakeError("Missing latitude");

    if (!obj.contains("longitude"))
        return MakeError("Missing longitude");

    if (!obj.contains("air_quality"))
        return MakeError("Missing air_quality");

    AirQualityReading reading;

    reading.deviceId = obj["device_id"].toString().trimmed().toUpper();
    reading.latitude = obj["latitude"].toDouble();
    reading.longitude = obj["longitude"].toDouble();
    reading.airQuality = obj["air_quality"].toDouble();
    reading.timestamp = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);

    if (reading.deviceId.isEmpty())
        return MakeError("device_id cannot be empty");

    m_readings[reading.deviceId] = reading;

    if (!SaveReadings())
        return MakeError("Reading stored in memory, but failed to save readings.json");

    qDebug() << "Stored reading:"
             << reading.deviceId
             << reading.latitude
             << reading.longitude
             << reading.airQuality
             << reading.timestamp;

    return MakeOk();
}

QByteArray QAQMS::HandleGetAll()
{
    QJsonArray devicesArray;

    QMap<QString, AirQualityReading>::const_iterator it;

    for (it = m_readings.constBegin(); it != m_readings.constEnd(); ++it)
    {
        const AirQualityReading& reading = it.value();

        QJsonObject deviceObj;
        deviceObj["device_id"] = reading.deviceId;
        deviceObj["latitude"] = reading.latitude;
        deviceObj["longitude"] = reading.longitude;
        deviceObj["air_quality"] = reading.airQuality;
        deviceObj["timestamp"] = reading.timestamp;

        devicesArray.append(deviceObj);
    }

    QJsonObject responseObj;
    responseObj["status"] = "ok";
    responseObj["devices"] = devicesArray;

    QJsonDocument responseDoc(responseObj);

    return responseDoc.toJson(QJsonDocument::Compact);
}

QByteArray QAQMS::HandleClearAll()
{
    int count = m_readings.size();

    m_readings.clear();

    if (!SaveReadings())
        return MakeError("Readings cleared in memory, but failed to save readings.json");

    QJsonObject responseObj;
    responseObj["status"] = "ok";
    responseObj["message"] = "All readings cleared";
    responseObj["deleted_count"] = count;

    QJsonDocument responseDoc(responseObj);

    return responseDoc.toJson(QJsonDocument::Compact);
}

QByteArray QAQMS::MakeOk()
{
    QJsonObject obj;
    obj["status"] = "ok";

    QJsonDocument doc(obj);
    return doc.toJson(QJsonDocument::Compact);
}

QByteArray QAQMS::MakeError(const QString& message)
{
    QJsonObject obj;
    obj["status"] = "error";
    obj["message"] = message;

    QJsonDocument doc(obj);
    return doc.toJson(QJsonDocument::Compact);
}

bool QAQMS::LoadReadings()
{
    QFile file(QAQMS_DATA_FILE);

    if (!file.exists())
    {
        qDebug() << "No existing data file found:" << QAQMS_DATA_FILE;
        return true;
    }

    if (!file.open(QIODevice::ReadOnly))
    {
        qDebug() << "Failed to open data file:" << QAQMS_DATA_FILE;
        return false;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError)
    {
        qDebug() << "Failed to parse data file:" << parseError.errorString();
        return false;
    }

    if (!doc.isObject())
    {
        qDebug() << "Data file root is not an object.";
        return false;
    }

    QJsonObject rootObj = doc.object();

    if (!rootObj.contains("devices") || !rootObj["devices"].isArray())
    {
        qDebug() << "Data file does not contain devices array.";
        return false;
    }

    QJsonArray devicesArray = rootObj["devices"].toArray();

    m_readings.clear();

    for (int i = 0; i < devicesArray.size(); ++i)
    {
        QJsonObject deviceObj = devicesArray[i].toObject();

        AirQualityReading reading;
        reading.deviceId = deviceObj["device_id"].toString().trimmed().toUpper();
        reading.latitude = deviceObj["latitude"].toDouble();
        reading.longitude = deviceObj["longitude"].toDouble();
        reading.airQuality = deviceObj["air_quality"].toDouble();
        reading.timestamp = deviceObj["timestamp"].toString();

        if (!reading.deviceId.isEmpty())
            m_readings[reading.deviceId] = reading;
    }

    qDebug() << "Loaded readings from file:" << m_readings.size();

    return true;
}

bool QAQMS::SaveReadings()
{
    QJsonArray devicesArray;

    QMap<QString, AirQualityReading>::const_iterator it;

    for (it = m_readings.constBegin(); it != m_readings.constEnd(); ++it)
    {
        const AirQualityReading& reading = it.value();

        QJsonObject deviceObj;
        deviceObj["device_id"] = reading.deviceId;
        deviceObj["latitude"] = reading.latitude;
        deviceObj["longitude"] = reading.longitude;
        deviceObj["air_quality"] = reading.airQuality;
        deviceObj["timestamp"] = reading.timestamp;

        devicesArray.append(deviceObj);
    }

    QJsonObject rootObj;
    rootObj["devices"] = devicesArray;

    QJsonDocument doc(rootObj);

    QSaveFile file(QAQMS_DATA_FILE);

    if (!file.open(QIODevice::WriteOnly))
    {
        qDebug() << "Failed to open data file for writing:" << QAQMS_DATA_FILE;
        return false;
    }

    file.write(doc.toJson(QJsonDocument::Indented));

    if (!file.commit())
    {
        qDebug() << "Failed to commit data file:" << QAQMS_DATA_FILE;
        return false;
    }

    return true;
}

QString QAQMS::GetCurrentTime()
{
    return QDateTime::currentDateTime().toString("yyyy MMM dd hh:mm:ss");
}