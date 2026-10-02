#include "DeviceIdProvider.h"

#include <QNetworkInterface>
#include <QSettings>
#include <QUuid>

QString DeviceIdProvider::getDeviceId()
{
    QString macAddress = getNetworkMacAddress();

    if (!macAddress.isEmpty())
        return macAddress;

    return getSavedGeneratedMacAddress();
}

QString DeviceIdProvider::getNetworkMacAddress()
{
    QList<QNetworkInterface> interfaces = QNetworkInterface::allInterfaces();

    for (const QNetworkInterface& interface : interfaces)
    {
        bool isUp = interface.flags().testFlag(QNetworkInterface::IsUp);
        bool isLoopback = interface.flags().testFlag(QNetworkInterface::IsLoopBack);

        if (!isUp || isLoopback)
            continue;

        QString macAddress = interface.hardwareAddress();

        if (macAddress.isEmpty())
            continue;

        if (macAddress == "00:00:00:00:00:00")
            continue;

        return macAddress;
    }

    return "";
}

QString DeviceIdProvider::getSavedGeneratedMacAddress()
{
    QSettings settings;

    QString savedId = settings.value("device_id").toString();

    if (!savedId.isEmpty())
        return savedId;

    QString newId = generateMacLikeId();

    settings.setValue("device_id", newId);
    settings.sync();

    return newId;
}

QString DeviceIdProvider::generateMacLikeId()
{
    QByteArray uuidBytes = QUuid::createUuid().toRfc4122();

    QList<QString> parts;

    for (int i = 0; i < 6; ++i)
    {
        unsigned char value = static_cast<unsigned char>(uuidBytes[i]);
        parts.append(QString("%1").arg(value, 2, 16, QChar('0')).toUpper());
    }

    return parts.join(":");
}