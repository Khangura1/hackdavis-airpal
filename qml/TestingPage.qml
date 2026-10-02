import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: testingPage

    signal goBack()

    background: Rectangle {
        color: "#20252b"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28

        spacing: 18

        Label {
            text: "Testing Information"

            color: "white"

            font.pixelSize: 30
            font.bold: true

            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 390

            radius: 18
            color: "#ffffff"

            border.width: 1
            border.color: "#000000"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18

                spacing: 10

                Label {
                    text: "Device ID:"
                    color: "#20252b"
                    font.pixelSize: 16
                    font.bold: true
                }

                Label {
                    text: airQualityController.deviceId
                    color: "#20252b"
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: "Latitude: " + airQualityController.latitude.toFixed(6)
                    color: "#20252b"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: "Longitude: " + airQualityController.longitude.toFixed(6)
                    color: "#20252b"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: "Location Status:"
                    color: "#20252b"
                    font.pixelSize: 16
                    font.bold: true
                }

                Label {
                    text: airQualityController.locationStatus
                    color: "#20252b"
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: "Server Status:"
                    color: "#20252b"
                    font.pixelSize: 16
                    font.bold: true
                }

                Label {
                    text: airQualityController.serverStatus
                    color: "#20252b"
                    font.pixelSize: 15
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: "Has Location: " + airQualityController.hasLocation
                    color: "#20252b"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: "Current Reading: " + airQualityController.currentAirQuality.toFixed(1)
                    color: "#20252b"
                    font.pixelSize: 16
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        Label {
            text: "Automatic upload every 10 seconds"

            color: "white"

            font.pixelSize: 17

            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            text: "Back"

            font.pixelSize: 17

            Layout.fillWidth: true
            height: 52

            onClicked: testingPage.goBack()
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
