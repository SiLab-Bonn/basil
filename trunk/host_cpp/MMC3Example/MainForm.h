#pragma once

#include <iomanip>

// Qt libs
#include <qwidget.h>
#include <qobject.h>
#include <QFileDialog>
#include <QStatusBar>
#include <QMainWindow>
// Qt GUI
#include "ui_MainForm.h"

// USB lib
#include "SiLibUSB.h"
#include "TL_USB.h"
// basil modules
#include "basil_gpio.h"

namespace Ui {
    class MainForm;
}

class MainForm : public QMainWindow
{
Q_OBJECT
public:
  MainForm(QWidget *parent = 0);
  ~MainForm(void);

public:
  void onDeviceChange();

public slots:
	void openFileDialog();
	void confFPGA();
	void readClicked();
	void writeClicked();
;

private:
  Ui::MainForm *ui;
	SiUSBDevice  *myUSBdev;
	TL_USB       *myTLUSB;
	basil_gpio   *GPIO1;
	QString FPGAFileName;
	void UpdateSystem();

};

