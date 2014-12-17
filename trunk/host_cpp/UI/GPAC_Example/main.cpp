#include "main.h"
#include "gpac_example.h"
#include <QApplication>

int main(int argc, char *argv[])
{
	MyQApplication app(argc, argv);
	GPAC_Example w;
	app.myMainForm = &w;
#ifdef WIN32
	app.doRegisterForDevNotification();
  #if QT_VERSION > 0x050000
	  app.installNativeEventFilter(&app);
  #endif	
#endif
	w.show();
	return app.exec();
}
