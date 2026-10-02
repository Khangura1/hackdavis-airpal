import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: homePage

    signal openCommunityPage()

    background: Rectangle {
        color: "#eeeef8"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: availableWidth

            ColumnLayout {
                width: parent.width
                spacing: 22

                Item {
                    Layout.fillWidth: true
                    height: 28
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Airpal"
                            color: "#20202d"
                            font.pixelSize: 38
                            font.bold: true
                        }

                        Label {
                            text: "Your personal air quality trinket"
                            color: "#9b9ba3"
                            font.pixelSize: 18
                        }
                    }

                    Rectangle {
                        width: 76
                        height: 76
                        radius: 38
                        color: "white"

                        Label {
                            anchors.centerIn: parent
                            text: "Airpal"
                            color: "#20202d"
                            font.pixelSize: 18
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    height: 84
                    radius: 20

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ff3e3e" }
                        GradientStop { position: 1.0; color: "#ff7a1a" }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 18

                        Label {
                            text: "⚠"
                            color: "white"
                            font.pixelSize: 34
                            font.bold: true
                        }

                        Label {
                            text: airQualityController.pm25 >= 100
                                  ? "High Dust Levels Detected Nearby"
                                  : "Air Quality Levels Updating"

                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    height: 360
                    radius: 22
                    color: "white"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 26
                        spacing: 16

                        Label {
                            text: "Average Air Quality"
                            color: "#20202d"
                            font.pixelSize: 26
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "Based on all sensors"
                            color: "#9b9ba3"
                            font.pixelSize: 19
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 160

                            Rectangle {
                                width: 140
                                height: 140
                                radius: 70
                                color: "#ffc52e"
                                anchors.centerIn: parent

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0

                                    Label {
                                        text: airQualityController.aqi.toFixed(0)
                                        color: "white"
                                        font.pixelSize: 46
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Label {
                                        text: "AQI"
                                        color: "white"
                                        font.pixelSize: 18
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }
                        }

                        ProgressBar {
                            Layout.fillWidth: true
                            from: 0
                            to: 500
                            value: airQualityController.aqi
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: "0"
                                color: "#9b9ba3"
                                font.pixelSize: 18
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "Current: " + airQualityController.aqi.toFixed(0)
                                color: "#20202d"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "500"
                                color: "#9b9ba3"
                                font.pixelSize: 18
                            }
                        }
                    }
                }

                MetricCard {
                    title: "Carbon Level"
                    subtitle: "Equivalent CO₂"
                    valueText: airQualityController.carbonLevel.toFixed(0)
                    unitText: "ppm"
                    iconText: "▥"
                    barValue: airQualityController.carbonLevel
                    barMax: 2000
                }

                MetricCard {
                    title: "PM 2.5"
                    subtitle: "Particulate Matter"
                    valueText: airQualityController.pm25.toFixed(0)
                    unitText: "µg/m³"
                    iconText: "≋"
                    barValue: airQualityController.pm25
                    barMax: 180
                }

                MetricCard {
                    title: "TVOC"
                    subtitle: "Total Volatile Compounds"
                    valueText: airQualityController.tvoc.toFixed(0)
                    unitText: "ppb"
                    iconText: "♒"
                    barValue: airQualityController.tvoc
                    barMax: 500
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 28
                    height: 140
                    radius: 22
                    color: "#252435"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 12

                        Label {
                            text: "Recommendation"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                        }

                        Label {
                            text: airQualityController.pm25 >= 100
                                  ? "High particulate levels detected. Stay indoors and keep windows closed."
                                  : "Air quality is being monitored. Check nearby readings often."

                            color: "#e8e8ee"
                            font.pixelSize: 18
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    height: 20
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 76
            color: "#eeeef8"
            border.width: 1
            border.color: "#d8d8e0"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 36
                anchors.rightMargin: 36

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: "⌂"
                            color: "#20202d"
                            font.pixelSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "My Pal"
                            color: "#20202d"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: "◫"
                            color: "#9b9ba3"
                            font.pixelSize: 26
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "Community"
                            color: "#9b9ba3"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: homePage.openCommunityPage()
                    }
                }
            }
        }
    }

    component MetricCard: Rectangle {
        property string title: ""
        property string subtitle: ""
        property string valueText: ""
        property string unitText: ""
        property string iconText: ""
        property real barValue: 0
        property real barMax: 100

        Layout.fillWidth: true
        Layout.leftMargin: 28
        Layout.rightMargin: 28
        height: 240
        radius: 22
        color: "white"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 18

                Rectangle {
                    width: 58
                    height: 58
                    radius: 29
                    color: "#eeeef8"

                    Label {
                        anchors.centerIn: parent
                        text: iconText
                        color: "#20202d"
                        font.pixelSize: 26
                        font.bold: true
                    }
                }

                ColumnLayout {
                    spacing: 2

                    Label {
                        text: title
                        color: "#20202d"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Label {
                        text: subtitle
                        color: "#9b9ba3"
                        font.pixelSize: 17
                        font.bold: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: valueText
                    color: "#20202d"
                    font.pixelSize: 62
                    font.bold: true
                }

                Label {
                    text: unitText
                    color: "#9b9ba3"
                    font.pixelSize: 26
                    font.bold: true
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 14
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: barMax
                value: barValue
            }
        }
    }
}