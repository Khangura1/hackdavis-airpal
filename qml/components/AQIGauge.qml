import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 6.2

Rectangle {
    id: aqiGauge
    implicitHeight: 330
    radius: 18
    color: "white"

    function aqiColor(value) {
        if (value <= 50) return "#B1E5F2"
        if (value <= 100) return "#fbbf24"
        if (value <= 150) return "#f97316"
        if (value <= 200) return "#ef4444"
        if (value <= 300) return "#991b1b"
        return "#7f1d1d"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: metricInfoDrawer.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.topMargin: 30
        anchors.bottomMargin: 28
        spacing: 16

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                text: "Average Air Quality"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#272635"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Based on all sensors"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: "#A6A6A8"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 140

            Rectangle {
                width: 128
                height: 128
                radius: 64
                anchors.centerIn: parent
                color: "white"
                border.width: 8
                border.color: aqiGauge.aqiColor(airQualityController.aqi)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        text: airQualityController.aqi.toFixed(0)
                        font.pixelSize: 40
                        font.weight: Font.Bold
                        color: "#272635"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "AQI"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: "#A6A6A8"
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: "#CECECE"

                Rectangle {
                    width: parent.width * Math.min(airQualityController.aqi / 500, 1.0)
                    height: parent.height
                    radius: 4
                    color: aqiGauge.aqiColor(airQualityController.aqi)
                    Behavior on width { NumberAnimation { duration: 250 } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "0"; font.pixelSize: 13; font.weight: Font.DemiBold; color: "#A6A6A8" }
                Item { Layout.fillWidth: true }
                Text { text: "Current: " + airQualityController.aqi.toFixed(0); font.pixelSize: 13; font.weight: Font.Bold; color: "#272635" }
                Item { Layout.fillWidth: true }
                Text { text: "500"; font.pixelSize: 13; font.weight: Font.DemiBold; color: "#A6A6A8" }
            }
        }
    }

    MetricInfoDrawer {
        id: metricInfoDrawer
        metricType: "aqi"
    }
}
