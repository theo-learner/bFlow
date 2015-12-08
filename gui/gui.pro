#-------------------------------------------------
#
# Project created by QtCreator 2015-11-30T12:52:41
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = gui
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    ../src/database.cpp \
    ../src/similarity.cpp \
    ../src/birthmark.cpp \
    ../src/print.cpp

HEADERS  += mainwindow.h \
    ../src/database.hpp \
    ../src/similarity.hpp \
    ../src/birthmark.hpp \
    ../src/error.hpp \
    ../src/print.hpp

INCLUDEPATH += ../libs



FORMS    += mainwindow.ui

OTHER_FILES += \
    ../libs/rapidxml/manual.html

QMAKE_CXXFLAGS_RELEASE += -O3
