#ifndef AIRQUALITYCONTROLLER_H
#define AIRQUALITYCONTROLLER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QDateTime>
#include <QGeoPositionInfoSource>

#include "ServerClient.h"
#include "BluetoothManager.h"

class AirQualityController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(double currentAirQuality READ currentAirQuality NOTIFY currentAirQualityChanged)
    Q_PROPERTY(double aqi READ aqi NOTIFY sensorValuesChanged)
    Q_PROPERTY(double carbonLevel READ carbonLevel NOTIFY sensorValuesChanged)
    Q_PROPERTY(double pm25 READ pm25 NOTIFY sensorValuesChanged)
    Q_PROPERTY(double tvoc READ tvoc NOTIFY sensorValuesChanged)

    Q_PROPERTY(QString serverStatus READ serverStatus NOTIFY serverStatusChanged)
    Q_PROPERTY(QString bluetoothStatus READ bluetoothStatus NOTIFY bluetoothStatusChanged)
    Q_PROPERTY(QString locationStatus READ locationStatus NOTIFY locationStatusChanged)
    Q_PROPERTY(QString communityStatus READ communityStatus NOTIFY communityStatusChanged)

    Q_PROPERTY(QString deviceId READ deviceId NOTIFY deviceIdChanged)
    Q_PROPERTY(double latitude READ latitude NOTIFY locationChanged)
    Q_PROPERTY(double longitude READ longitude NOTIFY locationChanged)

    Q_PROPERTY(QVariantList communityReadings READ communityReadings NOTIFY communityReadingsChanged)

public:
    explicit AirQualityController(QObject* parent = nullptr);

    double currentAirQuality() const;
    double aqi() const;
    double carbonLevel() const;
    double pm25() const;
    double tvoc() const;

    QString serverStatus() const;
    QString bluetoothStatus() const;
    QString locationStatus() const;
    QString communityStatus() const;

    QString deviceId() const;
    double latitude() const;
    double longitude() const;

    QVariantList communityReadings() const;

    Q_INVOKABLE void startBluetooth();
    Q_INVOKABLE void stopBluetooth();
    Q_INVOKABLE void refreshCommunityReadings();
    Q_INVOKABLE void createFakeReadingAndUpload();

signals:
    void currentAirQualityChanged();
    void sensorValuesChanged();

    void serverStatusChanged();
    void bluetoothStatusChanged();
    void locationStatusChanged();
    void communityStatusChanged();

    void deviceIdChanged();
    void locationChanged();
    void communityReadingsChanged();

private slots:
    void onArduinoJsonReceived(const QString& json);
    void onBluetoothStatusChanged(const QString& status);

    void onUploadFinished(bool success, const QString& message);
    void onGetAllFinished(bool success, const QString& message, const QVariantList& readings);

    void onPositionUpdated(const QGeoPositionInfo& info);
    void onPositionError(QGeoPositionInfoSource::Error error);

private:
    void setupLocation();
    void uploadCurrentAqiIfReady();
    void uploadCurrentAqiNow();
    void updateFromSensorJson(const QString& json);
    QString makeDeviceId() const;

    ServerClient m_serverClient;
    BluetoothManager m_bluetoothManager;
    QGeoPositionInfoSource* m_positionSource;

    double m_currentAirQuality;
    double m_aqi;
    double m_carbonLevel;
    double m_pm25;
    double m_tvoc;

    QString m_serverStatus;
    QString m_bluetoothStatus;
    QString m_locationStatus;
    QString m_communityStatus;
    QString m_deviceId;

    double m_latitude;
    double m_longitude;
    bool m_hasLocation;
    bool m_hasSensorReading;

    QVariantList m_communityReadings;

    QDateTime m_lastUploadTime;
};

#endif