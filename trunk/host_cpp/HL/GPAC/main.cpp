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
		app.doRegisterForDevNotification();
    MyForm.show();
    return app.exec();
}