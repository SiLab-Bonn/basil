#ifndef GPAC_EXAMPLE_H
#define GPAC_EXAMPLE_H

#include <QMainWindow>
#include <QTimer>
#include <QFileDialog>
#include <iomanip> 

#include "ui_gpac_example.h"

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"
#include "SILIB_GPIB_Keithley24xx.h"

#include "HL_GPAC.h"
#include "TL_USB.h"

// constrants for calibration routines
  #define DAC_LOW  1000
  #define DAC_HIGH 3000
  #define DAC_MID  2048 
  #define SMU_CURRENT_VERY_LOW  0.0001 // A
  #define SMU_CURRENT_LOW  0.001 // A
  #define SMU_CURRENT_HIGH 0.1   // A
  #define SMU_VOLTAGE_LOW  0.1
  #define SMU_VOLTAGE_MID  1.0
  #define SMU_VOLTAGE_HIGH 2.0
  #define SMU_VOLTAGE_COMPLIANCE 4.0  // V
  #define SMU_CURRENT_COMPLIANCE 0.1  // A
  #define GPAC_CURRENT     100 // µA
  #define GPAC_VOLTAGE     1800 // mV
  #define SETTLING_TIME  100 
  #define N_CAL_SAMPLES  8

// FPGA registers	
  #define DOUTL_REG_ADDR 0x40
  #define DOUTH_REG_ADDR 0x50
  #define DIN_REG_ADDR   0x30
  #define LVDS_REG_ADDR  0x60
  #define INJECT_REG     0x70

class GPAC_Example : public QMainWindow
{
	Q_OBJECT

public:
	GPAC_Example(QWidget *parent = 0);
	~GPAC_Example();

  void onDeviceChange();

public slots:
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
	void setISRC4(double val);
	void setISRC5(double val);
	void setISRC6(double val);
	void setISRC7(double val);
	void setISRC8(double val);
	void setISRC9(double val);
	void setISRC10(double val);
	void setISRC11(double val);
	void updateMeasurements();
	void setCurrLim();
	void enableTimer(bool yes_no);
	void initGPIB();
	void calibrateAll();
	void saveCalibrationData();
	void eraseEEPROM();
	void saveCalibrationDataToFile();
	void loadCalibrationDataFromFile();
	void ConfFPGADialog();
	void writeGPIO();
	void testDIO();
	void testAnalog();
	void selectCalMux();

private:
	Ui::GPAC_ExampleClass ui;
	SiUSBDevice	*myUSBdev;
	TL_USB  *myTLUSB;
  HL_GPAC	*myAnalogCard;
  PowerSupply   *PWR[MAX_PWR];
	VoltageSource *VSRC[MAX_VSRC];
	InjVoltageSource *VINJ[MAX_VINJ];
	CurrentSource *ISRC[MAX_ISRC];

	QTimer  *timer;
	TGPIB_Keithley24xx *mySMU;
  TGPIB_Interface_USB *myGPIBIf;

	void UI2HW();
	void UpdateSystem();
	void CalibrateAll();
	void writeReg(int add, unsigned char *data);
	void readReg(int add, unsigned char *data);
};

#endif // GPAC_EXAMPLE_H
