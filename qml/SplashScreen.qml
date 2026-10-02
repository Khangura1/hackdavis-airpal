import QtQuick 6.2
import QtQuick.Controls 6.2

Rectangle {
    id: splashScreen
    anchors.fill: parent
    color: "#E8E9F3"

    // Soft blue glow behind the title, like the mockup screenshot
    Rectangle {
        id: blueGlow
        width: Math.min(parent.width * 0.55, 260)
        height: width
        radius: width / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 55
        opacity: 0.32
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#99B1E5F2" }
            GradientStop { position: 0.55; color: "#33B1E5F2" }
            GradientStop { position: 1.0; color: "#00B1E5F2" }
        }

        SequentialAnimation on scale {
            running: true
            loops: Animation.Infinite
            NumberAnimation { from: 0.95; to: 1.08; duration: 1500; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1.08; to: 0.95; duration: 1500; easing.type: Easing.InOutQuad }
        }
    }

    Item {
        id: splashContent
        width: parent.width
        height: 430
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 25
        opacity: 0
        scale: 0.96

        OpacityAnimator on opacity {
            from: 0
            to: 1
            duration: 650
            easing.type: Easing.OutQuad
            running: true
        }

        ScaleAnimator on scale {
            from: 0.96
            to: 1.0
            duration: 700
            easing.type: Easing.OutBack
            running: true
        }

        Column {
            anchors.centerIn: parent
            spacing: 26

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Image {
                    id: logoImage
                    width: 92
                    height: 92
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "qrc:/resources/images/airpal.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true

                    SequentialAnimation on y {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { from: -4; to: 4; duration: 1100; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 4; to: -4; duration: 1100; easing.type: Easing.InOutQuad }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0
                    Text {
                        text: "air"
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        color: "#2F80ED"
                    }
                    Text {
                        text: "pal"
                        font.pixelSize: 34
                        font.weight: Font.Bold
                        color: "#081A44"
                    }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    text: "Airpal"
                    font.pixelSize: 44
                    font.weight: Font.Bold
                    color: "#272635"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Your personal air quality companion"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: "#A6A6A8"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                topPadding: 22

                Repeater {
                    model: 3
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#B1E5F2"

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: true
                            PauseAnimation { duration: index * 180 }
                            NumberAnimation { from: 0.35; to: 1.0; duration: 450; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.0; to: 0.35; duration: 450; easing.type: Easing.InOutQuad }
                        }

                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            running: true
                            PauseAnimation { duration: index * 180 }
                            NumberAnimation { from: 0.75; to: 1.15; duration: 450; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.15; to: 0.75; duration: 450; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }
    }
}
