#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QObject>
#include <QString>
#include <QByteArray>
#include <QBluetoothDeviceInfo>
#include <QBluetoothUuid>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <QLowEnergyCharacteristic>

class QBluetoothDeviceDiscoveryAgent;

class BluetoothManager : public QObject
{
    Q_OBJECT

public:
    explicit BluetoothManager(QObject* parent = nullptr);
    ~BluetoothManager();

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();
    Q_INVOKABLE void disconnectFromArduino();

signals:
    void statusChanged(const QString& status);
    void jsonReceived(const QString& json);

private slots:
    void onDeviceDiscovered(const QBluetoothDeviceInfo& device);
    void onScanFinished();
    void onScanError();

    void onControllerConnected();
    void onControllerDisconnected();
    void onControllerError(QLowEnergyController::Error error);

    void onServiceDiscovered(const QBluetoothUuid& serviceUuid);
    void onServiceDiscoveryFinished();

    void onServiceStateChanged(QLowEnergyService::ServiceState state);

    void onCharacteristicChanged(const QLowEnergyCharacteristic& characteristic,
                                 const QByteArray& value);

    void onCharacteristicRead(const QLowEnergyCharacteristic& characteristic,
                              const QByteArray& value);

private:
    void connectToDevice(const QBluetoothDeviceInfo& device);
    void cleanup();

    void processIncomingBytes(const QByteArray& value);
    void processReceiveBuffer();
    void emitJsonMessage(const QByteArray& message);
    int findCompleteJsonEnd(const QByteArray& data) const;

    static const QString ArduinoName;
    static const QBluetoothUuid ServiceUuid;
    static const QBluetoothUuid CharacteristicUuid;

    QBluetoothDeviceDiscoveryAgent* m_discoveryAgent;
    QLowEnergyController* m_controller;
    QLowEnergyService* m_service;
    QLowEnergyCharacteristic m_jsonCharacteristic;

    QByteArray m_receiveBuffer;

    bool m_foundArduino;
    bool m_foundService;
};

#endif