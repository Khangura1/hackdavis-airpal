QT -= gui

CONFIG += c++11 console
CONFIG -= app_bundle

QT += core network

SOURCES += \
    main.cpp \
    qAQMS.cpp

HEADERS += \
    qAQMS.h \
    qAQMSConst.h

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target