#include "main.h"
#include "MainForm.h"
#include <QApplication>

int main(int argc, char *argv[])
{
	MyQApplication app(argc, argv);
	//app.setWindowIcon(QPixmap(":/icons/resources/silab.ico"));
	/*
	app.setStyleSheet("QMainWindow {background-color:rgb(66, 66, 66)}" 
	                  "QMenuBar    {background-color:rgb(66, 66, 66); border: 1px solid black}"
                    "QMenuBar::item {spacing: 3px; padding: 1px 4px; background: transparent; border-radius: 4px}"
	                  "QMainWindow {background-color:rgb(66, 66, 66)}" );
	*/
//	MainForm *w = new MainForm();
	MainForm w;
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
