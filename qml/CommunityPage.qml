import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

Page {
    id: communityPage

    signal goHome()

    background: Rectangle {
        color: "#eef4fb"
    }

    Component.onCompleted: {
        airQualityController.refreshCommunityReadings()
    }

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            height: 112
            color: "#eef4fb"

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 28
                anchors.topMargin: 24
                spacing: 4

                Label {
                    text: "Community"
                    color: "#1f2633"
                    font.pixelSize: 38
                    font.bold: true
                }

                Label {
                    text: airQualityController.communityStatus
                    color: "#7f8fa6"
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.bottomMargin: 12
            radius: 26
            color: "#f8fbff"
            clip: true
            border.width: 1
            border.color: "#d8e8f7"

            Map {
                id: map

                anchors.fill: parent
                anchors.margins: 8

                plugin: mapPlugin

                center: QtPositioning.coordinate(
                            airQualityController.latitude,
                            airQualityController.longitude
                        )

                zoomLevel: 13
                copyrightsVisible: true

                DragHandler {
                    id: dragHandler
                    target: null

                    property real lastX: 0
                    property real lastY: 0

                    onActiveChanged: {
                        lastX = centroid.position.x
                        lastY = centroid.position.y
                    }

                    onCentroidChanged: {
                        if (active) {
                            var dx = centroid.position.x - lastX
                            var dy = centroid.position.y - lastY

                            map.pan(-dx, -dy)

                            lastX = centroid.position.x
                            lastY = centroid.position.y
                        }
                    }
                }

                MapItemView {
                    model: airQualityController.communityReadings

                    delegate: MapQuickItem {
                        coordinate: QtPositioning.coordinate(
                                        Number(modelData["latitude"]),
                                        Number(modelData["longitude"])
                                    )

                        anchorPoint.x: marker.width / 2
                        anchorPoint.y: marker.height / 2

                        sourceItem: Rectangle {
                            id: marker

                            width: 58
                            height: 58
                            radius: 29

                            color: {
                                var aqi = Number(modelData["air_quality"])

                                if (aqi >= 150)
                                    return "#d95c75"

                                if (aqi >= 100)
                                    return "#ff7b7b"

                                if (aqi >= 50)
                                    return "#78b7ff"

                                return "#66d6a3"
                            }

                            border.width: 4
                            border.color: "white"

                            Label {
                                anchors.centerIn: parent
                                text: Number(modelData["air_quality"]).toFixed(0)
                                color: "white"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    markerPopup.deviceText = modelData["device_id"]
                                    markerPopup.aqiText = Number(modelData["air_quality"]).toFixed(1)
                                    markerPopup.latitudeText = Number(modelData["latitude"]).toFixed(6)
                                    markerPopup.longitudeText = Number(modelData["longitude"]).toFixed(6)
                                    markerPopup.timestampText = modelData["timestamp"]
                                    markerPopup.open()
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 20
                anchors.topMargin: 20
                spacing: 10
                z: 20

                Button {
                    text: "+"
                    width: 52
                    height: 52

                    background: Rectangle {
                        radius: 26
                        color: "#d5e7f7"
                        border.width: 1
                        border.color: "#bdd8ef"
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#1f2633"
                        font.pixelSize: 28
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: map.zoomLevel = Math.min(20, map.zoomLevel + 1)
                }

                Button {
                    text: "−"
                    width: 52
                    height: 52

                    background: Rectangle {
                        radius: 26
                        color: "#d5e7f7"
                        border.width: 1
                        border.color: "#bdd8ef"
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#1f2633"
                        font.pixelSize: 28
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: map.zoomLevel = Math.max(2, map.zoomLevel - 1)
                }
            }

            Button {
                id: centerLocationButton

                width: 58
                height: 58
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22
                anchors.bottomMargin: 22
                z: 20

                text: "●"

                background: Rectangle {
                    radius: 29
                    color: "#d5e7f7"
                    border.width: 1
                    border.color: "#bdd8ef"
                }

                contentItem: Text {
                    text: parent.text
                    color: "#1f2633"
                    font.pixelSize: 22
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    map.center = QtPositioning.coordinate(
                                airQualityController.latitude,
                                airQualityController.longitude
                            )
                    map.zoomLevel = 15
                }
            }

            Button {
                id: refreshButton

                width: 58
                height: 58
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 22
                anchors.bottomMargin: 22
                z: 20

                text: "⟳"

                background: Rectangle {
                    radius: 29
                    color: "#d5e7f7"
                    border.width: 1
                    border.color: "#bdd8ef"
                }

                contentItem: Text {
                    text: parent.text
                    color: "#1f2633"
                    font.pixelSize: 34
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: airQualityController.refreshCommunityReadings()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 76
            color: "#eef4fb"
            border.width: 1
            border.color: "#d1e1f0"

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
                            color: "#94a3b8"
                            font.pixelSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "My Pal"
                            color: "#94a3b8"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: communityPage.goHome()
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
                            color: "#1f2633"
                            font.pixelSize: 26
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: "Community"
                            color: "#1f2633"
                            font.pixelSize: 15
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        Timer {
            interval: 10000
            running: communityPage.visible
            repeat: true

            onTriggered: airQualityController.refreshCommunityReadings()
        }
    }

    Dialog {
        id: markerPopup

        property string deviceText: ""
        property string aqiText: ""
        property string latitudeText: ""
        property string longitudeText: ""
        property string timestampText: ""

        title: "Air Quality Reading"
        modal: true
        standardButtons: Dialog.Ok

        background: Rectangle {
            color: "#f8fbff"
            radius: 18
            border.width: 1
            border.color: "#d8e8f7"
        }

        ColumnLayout {
            width: 280
            spacing: 10

            Label {
                text: "AQI: " + markerPopup.aqiText
                font.pixelSize: 28
                font.bold: true
                color: "#1f2633"
            }

            Label {
                text: "Device: " + markerPopup.deviceText
                color: "#1f2633"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Label {
                text: "Latitude: " + markerPopup.latitudeText
                color: "#1f2633"
                Layout.fillWidth: true
            }

            Label {
                text: "Longitude: " + markerPopup.longitudeText
                color: "#1f2633"
                Layout.fillWidth: true
            }

            Label {
                text: "Timestamp: " + markerPopup.timestampText
                color: "#7f8fa6"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}