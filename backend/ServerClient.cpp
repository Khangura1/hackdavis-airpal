#include "ServerClient.h"
#include "AppConstants.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>

ServerClient::ServerClient(QObject* parent)
    : QObject(parent)
    , m_socket(new QTcpSocket(this))
    , m_requestType(NoRequest)
    , m_waitingForResponse(false)
{
    connect(m_socket, &QTcpSocket::connected,
            this, &ServerClient::onConnected);

    connect(m_socket, &QTcpSocket::readyRead,
            this, &ServerClient::onReadyRead);

    connect(m_socket, &QTcpSocket::disconnected,
            this, &ServerClient::onDisconnected);

    connect(m_socket, &QTcpSocket::errorOccurred,
            this, &ServerClient::onErrorOccurred);
}

void ServerClient::uploadReading(const QString& deviceId,
                                 double latitude,
                                 double longitude,
                                 double airQuality)
{
    QJsonObject object;

    object["type"] = "upload";
    object["device_id"] = deviceId;
    object["latitude"] = latitude;
    object["longitude"] = longitude;
    object["air_quality"] = airQuality;

    sendRequest(object, UploadRequest);
}

void ServerClient::getAllReadings()
{
    QJsonObject object;

    object["type"] = "get_all";

    sendRequest(object, GetAllRequest);
}

void ServerClient::sendRequest(const QJsonObject& object, RequestType requestType)
{
    if (m_waitingForResponse)
        return;

    QJsonDocument document(object);

    m_requestData = document.toJson(QJsonDocument::Compact);
    m_responseData.clear();
    m_requestType = requestType;
    m_waitingForResponse = true;

    m_socket->abort();
    m_socket->connectToHost(AppConstants::ServerIp, AppConstants::ServerPort);
}

void ServerClient::onConnected()
{
    m_socket->write(m_requestData);
    m_socket->flush();
}

void ServerClient::onReadyRead()
{
    m_responseData += m_socket->readAll();
}

void ServerClient::onDisconnected()
{
    finishRequest(m_responseData);
}

void ServerClient::onErrorOccurred(QAbstractSocket::SocketError socketError)
{
    if (!m_waitingForResponse)
        return;

    if (socketError == QAbstractSocket::RemoteHostClosedError)
    {
        return;
    }

    QString message = m_socket->errorString();
    RequestType finishedType = m_requestType;

    m_waitingForResponse = false;
    m_requestType = NoRequest;

    if (finishedType == UploadRequest)
    {
        emit uploadFinished(false, message);
    }
    else if (finishedType == GetAllRequest)
    {
        emit getAllFinished(false, message, QVariantList());
    }
}

void ServerClient::finishRequest(const QByteArray& data)
{
    if (!m_waitingForResponse)
        return;

    RequestType finishedType = m_requestType;

    m_waitingForResponse = false;
    m_requestType = NoRequest;

    QJsonParseError parseError;
    QJsonDocument document = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError || !document.isObject())
    {
        if (finishedType == UploadRequest)
        {
            emit uploadFinished(false, "Invalid server response: " + QString::fromUtf8(data));
        }
        else if (finishedType == GetAllRequest)
        {
            emit getAllFinished(false, "Invalid server response: " + QString::fromUtf8(data), QVariantList());
        }

        return;
    }

    QJsonObject object = document.object();
    QString status = object["status"].toString();

    if (status != "ok")
    {
        QString message = object["message"].toString("Server error");

        if (finishedType == UploadRequest)
        {
            emit uploadFinished(false, message);
        }
        else if (finishedType == GetAllRequest)
        {
            emit getAllFinished(false, message, QVariantList());
        }

        return;
    }

    if (finishedType == UploadRequest)
    {
        emit uploadFinished(true, "Upload successful");
    }
    else if (finishedType == GetAllRequest)
    {
        emit getAllFinished(true, "Readings loaded", parseDevices(object));
    }
}

QVariantList ServerClient::parseDevices(const QJsonObject& object) const
{
    QVariantList readings;

    QJsonArray devices = object["devices"].toArray();

    for (int i = 0; i < devices.size(); ++i)
    {
        QJsonObject device = devices[i].toObject();
        QVariantMap reading;

        reading["device_id"] = device["device_id"].toString();
        reading["latitude"] = device["latitude"].toDouble();
        reading["longitude"] = device["longitude"].toDouble();
        reading["air_quality"] = device["air_quality"].toDouble();
        reading["timestamp"] = device["timestamp"].toString();

        readings.append(reading);
    }

    return readings;
}