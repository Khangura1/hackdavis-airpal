import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 6.2
import Qt.labs.settings 1.1
import "components"

ScrollView {
    id: myAirView
    width: parent ? parent.width : 430
    height: parent ? parent.height : 850
    contentWidth: width
    clip: true

    property string airpalName: appSettings.airpalName

    Settings {
        id: appSettings
        category: "Airpal"
        property string airpalName: "Your Airpal"
    }

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    function aqiColor(value) {
        if (value <= 50) return "#B1E5F2"
        if (value <= 100) return "#fbbf24"
        if (value <= 150) return "#f97316"
        if (value <= 200) return "#ef4444"
        if (value <= 300) return "#991b1b"
        return "#7f1d1d"
    }

    function carbonColor(value) {
        if (value <= 1000) return "#B1E5F2"
        if (value <= 3000) return "#fbbf24"
        if (value <= 5000) return "#f97316"
        return "#ef4444"
    }

    function pm25Color(value) {
        if (value <= 12) return "#B1E5F2"
        if (value <= 35.4) return "#fbbf24"
        if (value <= 55.4) return "#f97316"
        return "#ef4444"
    }

    function tvocColor(value) {
        if (value <= 220) return "#B1E5F2"
        if (value <= 660) return "#fbbf24"
        if (value <= 2200) return "#f97316"
        return "#ef4444"
    }

    function recommendation() {
        if (airQualityController.pm25 > 55.4)
            return "High particulate levels detected. Stay indoors and keep windows closed."

        if (airQualityController.carbonLevel > 1000)
            return "CO₂ levels are elevated. Consider ventilation if it is safe."

        if (airQualityController.tvoc > 660)
            return "Volatile organic compounds are elevated. Check for chemical sources."

        if (airQualityController.aqi > 100)
            return "Air quality may affect sensitive groups. Limit prolonged outdoor exposure."

        if (airQualityController.aqi === 0 &&
            airQualityController.pm25 === 0 &&
            airQualityController.carbonLevel === 0 &&
            airQualityController.tvoc === 0)
            return "Waiting for your Airpal sensor data from Bluetooth."

        return "Air quality is good. Safe to ventilate your space."
    }

    Dialog {
        id: renameDialog

        title: "Rename Airpal"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay

        onOpened: {
            nameField.text = myAirView.airpalName
            nameField.forceActiveFocus()
            nameField.selectAll()
        }

        onAccepted: {
            var cleanedName = nameField.text.trim()

            if (cleanedName.length > 0) {
                appSettings.airpalName = cleanedName
                myAirView.airpalName = cleanedName
            }
        }

        background: Rectangle {
            radius: 18
            color: "white"
            border.width: 1
            border.color: "#d8e8f7"
        }

        contentItem: ColumnLayout {
            width: 280
            spacing: 12

            Text {
                text: "Enter a new name for your Airpal."
                font.pixelSize: 14
                color: "#272635"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            TextField {
                id: nameField
                Layout.fillWidth: true
                placeholderText: "Airpal name"
                maximumLength: 24
                selectByMouse: true

                background: Rectangle {
                    radius: 10
                    color: "#E8E9F3"
                    border.width: 1
                    border.color: "#B1E5F2"
                }

                onAccepted: {
                    renameDialog.accept()
                }
            }
        }
    }

    Rectangle {
        width: myAirView.width
        implicitHeight: contentColumn.implicitHeight
        color: "#E8E9F3"

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                color: "#E8E9F3"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    anchors.topMargin: 26
                    anchors.bottomMargin: 14
                    spacing: 14

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: myAirView.airpalName.length > 0 ? myAirView.airpalName : "Your Airpal"
                                    font.pixelSize: 26
                                    font.weight: Font.Bold
                                    color: "#272635"
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 230
                                }

                                Text {
                                    text: "●"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: "#A6A6A8"
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Text {
                                text: "Your personal airpal"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#A6A6A8"
                            }

                            Text {
                                text: airQualityController.bluetoothStatus
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#A6A6A8"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                renameDialog.open()
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        color: "white"
                        clip: true

                        Image {
                            anchors.centerIn: parent
                            width: 58
                            height: 58
                            source: "qrc:/resources/images/airpal.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }
                }
            }

            StatusBanner {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 0
            }

            AQIGauge {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 16
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 16
                spacing: 16

                MetricCard {
                    Layout.fillWidth: true
                    metricTitle: "Carbon Level"
                    metricSubtitle: "Equivalent CO₂"
                    metricValue: airQualityController.carbonLevel
                    metricUnit: "ppm"
                    metricColor: carbonColor(airQualityController.carbonLevel)
                    maxValue: 5000
                    showWarning: airQualityController.carbonLevel > 1000
                    iconName: "factory"
                    metricType: "carbon"
                }

                MetricCard {
                    Layout.fillWidth: true
                    metricTitle: "PM 2.5"
                    metricSubtitle: "Particulate Matter"
                    metricValue: airQualityController.pm25
                    metricUnit: "μg/m³"
                    metricColor: pm25Color(airQualityController.pm25)
                    maxValue: 75
                    showWarning: airQualityController.pm25 > 35.4
                    iconName: "wind"
                    metricType: "pm25"
                }

                MetricCard {
                    Layout.fillWidth: true
                    metricTitle: "TVOC"
                    metricSubtitle: "Total Volatile Compounds"
                    metricValue: airQualityController.tvoc
                    metricUnit: "ppb"
                    metricColor: tvocColor(airQualityController.tvoc)
                    maxValue: 2200
                    showWarning: airQualityController.tvoc > 660
                    iconName: "droplet"
                    metricType: "tvoc"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 18
                Layout.preferredHeight: adviceColumn.implicitHeight + 46
                radius: 16
                color: "#272635"

                ColumnLayout {
                    id: adviceColumn
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 12

                    Text {
                        text: "Recommendation"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "white"
                    }

                    Text {
                        text: recommendation()
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: "#E8E9F3"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.35
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 28
                Layout.rightMargin: 28
                Layout.topMargin: 18
                Layout.bottomMargin: 28
                Layout.preferredHeight: statusColumn.implicitHeight + 36
                radius: 16
                color: "white"

                ColumnLayout {
                    id: statusColumn
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 8

                    Text {
                        text: "Connection Status"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: "#272635"
                    }

                    Text {
                        text: airQualityController.bluetoothStatus
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#A6A6A8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        text: airQualityController.serverStatus
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#A6A6A8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            id: refreshButton
                            text: "Refresh Map"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            background: Rectangle {
                                radius: 10
                                color: "#B1E5F2"
                            }

                            contentItem: Text {
                                text: refreshButton.text
                                color: "#272635"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                airQualityController.refreshCommunityReadings()
                            }
                        }
                    }
                }
            }
        }
    }
}