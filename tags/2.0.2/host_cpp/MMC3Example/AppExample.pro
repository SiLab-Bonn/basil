HEADERS += MainForm.h \
main.h \
SiLibUSB.h

SOURCES += main.cpp \
MainForm.cpp

FORMS = MainForm.ui

RESOURCES += SiUSBman.qrc

#CONFIG += QwtDll 
equals(QT_MAJOR_VERSION, 5) {
  QT += widgets
  QT += core
}

INCLUDEPATH += $(QWTDIR)/src \
  ../inc \
  ./resources

TEMPLATE = app

DESTDIR = ../bin

CONFIG(debug, debug|release){
    win32 {
        DEFINES += WIN32 INITGUID DEBUG
        LIBS += $(QWTDIR)/lib/qwtd.lib ../lib/SiLibUSBd.lib user32.lib
    }
    unix {
        DEFINES += CF__LINUX
        LIBS += -L$(QWTDIR)/lib -lqwt -L$(USBCMN)/lib -ldsiusb
    }
}
else {
    win32 {
        DEFINES += WIN32 INITGUID 
        LIBS += $(QWTDIR)/lib/qwt.lib ../lib/SiLibUSB.lib user32.lib
    }
    unix {
        DEFINES += CF__LINUX
        LIBS += -L$(QWTDIR)/lib -lqwt -L$(USBCMN)/lib -lsiusb
    }
}
