import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 6.2

Rectangle {
    id: metricCard

    property string metricTitle: "Metric"
    property string metricSubtitle: "Description"
    property real metricValue: 0
    property string metricUnit: ""
    property string metricColor: "#B1E5F2"
    property real maxValue: 100
    property bool showWarning: false
    property string iconName: "activity"
    property string metricType: ""

    implicitHeight: 176
    radius: 18
    color: "white"

    MouseArea {
        anchors.fill: parent
        onClicked: metricInfoDrawer.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 20
        anchors.bottomMargin: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 54
                radius: 27
                color: "#E8E9F3"

                AppIcon {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    name: metricCard.iconName
                    lineColor: "#272635"
                    lineWidth: 3
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: metricTitle
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: "#272635"
                }

                Text {
                    text: metricSubtitle
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#A6A6A8"
                }
            }

            Text {
                visible: showWarning
                text: "⚠"
                font.pixelSize: 24
                color: "#ef4444"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Text {
                text: metricValue % 1 === 0 ? metricValue.toFixed(0) : metricValue.toFixed(1)
                font.pixelSize: 48
                font.weight: Font.Bold
                color: "#272635"
            }

            Text {
                text: metricUnit
                font.pixelSize: 22
                font.weight: Font.DemiBold
                color: "#A6A6A8"
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 8
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: "#CECECE"

            Rectangle {
                width: parent.width * Math.min(metricValue / maxValue, 1.0)
                height: parent.height
                radius: 4
                color: metricColor
                Behavior on width { NumberAnimation { duration: 250 } }
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }
    }

    MetricInfoDrawer {
        id: metricInfoDrawer
        metricType: metricCard.metricType
    }
}
