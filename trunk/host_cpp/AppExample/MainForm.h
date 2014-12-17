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

// Qwt libs
#include <qwt_plot.h>
#include <qwt_plot_curve.h>
#include <qwt_legend.h>

// USB lib
#include "SiLibUSB.h"

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
	void plotData();
	void readClicked();
	void writeClicked();
;

private:
  Ui::MainForm *ui;
	SiUSBDevice *myUSBdev;
	QString FPGAFileName;
	void UpdateSystem();
	QwtPlotCurve *curve1;
	QwtPlotCurve *curve2;

};

