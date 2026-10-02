import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtLocation
import QtPositioning

Item {
    id: root

    property real defaultLatitude: 38.5449
    property real defaultLongitude: -121.7405

    Rectangle {
        anchors.fill: parent
        color: "#EEF0FA"
    }

    Plugin {
        id: osmPlugin
        name: "osm"

        PluginParameter {
            name: "osm.useragent"
            value: "Airpal HackDavis App"
        }
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 26
        anchors.rightMargin: 26
        anchors.topMargin: 58
        anchors.bottomMargin: 16
        spacing: 16

        Column {
            width: parent.width
            spacing: 6

            Text {
                text: "Community"
                color: "#20202D"
                font.pixelSize: 54
                font.bold: true
            }

            Text {
                text: airQualityController.communityStatus
                color: "#9696A0"
                font.pixelSize: 22
                wrapMode: Text.WordWrap
                width: parent.width
            }
        }

        Rectangle {
            id: mapCard
            width: parent.width
            height: parent.height - 150
            radius: 28
            color: "white"
            clip: true

            Map {
                id: communityMap
                anchors.fill: parent
                plugin: osmPlugin

                center: QtPositioning.coordinate(root.defaultLatitude, root.defaultLongitude)
                zoomLevel: 13
                minimumZoomLevel: 3
                maximumZoomLevel: 19

                Component.onCompleted: {
                    centerOnBestLocation()
                    airQualityController.refreshCommunityReadings()
                }

                function readingLatitude(reading) {
                    return Number(reading["latitude"])
                }

                function readingLongitude(reading) {
                    return Number(reading["longitude"])
                }

                function readingAqi(reading) {
                    return Number(reading["air_quality"])
                }

                function centerOnBestLocation() {
                    if (airQualityController.latitude !== 0 && airQualityController.longitude !== 0) {
                        communityMap.center = QtPositioning.coordinate(
                                    airQualityController.latitude,
                                    airQualityController.longitude)
                        communityMap.zoomLevel = 14
                        return
                    }

                    if (airQualityController.communityReadings.length > 0) {
                        var first = airQualityController.communityReadings[0]
                        communityMap.center = QtPositioning.coordinate(
                                    readingLatitude(first),
                                    readingLongitude(first))
                        communityMap.zoomLevel = 13
                        return
                    }

                    communityMap.center = QtPositioning.coordinate(root.defaultLatitude, root.defaultLongitude)
                    communityMap.zoomLevel = 13
                }

                DragHandler {
                    id: mapDragHandler
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

                            communityMap.pan(-dx, -dy)

                            lastX = centroid.position.x
                            lastY = centroid.position.y
                        }
                    }
                }

                PinchHandler {
                    id: pinchHandler
                    target: null

                    property real startZoom: 13

                    onActiveChanged: {
                        if (active) {
                            startZoom = communityMap.zoomLevel
                        }
                    }

                    onScaleChanged: {
                        if (active) {
                            var newZoom = startZoom + Math.log(scale) / Math.log(2)
                            communityMap.zoomLevel = Math.max(
                                        communityMap.minimumZoomLevel,
                                        Math.min(communityMap.maximumZoomLevel, newZoom))
                        }
                    }
                }

                WheelHandler {
                    id: wheelHandler
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                    onWheel: function(event) {
                        var change = event.angleDelta.y > 0 ? 0.25 : -0.25

                        communityMap.zoomLevel = Math.max(
                                    communityMap.minimumZoomLevel,
                                    Math.min(communityMap.maximumZoomLevel,
                                             communityMap.zoomLevel + change))

                        event.accepted = true
                    }
                }

                MapQuickItem {
                    id: currentLocationMarker

                    coordinate: QtPositioning.coordinate(
                                    airQualityController.latitude,
                                    airQualityController.longitude)

                    visible: airQualityController.latitude !== 0 &&
                             airQualityController.longitude !== 0

                    anchorPoint.x: currentLocationDot.width / 2
                    anchorPoint.y: currentLocationDot.height / 2
                    zoomLevel: 0
                    z: 10

                    sourceItem: Rectangle {
                        id: currentLocationDot
                        width: 18
                        height: 18
                        radius: 9
                        color: "#2563EB"
                        border.color: "white"
                        border.width: 3
                    }
                }

                MapItemView {
                    model: airQualityController.communityReadings

                    delegate: MapQuickItem {
                        coordinate: QtPositioning.coordinate(
                                        Number(modelData["latitude"]),
                                        Number(modelData["longitude"]))

                        anchorPoint.x: markerBubble.width / 2
                        anchorPoint.y: markerBubble.height / 2
                        zoomLevel: 0
                        z: 5

                        sourceItem: Rectangle {
                            id: markerBubble

                            width: 46
                            height: 46
                            radius: 23
                            color: getAqiColor(Number(modelData["air_quality"]))
                            border.color: "white"
                            border.width: 3

                            Text {
                                anchors.centerIn: parent
                                text: Math.round(Number(modelData["air_quality"]))
                                color: "#20202D"
                                font.pixelSize: 16
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    infoPopup.aqi = Number(modelData["air_quality"])
                                    infoPopup.latitudeText = Number(modelData["latitude"]).toFixed(6)
                                    infoPopup.longitudeText = Number(modelData["longitude"]).toFixed(6)
                                    infoPopup.timestampText = modelData["timestamp"]
                                    infoPopup.open()
                                }
                            }

                            function getAqiColor(aqi) {
                                if (aqi <= 50)
                                    return "#B1E5F2"
                                if (aqi <= 100)
                                    return "#F7C948"
                                if (aqi <= 150)
                                    return "#FF8A3D"
                                return "#FF3B3B"
                            }
                        }
                    }
                }
            }

            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 18
                anchors.topMargin: 18
                spacing: 12
                z: 50

                Button {
                    width: 58
                    height: 58

                    background: Rectangle {
                        radius: 29
                        color: "#E8E9F3"
                        border.color: "#D2D3DD"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: "+"
                        color: "#20202D"
                        font.pixelSize: 34
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        communityMap.zoomLevel = Math.min(
                                    communityMap.maximumZoomLevel,
                                    communityMap.zoomLevel + 1)
                    }
                }

                Button {
                    width: 58
                    height: 58

                    background: Rectangle {
                        radius: 29
                        color: "#E8E9F3"
                        border.color: "#D2D3DD"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: "●"
                        color: "#20202D"
                        font.pixelSize: 23
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        communityMap.centerOnBestLocation()
                    }
                }

                Button {
                    width: 58
                    height: 58

                    background: Rectangle {
                        radius: 29
                        color: "#E8E9F3"
                        border.color: "#D2D3DD"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: "−"
                        color: "#20202D"
                        font.pixelSize: 34
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        communityMap.zoomLevel = Math.max(
                                    communityMap.minimumZoomLevel,
                                    communityMap.zoomLevel - 1)
                    }
                }
            }
        }
    }

    Connections {
        target: airQualityController

        function onCommunityReadingsChanged() {
            if (airQualityController.communityReadings.length > 0) {
                var first = airQualityController.communityReadings[0]

                communityMap.center = QtPositioning.coordinate(
                            Number(first["latitude"]),
                            Number(first["longitude"]))

                communityMap.zoomLevel = 13
            }
        }

        function onLocationChanged() {
            currentLocationMarker.coordinate = QtPositioning.coordinate(
                        airQualityController.latitude,
                        airQualityController.longitude)
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true

        onTriggered: {
            airQualityController.refreshCommunityReadings()
        }
    }

    Dialog {
        id: infoPopup

        property real aqi: 0
        property string latitudeText: ""
        property string longitudeText: ""
        property string timestampText: ""

        title: "Air Quality Reading"
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay

        background: Rectangle {
            radius: 18
            color: "white"
            border.color: "#D2D3DD"
            border.width: 1
        }

        contentItem: ColumnLayout {
            width: 290
            spacing: 10

            Text {
                text: "AQI: " + Math.round(infoPopup.aqi)
                color: "#20202D"
                font.pixelSize: 32
                font.bold: true
            }

            Text {
                text: "Status: " + getStatusText(infoPopup.aqi)
                color: getAqiColor(infoPopup.aqi)
                font.pixelSize: 17
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Location: " + infoPopup.latitudeText + ", " + infoPopup.longitudeText
                color: "#60606A"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                text: "Time: " + infoPopup.timestampText
                color: "#60606A"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            function getAqiColor(aqi) {
                if (aqi <= 50)
                    return "#4AAFD8"
                if (aqi <= 100)
                    return "#D9A700"
                if (aqi <= 150)
                    return "#E56B1F"
                return "#D92D2D"
            }

            function getStatusText(aqi) {
                if (aqi <= 50)
                    return "Good"
                if (aqi <= 100)
                    return "Moderate"
                if (aqi <= 150)
                    return "Unhealthy for Sensitive Groups"
                return "Unhealthy"
            }
        }
    }
}