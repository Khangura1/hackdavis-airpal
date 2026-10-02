#include "AirQualityController.h"
#include "AppConstants.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QRandomGenerator>
#include <QTimer>
#include <QSysInfo>

AirQualityController::AirQualityController(QObject* parent)
    : QObject(parent)
    , m_positionSource(nullptr)
    , m_currentAirQuality(0.0)
    , m_aqi(0.0)
    , m_carbonLevel(0.0)
    , m_pm25(0.0)
    , m_tvoc(0.0)
    , m_serverStatus("Server ready")
    , m_bluetoothStatus("Bluetooth not connected")
    , m_locationStatus("Location not ready")
    , m_communityStatus("Community not loaded")
    , m_deviceId(makeDeviceId())
    , m_latitude(AppConstants::DefaultLatitude)
    , m_longitude(AppConstants::DefaultLongitude)
    , m_hasLocation(false)
    , m_hasSensorReading(false)
{
    connect(&m_serverClient,
            &ServerClient::uploadFinished,
            this,
            &AirQualityController::onUploadFinished);

    connect(&m_serverClient,
            &ServerClient::getAllFinished,
            this,
            &AirQualityController::onGetAllFinished);

    connect(&m_bluetoothManager,
            &BluetoothManager::jsonReceived,
            this,
            &AirQualityController::onArduinoJsonReceived);

    connect(&m_bluetoothManager,
            &BluetoothManager::statusChanged,
            this,
            &AirQualityController::onBluetoothStatusChanged);

    setupLocation();

    QTimer::singleShot(1000, this, &AirQualityController::startBluetooth);
}

double AirQualityController::currentAirQuality() const
{
    return m_currentAirQuality;
}

double AirQualityController::aqi() const
{
    return m_aqi;
}

double AirQualityController::carbonLevel() const
{
    return m_carbonLevel;
}

double AirQualityController::pm25() const
{
    return m_pm25;
}

double AirQualityController::tvoc() const
{
    return m_tvoc;
}

QString AirQualityController::serverStatus() const
{
    return m_serverStatus;
}

QString AirQualityController::bluetoothStatus() const
{
    return m_bluetoothStatus;
}

QString AirQualityController::locationStatus() const
{
    return m_locationStatus;
}

QString AirQualityController::communityStatus() const
{
    return m_communityStatus;
}

QString AirQualityController::deviceId() const
{
    return m_deviceId;
}

double AirQualityController::latitude() const
{
    return m_latitude;
}

double AirQualityController::longitude() const
{
    return m_longitude;
}

QVariantList AirQualityController::communityReadings() const
{
    return m_communityReadings;
}

void AirQualityController::startBluetooth()
{
    m_bluetoothManager.startScan();
}

void AirQualityController::stopBluetooth()
{
    m_bluetoothManager.disconnectFromArduino();
}

void AirQualityController::refreshCommunityReadings()
{
    m_communityStatus = "Loading community readings...";
    emit communityStatusChanged();

    m_serverClient.getAllReadings();
}

void AirQualityController::createFakeReadingAndUpload()
{
    QJsonObject fakeObject;

    fakeObject["AQI"] = QRandomGenerator::global()->bounded(10, 151);
    fakeObject["Carbon_LEVEL"] = QRandomGenerator::global()->bounded(400, 1301);
    fakeObject["PM25"] = QRandomGenerator::global()->bounded(0, 151);
    fakeObject["TVOC_level"] = QRandomGenerator::global()->bounded(0, 501);

    QJsonDocument document(fakeObject);

    updateFromSensorJson(QString::fromUtf8(document.toJson(QJsonDocument::Compact)));
}

void AirQualityController::onArduinoJsonReceived(const QString& json)
{
    updateFromSensorJson(json);
}

void AirQualityController::onBluetoothStatusChanged(const QString& status)
{
    m_bluetoothStatus = status;
    emit bluetoothStatusChanged();
}

void AirQualityController::onUploadFinished(bool success, const QString& message)
{
    if (success)
    {
        m_serverStatus = "Uploaded AQI: " + QString::number(m_currentAirQuality, 'f', 0);
    }
    else
    {
        m_serverStatus = "Upload failed: " + message;
    }

    emit serverStatusChanged();
}

void AirQualityController::onGetAllFinished(bool success,
                                            const QString& message,
                                            const QVariantList& readings)
{
    if (success)
    {
        m_communityReadings = readings;
        m_communityStatus = "Loaded " + QString::number(readings.size()) + " community readings.";
        emit communityReadingsChanged();
    }
    else
    {
        m_communityStatus = "Community load failed: " + message;
    }

    emit communityStatusChanged();
}

void AirQualityController::onPositionUpdated(const QGeoPositionInfo& info)
{
    if (!info.isValid())
        return;

    m_latitude = info.coordinate().latitude();
    m_longitude = info.coordinate().longitude();
    m_hasLocation = true;

    m_locationStatus =
        "Location: " +
        QString::number(m_latitude, 'f', 6) +
        ", " +
        QString::number(m_longitude, 'f', 6);

    emit locationChanged();
    emit locationStatusChanged();

    uploadCurrentAqiIfReady();
}

void AirQualityController::onPositionError(QGeoPositionInfoSource::Error error)
{
    switch (error)
    {
    case QGeoPositionInfoSource::AccessError:
        m_locationStatus = "Location error: permission denied";
        break;

    case QGeoPositionInfoSource::ClosedError:
        m_locationStatus = "Location error: location service closed";
        break;

    case QGeoPositionInfoSource::UnknownSourceError:
        m_locationStatus = "Location error: unknown location source error";
        break;

    case QGeoPositionInfoSource::UpdateTimeoutError:
        m_locationStatus = "Location error: update timed out";
        break;

    case QGeoPositionInfoSource::NoError:
        m_locationStatus = "Location ready";
        break;

    default:
        m_locationStatus = "Location error";
        break;
    }

    emit locationStatusChanged();
}
void AirQualityController::setupLocation()
{
    m_positionSource = QGeoPositionInfoSource::createDefaultSource(this);

    if (!m_positionSource)
    {
        m_locationStatus = "No location source. Using default Davis location.";
        emit locationStatusChanged();
        return;
    }

    connect(m_positionSource,
            &QGeoPositionInfoSource::positionUpdated,
            this,
            &AirQualityController::onPositionUpdated);

    connect(m_positionSource,
            &QGeoPositionInfoSource::errorOccurred,
            this,
            &AirQualityController::onPositionError);

    m_positionSource->setUpdateInterval(10000);

    m_locationStatus = "Requesting phone location...";
    emit locationStatusChanged();

    m_positionSource->startUpdates();
    m_positionSource->requestUpdate(10000);
}

void AirQualityController::uploadCurrentAqiIfReady()
{
    if (!m_hasSensorReading)
        return;

    if (!m_hasLocation)
        return;

    QDateTime now = QDateTime::currentDateTimeUtc();

    if (m_lastUploadTime.isValid() && m_lastUploadTime.secsTo(now) < 10)
        return;

    m_lastUploadTime = now;

    uploadCurrentAqiNow();
}

void AirQualityController::uploadCurrentAqiNow()
{
    m_serverStatus = "Uploading AQI...";
    emit serverStatusChanged();

    m_serverClient.uploadReading(
        m_deviceId,
        m_latitude,
        m_longitude,
        m_currentAirQuality
        );
}

void AirQualityController::updateFromSensorJson(const QString& json)
{
    QJsonParseError parseError;
    QJsonDocument document = QJsonDocument::fromJson(json.toUtf8(), &parseError);

    if (parseError.error != QJsonParseError::NoError || !document.isObject())
    {
        m_bluetoothStatus = "Bad Arduino JSON: " + json;
        emit bluetoothStatusChanged();
        return;
    }

    QJsonObject object = document.object();

    if (object.contains("AQI"))
        m_aqi = object["AQI"].toDouble();

    if (object.contains("Carbon_LEVEL"))
        m_carbonLevel = object["Carbon_LEVEL"].toDouble();

    if (object.contains("PM25"))
        m_pm25 = object["PM25"].toDouble();

    if (object.contains("TVOC_level"))
        m_tvoc = object["TVOC_level"].toDouble();

    m_currentAirQuality = m_aqi;
    m_hasSensorReading = true;

    emit sensorValuesChanged();
    emit currentAirQualityChanged();

    uploadCurrentAqiIfReady();
}

QString AirQualityController::makeDeviceId() const
{
    QByteArray id = QSysInfo::machineUniqueId();

    if (id.isEmpty())
        return AppConstants::DeviceId;

    return "PHONE_" + QString::fromUtf8(id.toHex()).left(16).toUpper();
}