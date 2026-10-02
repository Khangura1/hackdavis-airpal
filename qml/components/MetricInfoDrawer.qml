import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 6.2

Drawer {
    id: drawer

    property string metricType: "aqi"
    property var metricInfo: getMetricInfo()

    width: parent ? parent.width : 430
    height: parent ? Math.min(parent.height * 0.62, 520) : 500
    edge: Qt.BottomEdge
    modal: true
    dim: true

    background: Rectangle {
        color: "#E8E9F3"
        radius: 24

        Rectangle {
            width: 48
            height: 6
            radius: 3
            color: "#CECECE"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12
        }
    }

    function getMetricInfo() {
        var info = {
            "aqi": {
                title: "Air Quality Index (AQI)",
                unit: "",
                ranges: [
                    { label: "Good", range: "0-50", color: "#B1E5F2", description: "Air quality is good" },
                    { label: "Moderate", range: "51-100", color: "#fbbf24", description: "Acceptable air quality" },
                    { label: "Unhealthy for Sensitive", range: "101-150", color: "#f97316", description: "Sensitive groups affected" },
                    { label: "Unhealthy", range: "151-200", color: "#ef4444", description: "Everyone may experience effects" },
                    { label: "Very Unhealthy", range: "201-300", color: "#991b1b", description: "Health alert" },
                    { label: "Hazardous", range: "301-500", color: "#7f1d1d", description: "Emergency conditions" }
                ]
            },
            "carbon": {
                title: "Carbon Level (eCO₂)",
                unit: "ppm",
                ranges: [
                    { label: "Good", range: "400-1000", color: "#B1E5F2", description: "Normal outdoor air quality" },
                    { label: "Moderate", range: "1000-3000", color: "#fbbf24", description: "May cause drowsiness" },
                    { label: "Poor", range: "3000-5000", color: "#f97316", description: "Can cause headaches and fatigue" },
                    { label: "Unhealthy", range: "5000+", color: "#ef4444", description: "Serious health concerns" }
                ]
            },
            "pm25": {
                title: "PM 2.5 (Particulate Matter)",
                unit: "μg/m³",
                ranges: [
                    { label: "Good", range: "0-12", color: "#B1E5F2", description: "Air quality is satisfactory" },
                    { label: "Moderate", range: "12.1-35.4", color: "#fbbf24", description: "Acceptable for most" },
                    { label: "Unhealthy", range: "35.5-55.4", color: "#f97316", description: "Sensitive groups affected" },
                    { label: "Very Unhealthy", range: "55.5+", color: "#ef4444", description: "Health warnings" }
                ]
            },
            "tvoc": {
                title: "TVOC",
                unit: "ppb",
                ranges: [
                    { label: "Good", range: "0-220", color: "#B1E5F2", description: "No irritation or discomfort" },
                    { label: "Moderate", range: "220-660", color: "#fbbf24", description: "Possible irritation" },
                    { label: "Poor", range: "660-2200", color: "#f97316", description: "Irritation and headaches" },
                    { label: "Unhealthy", range: "2200+", color: "#ef4444", description: "Severe health effects" }
                ]
            }
        }
        return info[metricType] || info["aqi"]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.topMargin: 54
        anchors.bottomMargin: 20
        spacing: 18

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: metricInfo.title
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    color: "#272635"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: "Understanding the values"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#A6A6A8"
                }
            }

            Button {
                id: closeButton
                text: "×"
                flat: true
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                background: Rectangle {
                    radius: 27
                    color: "#D6D6D8"
                }
                contentItem: Text {
                    text: closeButton.text
                    font.pixelSize: 28
                    color: "#272635"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: drawer.close()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: drawer.width - 60
                spacing: 10

                Repeater {
                    model: metricInfo.ranges

                    Rectangle {
                        Layout.fillWidth: true
                        height: 70
                        radius: 14
                        color: "white"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            spacing: 5

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: modelData.color
                                }

                                Text {
                                    text: modelData.label
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                    color: "#272635"
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: modelData.range + (metricInfo.unit === "" ? "" : " " + metricInfo.unit)
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    color: "#A6A6A8"
                                }
                            }

                            Text {
                                text: modelData.description
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: "#A6A6A8"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
