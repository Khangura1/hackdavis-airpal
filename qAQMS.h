#ifndef QAQMS_H
#define QAQMS_H

#include <QObject>
#include <QString>
#include <QMap>

class QTcpServer;
class QTcpSocket;
class QJsonObject;

struct AirQualityReading
{
    QString deviceId;
    double latitude;
    double longitude;
    double airQuality;
    QString timestamp;
};

class QAQMS : public QObject
{
    Q_OBJECT

public:
    explicit QAQMS(QObject* parent = 0);
    ~QAQMS();

    bool Init();

public slots:
    void NewConnection();
    void ReadClientData();

protected:
    QString GetCurrentTime();

private:
    QTcpServer* m_pServer;
    QMap<QString, AirQualityReading> m_readings;

    QByteArray HandleRequest(const QByteArray& data);
    QByteArray HandleUpload(const QJsonObject& obj);
    QByteArray HandleGetAll();
    QByteArray HandleClearAll();
    QByteArray MakeOk();
    QByteArray MakeError(const QString& message);

    bool LoadReadings();
    bool SaveReadings();
};

#endif