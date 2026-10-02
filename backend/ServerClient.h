#ifndef SERVERCLIENT_H
#define SERVERCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QJsonObject>
#include <QVariantList>

class ServerClient : public QObject
{
    Q_OBJECT

public:
    explicit ServerClient(QObject* parent = nullptr);

    void uploadReading(const QString& deviceId,
                       double latitude,
                       double longitude,
                       double airQuality);

    void getAllReadings();

signals:
    void uploadFinished(bool success, const QString& message);
    void getAllFinished(bool success, const QString& message, const QVariantList& readings);

private slots:
    void onConnected();
    void onReadyRead();
    void onDisconnected();
    void onErrorOccurred(QAbstractSocket::SocketError socketError);

private:
    enum RequestType
    {
        NoRequest,
        UploadRequest,
        GetAllRequest
    };

    QTcpSocket* m_socket;
    QByteArray m_responseData;
    QByteArray m_requestData;
    RequestType m_requestType;
    bool m_waitingForResponse;

    void sendRequest(const QJsonObject& object, RequestType requestType);
    void finishRequest(const QByteArray& data);
    QVariantList parseDevices(const QJsonObject& object) const;
};

#endif
