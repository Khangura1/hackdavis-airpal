import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 6.2

Rectangle {
    id: statusBanner
    implicitHeight: 64
    radius: 16

    property bool isWarning: airQualityController.aqi > 100 || airQualityController.pm25 > 35.4 || airQualityController.carbonLevel > 1000 || airQualityController.tvoc > 660
    property string bannerText: airQualityController.pm25 > 35.4 ? "High Dust Levels Detected Nearby" : (isWarning ? "Air Quality Warning Detected" : "Air Quality is Good")

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: isWarning ? "#ef4444" : "#B1E5F2" }
        GradientStop { position: 1.0; color: isWarning ? "#f97316" : "#10b981" }
    }

    SequentialAnimation on opacity {
        running: isWarning
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 0.94; duration: 700 }
        NumberAnimation { from: 0.94; to: 1.0; duration: 700 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 20
        spacing: 16

        AppIcon {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            name: isWarning ? "warning" : "wind"
            lineColor: "white"
            lineWidth: 3
        }

        Text {
            text: bannerText
            font.pixelSize: 15
            font.weight: Font.Bold
            color: "white"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
