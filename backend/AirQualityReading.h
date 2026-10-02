#ifndef AIRQUALITYREADING_H
#define AIRQUALITYREADING_H

#include <QString>

struct AirQualityReading
{
    QString deviceId;
    double latitude;
    double longitude;
    double airQuality;
    QString timestamp;
};

#endif
