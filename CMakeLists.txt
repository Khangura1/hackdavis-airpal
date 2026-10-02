cmake_minimum_required(VERSION 3.21)

project(AirDavisApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Network Positioning Location Bluetooth)

qt_standard_project_setup()

qt_add_executable(appAirDavisApp
    main.cpp

    backend/AppConstants.h
    backend/AirQualityReading.h

    backend/ServerClient.h
    backend/ServerClient.cpp

    backend/BluetoothManager.h
    backend/BluetoothManager.cpp

    backend/AirQualityController.h
    backend/AirQualityController.cpp
)

set_target_properties(appAirDavisApp PROPERTIES
    QT_ANDROID_APP_NAME "Airpal"
    QT_ANDROID_APP_ICON "@drawable/icon"
)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/android")
    set_target_properties(appAirDavisApp PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    )
endif()

qt_add_resources(appAirDavisApp "app_resources"
    PREFIX "/"
    FILES
        qml/Main.qml
        qml/SplashScreen.qml
        qml/MyAir.qml
        qml/CommunityMap.qml

        qml/components/AppIcon.qml
        qml/components/AQIGauge.qml
        qml/components/MetricCard.qml
        qml/components/MetricInfoDrawer.qml
        qml/components/StatusBanner.qml

        resources/images/airpal.png
        resources/images/PNG_image.png
)

target_include_directories(appAirDavisApp PRIVATE backend)

if(ANDROID)
    qt_add_android_permission(appAirDavisApp
        NAME android.permission.INTERNET
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.ACCESS_NETWORK_STATE
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.ACCESS_FINE_LOCATION
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.ACCESS_COARSE_LOCATION
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.BLUETOOTH
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.BLUETOOTH_ADMIN
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.BLUETOOTH_SCAN
    )

    qt_add_android_permission(appAirDavisApp
        NAME android.permission.BLUETOOTH_CONNECT
    )
endif()

target_link_libraries(appAirDavisApp
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Network
        Qt6::Positioning
        Qt6::Location
        Qt6::Bluetooth
)