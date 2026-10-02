import QtQuick 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 6.2
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 430
    height: 932
    minimumWidth: 390
    minimumHeight: 700
    title: "Airpal"
    color: "#E8E9F3"

    property bool showSplash: true
    property bool splashFadeOut: false

    Loader {
        id: splashLoader
        anchors.fill: parent
        active: root.showSplash
        source: "SplashScreen.qml"
        z: 100
        opacity: root.splashFadeOut ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 420; easing.type: Easing.InOutQuad }
        }
    }

    Timer {
        id: splashStartTimer
        interval: 2500
        running: true
        repeat: false
        onTriggered: {
            root.splashFadeOut = true
            splashRemoveTimer.start()
        }
    }

    Timer {
        id: splashRemoveTimer
        interval: 430
        repeat: false
        onTriggered: {
            root.showSplash = false
            splashLoader.active = false
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: true
        opacity: root.showSplash ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.OutQuad }
        }

        SwipeView {
            id: swipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            interactive: true
            clip: true

            MyAir {
                width: swipeView.width
                height: swipeView.height
            }

            CommunityMap {
                width: swipeView.width
                height: swipeView.height
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            color: "#E8E9F3"
            border.color: "#D2D3DD"
            border.width: 1

            TabBar {
                id: tabBar
                anchors.fill: parent
                currentIndex: swipeView.currentIndex
                background: Rectangle { color: "transparent" }

                TabButton {
                    id: myPalTab
                    text: "My Pal"

                    contentItem: ColumnLayout {
                        spacing: 5
                        Item {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignHCenter
                            AppIcon {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                name: "activity"
                                lineColor: myPalTab.checked ? "#272635" : "#A6A6A8"
                                lineWidth: 3
                            }
                        }
                        Text {
                            text: myPalTab.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: myPalTab.checked ? "#272635" : "#A6A6A8"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    background: Rectangle { color: "transparent" }
                }

                TabButton {
                    id: communityTab
                    text: "Community"

                    contentItem: ColumnLayout {
                        spacing: 5
                        Item {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignHCenter
                            AppIcon {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                name: "map"
                                lineColor: communityTab.checked ? "#272635" : "#A6A6A8"
                                lineWidth: 3
                            }
                        }
                        Text {
                            text: communityTab.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: communityTab.checked ? "#272635" : "#A6A6A8"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                    background: Rectangle { color: "transparent" }
                }
            }
        }
    }
}
