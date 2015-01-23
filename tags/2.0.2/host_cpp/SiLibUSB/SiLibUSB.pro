include(../USBpix.pri)

TEMPLATE = lib
CONFIG += dll thread debug_and_release
DEPENDPATH += . \
              ../inc 
              
INCLUDEPATH += . \
               ../inc 

HEADERS +=  
           winusb2libusb.h \
           SiI2CDevice.h \
           SiSPIDevice.h \
           SiUSBDevice.h \
           SiUSBDeviceManager.h \
           SiXilinxChip.h
SOURCES += interface_libusb.cpp \
           SiI2CDevice.cpp \
           SiUSBDevice.cpp \
           SiUSBDeviceManager.cpp \
           SiUSBLib.cpp \
           SiXilinxChip.cpp

TARGET = siusb

win32 {
    DEFINES += __VISUALC__ \
               DLL_EXPORT \
               _WIN32 \
               WIN32 \
               NO_ERROR_MESSAGES \
               _CRT_SECURE_NO_WARNINGS \
               _WINDLL
    DEFINES -= UNICODE
#	TARGET = SiUSB
    CONFIG(debug, debug|release) {
        TARGET = $$join(TARGET,,,$${DEBUG_SUFFIX})
    }
	DLLDESTDIR = ../bin
	DESTDIR = ../lib
	LIBS += user32.lib \
	        kernel32.lib \
	        gdi32.lib \
	        winspool.lib \
	        comdlg32.lib \
	        advapi32.lib \
	        shell32.lib \
	        ole32.lib \
	        oleaut32.lib \
	        uuid.lib \
	        odbc32.lib \
	        odbccp32.lib
	contains(QMAKE_HOST.arch, x86_64) {
	LIBS += ./libusb_windows_backend/x64/libusb-1.0.lib
	system(copy /Y .\libusb_windows_backend\x64\libusb-1.0.dll ..\bin)
	} else {
	LIBS += ./libusb_windows_backend/x86/libusb-1.0.lib
	system(copy /Y .\libusb_windows_backend\x86\libusb-1.0.dll ..\bin)
	}	
}

unix {
    DEFINES += CF__LINUX \
#               DFreeBSD \
               _REENTRANT \
               _FORTIFY_SOURCE=2
	QMAKE_CXXFLAGS += -g -ggdb
#    TARGET = SiUSB
    CONFIG(debug, debug|release) {
        TARGET = $$join(TARGET,,,$${DEBUG_SUFFIX})
	}
    DESTDIR = ../lib
    LIBS += -lusb-1.0 -lpthread
}
