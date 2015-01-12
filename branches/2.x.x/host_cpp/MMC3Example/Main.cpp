#include <QFont>
#include <QPushButton>
#include <QWidget>

#include "Main.h"
#include "MainForm.h"

int main(int argc, char *argv[])
{
    MyQApplication app(argc, argv);
    MainForm MyForm;
    app.myMainForm = &MyForm;
#ifdef WIN32
  app.doRegisterForDevNotification();
  #if QT_VERSION > 0x050000
	 app.installNativeEventFilter(&app);
  #endif	 
#endif
    MyForm.show();
    return app.exec();
}
