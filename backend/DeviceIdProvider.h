#ifndef DEVICEIDPROVIDER_H
#define DEVICEIDPROVIDER_H

#include <QString>

class DeviceIdProvider
{
public:
    static QString getDeviceId();

private:
    static QString getNetworkMacAddress();
    static QString getSavedGeneratedMacAddress();
    static QString generateMacLikeId();
};

#endif