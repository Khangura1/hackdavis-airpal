#include "BluetoothManager.h"

#include <QBluetoothDeviceDiscoveryAgent>
#include <QLowEnergyDescriptor>
#include <QTimer>
#include <QDebug>

const QString BluetoothManager::ArduinoName = "AirQualityMonitor";

const QBluetoothUuid BluetoothManager::ServiceUuid(
    QStringLiteral("19b10000-e8f2-537e-4f6c-d104768a1214")
    );

const QBluetoothUuid BluetoothManager::CharacteristicUuid(
    QStringLiteral("19b10001-e8f2-537e-4f6c-d104768a1214")
    );

BluetoothManager::BluetoothManager(QObject* parent)
    : QObject(parent)
    , m_discoveryAgent(nullptr)
    , m_controller(nullptr)
    , m_service(nullptr)
    , m_foundArduino(false)
    , m_foundService(false)
{
}

BluetoothManager::~BluetoothManager()
{
    stopScan();
    cleanup();
}

void BluetoothManager::startScan()
{
    stopScan();
    cleanup();

    m_foundArduino = false;
    m_foundService = false;
    m_receiveBuffer.clear();

    emit statusChanged("Scanning for AirQualityMonitor...");

    m_discoveryAgent = new QBluetoothDeviceDiscoveryAgent(this);

    connect(m_discoveryAgent,
            &QBluetoothDeviceDiscoveryAgent::deviceDiscovered,
            this,
            &BluetoothManager::onDeviceDiscovered);

    connect(m_discoveryAgent,
            &QBluetoothDeviceDiscoveryAgent::finished,
            this,
            &BluetoothManager::onScanFinished);

    connect(m_discoveryAgent,
            &QBluetoothDeviceDiscoveryAgent::canceled,
            this,
            &BluetoothManager::onScanFinished);

    connect(m_discoveryAgent,
            &QBluetoothDeviceDiscoveryAgent::errorOccurred,
            this,
            &BluetoothManager::onScanError);

    m_discoveryAgent->start(QBluetoothDeviceDiscoveryAgent::LowEnergyMethod);
}

void BluetoothManager::stopScan()
{
    if (m_discoveryAgent)
    {
        if (m_discoveryAgent->isActive())
            m_discoveryAgent->stop();

        m_discoveryAgent->deleteLater();
        m_discoveryAgent = nullptr;
    }
}

void BluetoothManager::disconnectFromArduino()
{
    if (m_controller)
    {
        emit statusChanged("Disconnecting from Arduino...");
        m_controller->disconnectFromDevice();
    }
}

void BluetoothManager::onDeviceDiscovered(const QBluetoothDeviceInfo& device)
{
    qDebug() << "BLE device found:" << device.name() << device.address().toString();

    if (device.name().compare(ArduinoName, Qt::CaseInsensitive) != 0)
        return;

    m_foundArduino = true;

    emit statusChanged("Found AirQualityMonitor. Connecting...");

    stopScan();
    connectToDevice(device);
}

void BluetoothManager::onScanFinished()
{
    if (!m_foundArduino)
    {
        emit statusChanged("AirQualityMonitor not found. Retrying...");
        QTimer::singleShot(3000, this, &BluetoothManager::startScan);
    }
}

void BluetoothManager::onScanError()
{
    QString message = "Bluetooth scan error";

    if (m_discoveryAgent)
        message += ": " + m_discoveryAgent->errorString();

    emit statusChanged(message);

    QTimer::singleShot(3000, this, &BluetoothManager::startScan);
}

void BluetoothManager::connectToDevice(const QBluetoothDeviceInfo& device)
{
    cleanup();

    m_controller = QLowEnergyController::createCentral(device, this);

    connect(m_controller,
            &QLowEnergyController::connected,
            this,
            &BluetoothManager::onControllerConnected);

    connect(m_controller,
            &QLowEnergyController::disconnected,
            this,
            &BluetoothManager::onControllerDisconnected);

    connect(m_controller,
            &QLowEnergyController::serviceDiscovered,
            this,
            &BluetoothManager::onServiceDiscovered);

    connect(m_controller,
            &QLowEnergyController::discoveryFinished,
            this,
            &BluetoothManager::onServiceDiscoveryFinished);

    connect(m_controller,
            &QLowEnergyController::errorOccurred,
            this,
            &BluetoothManager::onControllerError);

    m_controller->connectToDevice();
}

void BluetoothManager::onControllerConnected()
{
    emit statusChanged("Connected. Discovering BLE services...");
    m_controller->discoverServices();
}

void BluetoothManager::onControllerDisconnected()
{
    emit statusChanged("Arduino disconnected. Retrying...");
    cleanup();

    QTimer::singleShot(3000, this, &BluetoothManager::startScan);
}

void BluetoothManager::onControllerError(QLowEnergyController::Error error)
{
    Q_UNUSED(error)

    QString message = "Bluetooth controller error";

    if (m_controller)
        message += ": " + m_controller->errorString();

    emit statusChanged(message);

    cleanup();

    QTimer::singleShot(3000, this, &BluetoothManager::startScan);
}

void BluetoothManager::onServiceDiscovered(const QBluetoothUuid& serviceUuid)
{
    qDebug() << "BLE service found:" << serviceUuid.toString();

    if (serviceUuid == ServiceUuid)
    {
        m_foundService = true;
        emit statusChanged("Air quality BLE service found");
    }
}

void BluetoothManager::onServiceDiscoveryFinished()
{
    if (!m_foundService)
    {
        emit statusChanged("Air quality BLE service not found");
        return;
    }

    if (!m_controller)
        return;

    m_service = m_controller->createServiceObject(ServiceUuid, this);

    if (!m_service)
    {
        emit statusChanged("Could not create BLE service object");
        return;
    }

    connect(m_service,
            &QLowEnergyService::stateChanged,
            this,
            &BluetoothManager::onServiceStateChanged);

    connect(m_service,
            &QLowEnergyService::characteristicChanged,
            this,
            &BluetoothManager::onCharacteristicChanged);

    connect(m_service,
            &QLowEnergyService::characteristicRead,
            this,
            &BluetoothManager::onCharacteristicRead);

    emit statusChanged("Discovering BLE characteristic...");
    m_service->discoverDetails();
}

void BluetoothManager::onServiceStateChanged(QLowEnergyService::ServiceState state)
{
    if (state != QLowEnergyService::RemoteServiceDiscovered)
        return;

    m_jsonCharacteristic = m_service->characteristic(CharacteristicUuid);

    if (!m_jsonCharacteristic.isValid())
    {
        emit statusChanged("Arduino JSON characteristic not found");
        return;
    }

    QLowEnergyDescriptor notifyDescriptor =
        m_jsonCharacteristic.descriptor(
            QBluetoothUuid(QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration)
            );

    if (!notifyDescriptor.isValid())
    {
        emit statusChanged("BLE notify descriptor not found");
        return;
    }

    m_service->writeDescriptor(notifyDescriptor, QByteArray::fromHex("0100"));
    m_service->readCharacteristic(m_jsonCharacteristic);

    emit statusChanged("Connected to Arduino. Waiting for JSON...");
}

void BluetoothManager::onCharacteristicChanged(const QLowEnergyCharacteristic& characteristic,
                                               const QByteArray& value)
{
    if (characteristic.uuid() != CharacteristicUuid)
        return;

    qDebug() << "BLE raw chunk:" << value;

    processIncomingBytes(value);
}

void BluetoothManager::onCharacteristicRead(const QLowEnergyCharacteristic& characteristic,
                                            const QByteArray& value)
{
    onCharacteristicChanged(characteristic, value);
}

void BluetoothManager::processIncomingBytes(const QByteArray& value)
{
    if (value.isEmpty())
        return;

    m_receiveBuffer.append(value);

    if (m_receiveBuffer.size() > 4096)
    {
        m_receiveBuffer.clear();
        emit statusChanged("Bluetooth buffer cleared");
        return;
    }

    processReceiveBuffer();
}

void BluetoothManager::processReceiveBuffer()
{
    while (!m_receiveBuffer.isEmpty())
    {
        int newlineIndex = m_receiveBuffer.indexOf('\n');

        if (newlineIndex >= 0)
        {
            QByteArray line = m_receiveBuffer.left(newlineIndex).trimmed();
            m_receiveBuffer.remove(0, newlineIndex + 1);

            if (!line.isEmpty())
                emitJsonMessage(line);

            continue;
        }

        int objectStart = m_receiveBuffer.indexOf('{');

        if (objectStart < 0)
        {
            if (m_receiveBuffer.size() > 128)
                m_receiveBuffer.clear();

            return;
        }

        if (objectStart > 0)
            m_receiveBuffer.remove(0, objectStart);

        int objectEnd = findCompleteJsonEnd(m_receiveBuffer);

        if (objectEnd < 0)
            return;

        QByteArray json = m_receiveBuffer.left(objectEnd + 1).trimmed();
        m_receiveBuffer.remove(0, objectEnd + 1);

        emitJsonMessage(json);
    }
}

int BluetoothManager::findCompleteJsonEnd(const QByteArray& data) const
{
    int depth = 0;
    bool insideString = false;
    bool escaped = false;

    for (int i = 0; i < data.size(); ++i)
    {
        char c = data.at(i);

        if (insideString)
        {
            if (escaped)
            {
                escaped = false;
            }
            else if (c == '\\')
            {
                escaped = true;
            }
            else if (c == '"')
            {
                insideString = false;
            }

            continue;
        }

        if (c == '"')
        {
            insideString = true;
        }
        else if (c == '{')
        {
            ++depth;
        }
        else if (c == '}')
        {
            --depth;

            if (depth == 0)
                return i;
        }
    }

    return -1;
}

void BluetoothManager::emitJsonMessage(const QByteArray& message)
{
    QString json = QString::fromUtf8(message).trimmed();

    if (json.isEmpty())
        return;

    qDebug() << "BLE complete JSON:" << json;

    emit statusChanged("Received Arduino JSON");
    emit jsonReceived(json);
}

void BluetoothManager::cleanup()
{
    if (m_service)
    {
        m_service->deleteLater();
        m_service = nullptr;
    }

    if (m_controller)
    {
        m_controller->disconnectFromDevice();
        m_controller->deleteLater();
        m_controller = nullptr;
    }

    m_jsonCharacteristic = QLowEnergyCharacteristic();
    m_receiveBuffer.clear();
    m_foundService = false;
}