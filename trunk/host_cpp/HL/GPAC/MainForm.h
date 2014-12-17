#pragma once

#include "stdafx.h"
#include <qwidget.h>
#include <qobject.h>
#include <QFileDialog>
#include <QStatusBar>
#include <QTimer>

//#include "SimpleQWTPlot.h"
#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"
#include "SILIB_GPIB_Keithley24xx.h"

#include "HL_GPAC.h"
#include "TL_USB.h"
//#include "SilibDistributions.h"

#include "ui_mainform.h"

class MainForm :
	 public QWidget, protected Ui_MainForm
{

Q_OBJECT
public:
	MainForm(void);
	virtual ~MainForm(void);

public:
  void onDeviceChange();

public slots:
	void openFileDialog();
	void refreshGPIBList();
	void sendReceiveGPIB();
	void sendGPIB();
	void clearGPIB();
	void setSMUon();
	void setSMUoff();
	void setSMUval();
	void setSMUCout();
	void setSMUVout();
	void getSMUMeas();
	void calibrate();

	void enablePWR0(bool on_off);
	void enablePWR1(bool on_off);
	void enablePWR2(bool on_off);
	void enablePWR3(bool on_off);
	void setPWR0(double val);
	void setPWR1(double val);
	void setPWR2(double val);
	void setPWR3(double val);
	void setVSRC0(double val);
	void setVSRC1(double val);
	void setVSRC2(double val);
	void setVSRC3(double val);
	void setISRC0(double val);
	void setISRC1(double val);
	void setISRC2(double val);
	void setISRC3(double val);
	//void setISRC4(double val);
	//void setISRC5(double val);
	//void setISRC6(double val);
	//void setISRC7(double val);
	//void setISRC8(double val);
	//void setISRC9(double val);
	//void setISRC10(double val);
	//void setISRC11(double val);
	void updateMeasurements();
	void updateEEPROM();
	void dumpEEPROM();
	void setCurrLim();
	void setId();
	void enableTimer(bool yes_no);
	void change4WireSense(bool enable);
;
private:
//	TL_base *myUSB;
	TL_USB *myUSB;
	void * hUSB;
  TGPIB_Interface_USB *myGPIBIf;
  HL_GPAC	*myAnalogCard;
	TGPIB_Keithley24xx *mySMU;
	QString FPGAFileName;
	QTimer *timer;
	void UpdateSystem();
	void CalibrateAll();
	void CalibrateChannel(int ch);
	void Power(bool on_off, int channel = -1);
	void SelectChannel(unsigned char ch);
	bool checkChannel(int channel);

};

