#ifndef USB_DEV_MANAGER_H
#define USB_DEV_MANAGER_H

#include <QWidget>
#include <QMainWindow>
#include <QMessageBox>
#include <QFileDialog>
#include <QTime>

#include <qwt_plot.h>
#include <qwt_plot_curve.h>
#include <qwt_legend.h>

#include "ui_MainForm.h"
#include "SiUSBLib.h"


namespace Ui {
    class MainForm;
}

class MainForm : public QMainWindow
{
	Q_OBJECT

public:
	MainForm(QWidget *parent = 0, Qt::WindowFlags flags = 0);
	~MainForm();
	void onDeviceChange();
  void doflashEEPROM();

public slots:
	void openFPGADialog();
	void openEEPROMDialog();
	void openControllerDialog();
	void loadFPGA();
	void loadController();
	void flashEEPROM();
	void updateDeviceId();
	void listItemClicked(QTreeWidgetItem *item, int column);
	void showAbout();
	void refreshListClicked();
	void writeClicked();
	void readClicked();
  void selectMode(QString mode);
	void runBenchmark();
	void expertModeChanged();
	void runIntegrityTest();

private:
	Ui::MainForm *ui;
	QwtPlotCurve *curve1;
	QwtPlotCurve *curve2;

	SiUSBDevice *myUSBdev;
	QString EEPROMFileName;
	QString FPGAFileName;
	QString ControllerFileName;
	void UpdateDevList();
	void SetCurrentUSBDevice(int id);
	QIcon *silab_usb_ico;
  QList<QTreeWidgetItem *> devListItems;
  QTreeWidgetItem *currentItem;
	QAction *showAboutAct;
	QAction *expertModeAct;
	QAction *refreshListAct;
	void DisplayDeviceInfo();
	void createActions();

	static unsigned long MyThreadFunc(void* ptr);

};

#endif // USB_DEV_MANAGER_H
