#include "gpac_example.h"


GPAC_Example::GPAC_Example(QWidget *parent)
	: QMainWindow(parent)
{
  ui.setupUi(this);
  connect(ui.PWR0CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR0(bool)));
  connect(ui.PWR1CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR1(bool)));
  connect(ui.PWR2CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR2(bool)));
  connect(ui.PWR3CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR3(bool)));
  connect(ui.PWR0spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR0(double)));
  connect(ui.PWR1spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR1(double)));
  connect(ui.PWR2spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR2(double)));
  connect(ui.PWR3spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR3(double)));
  connect(ui.VSRC0spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC0(double)));
  connect(ui.VSRC1spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC1(double)));
  connect(ui.VSRC2spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC2(double)));
  connect(ui.VSRC3spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC3(double)));
  connect(ui.ISRC0spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC0(double)));
  connect(ui.ISRC1spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC1(double)));
  connect(ui.ISRC2spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC2(double)));
  connect(ui.ISRC3spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC3(double)));
  connect(ui.ISRC4spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC4(double)));
  connect(ui.ISRC5spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC5(double)));
  connect(ui.ISRC6spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC6(double)));
  connect(ui.ISRC7spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC7(double)));
  connect(ui.ISRC8spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC8(double)));
  connect(ui.ISRC9spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC9(double)));
  connect(ui.ISRC10spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC10(double)));
  connect(ui.ISRC11spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC11(double)));
  connect(ui.CurrLimBox, SIGNAL(valueChanged(double)), this, SLOT(setCurrLim()));

	connect(ui.InitGPIBBtn, SIGNAL(clicked()), this, SLOT(initGPIB()));
	connect(ui.CalBtn, SIGNAL(clicked()), this, SLOT(calibrateAll()));
	connect(ui.WriteEEPROMBtn, SIGNAL(clicked()), this, SLOT(saveCalibrationData()));
	connect(ui.EraseEEPROMBtn, SIGNAL(clicked()), this, SLOT(eraseEEPROM()));
	connect(ui.SaveFileBtn, SIGNAL(clicked()), this, SLOT(saveCalibrationDataToFile()));
	connect(ui.LoadFileBtn, SIGNAL(clicked()), this, SLOT(loadCalibrationDataFromFile()));
	connect(ui.confFPGABtn, SIGNAL(clicked()), this, SLOT(ConfFPGADialog()));
	connect(ui.wrGpioBtn, SIGNAL(clicked()), this, SLOT(writeGPIO()));
	connect(ui.digitalTestBtn, SIGNAL(clicked()), this, SLOT(testDIO()));
	connect(ui.analogTestBtn, SIGNAL(clicked()), this, SLOT(testAnalog()));
	connect(ui.CalMuxSpinBox,SIGNAL(valueChanged(int)), this, SLOT(selectCalMux()));

#ifndef CALIBRATION_MODE
  ui.calibrationBox->hide();
#endif

  InitUSB();             // init USB device manager
	myUSBdev = new SiUSBDevice(NULL);
	myTLUSB = new TL_USB(myUSBdev);  // generate USB transfer layer object
	myTLUSB->Open(-1);       // get next available USB device instance
	myAnalogCard = new HL_GPAC(*myTLUSB);
	timer = new QTimer();
	connect(timer, SIGNAL(timeout()), this, SLOT(updateMeasurements()));

#ifdef CALIBRATION_MODE
	myGPIBIf = new TGPIB_Interface_USB();
	mySMU = new TGPIB_Keithley24xx(myGPIBIf, 4);
//	mySMU    = NULL; 
#endif
                          //         , name , min,  max,  def, I lim
 	PWR[0] = myAnalogCard->PWR[0]->Init("DVDD",  0, 3000, 1500, 100);
 	PWR[1] = myAnalogCard->PWR[1]->Init("AVDD",  0, 3000, 1500, 100);
 	PWR[2] = myAnalogCard->PWR[2]->Init("VDD",   0, 3000, 1500, 100);
 	PWR[3] = myAnalogCard->PWR[3]->Init("VDDIO", 0, 3000, 1500, 100);

 	 
                           //            name,  min,  max, def, 
 	ISRC[0]  = myAnalogCard->ISRC[0] ->Init("Iaa", -1200,  1200,  30);
 	ISRC[1]  = myAnalogCard->ISRC[1] ->Init("Ibb", -1200,  1200,  31);
 	ISRC[2]  = myAnalogCard->ISRC[2] ->Init("Icc", -1200,  1200,  32);
 	ISRC[3]  = myAnalogCard->ISRC[3] ->Init("Idd", -1200,  1200,  33);
 	ISRC[4]  = myAnalogCard->ISRC[4] ->Init("Iee", -1200,  1200,  34);
 	ISRC[5]  = myAnalogCard->ISRC[5] ->Init("Iff", -1200,  1200,  35);
 	ISRC[6]  = myAnalogCard->ISRC[6] ->Init("Igg", -1200,  1200, -30);
 	ISRC[7]  = myAnalogCard->ISRC[7] ->Init("Ihh", -1200,  1200, -31);
 	ISRC[8]  = myAnalogCard->ISRC[8] ->Init("Iii", -1200,  1200, -32);
 	ISRC[9]  = myAnalogCard->ISRC[9] ->Init("Ijj", -1200,  1200, -33);
 	ISRC[10] = myAnalogCard->ISRC[10]->Init("Ikk", -1200,  1200, -34);
 	ISRC[11] = myAnalogCard->ISRC[11]->Init("Ill", -1200,  1200, -35);

                           //            name,  min,  max, def, 
 	VSRC[0]  = myAnalogCard->VSRC[0] ->Init("Vaa", 0,  2500,  300);
 	VSRC[1]  = myAnalogCard->VSRC[1] ->Init("Vbb", 0,  2500,  300);
 	VSRC[2]  = myAnalogCard->VSRC[2] ->Init("Vcc", 0,  2500,  300);
 	VSRC[3]  = myAnalogCard->VSRC[3] ->Init("Vdd", 0,  2500,  300);

 	VINJ[0]  = myAnalogCard->VINJ[0] ->Init("InjLo", 0, 2500,  200);
 	VINJ[1]  = myAnalogCard->VINJ[1] ->Init("InjHi", 0, 2500, 1300);


	ui.PWR0spin-> setValue( PWR[0]->CalData.DefaultValue);
	ui.PWR1spin-> setValue( PWR[1]->CalData.DefaultValue);
	ui.PWR2spin-> setValue( PWR[2]->CalData.DefaultValue);
	ui.PWR3spin-> setValue( PWR[3]->CalData.DefaultValue);
	ui.VSRC0spin->setValue(VSRC[0]->CalData.DefaultValue);
	ui.VSRC1spin->setValue(VSRC[1]->CalData.DefaultValue);
	ui.VSRC2spin->setValue(VSRC[2]->CalData.DefaultValue);
	ui.VSRC3spin->setValue(VSRC[3]->CalData.DefaultValue);
	ui.ISRC0spin->setValue(ISRC[0]->CalData.DefaultValue);
	ui.ISRC1spin->setValue(ISRC[1]->CalData.DefaultValue);
	ui.ISRC2spin->setValue(ISRC[2]->CalData.DefaultValue);
	ui.ISRC3spin->setValue(ISRC[3]->CalData.DefaultValue);
	ui.ISRC4spin->setValue(ISRC[4]->CalData.DefaultValue);
	ui.ISRC5spin->setValue(ISRC[5]->CalData.DefaultValue);
	ui.ISRC6spin->setValue(ISRC[6]->CalData.DefaultValue);
	ui.ISRC7spin->setValue(ISRC[7]->CalData.DefaultValue);
	ui.ISRC8spin->setValue(ISRC[8]->CalData.DefaultValue);
	ui.ISRC9spin->setValue(ISRC[9]->CalData.DefaultValue);
	ui.ISRC10spin->setValue(ISRC[10]->CalData.DefaultValue);
	ui.ISRC11spin->setValue(ISRC[11]->CalData.DefaultValue);

	ui.PWRname_0-> setText(QString( PWR[0]->GetName()));
	ui.PWRname_1-> setText(QString( PWR[1]->GetName()));
	ui.PWRname_2-> setText(QString( PWR[2]->GetName()));
	ui.PWRname_3-> setText(QString( PWR[3]->GetName()));
	ui.VSRCname_0->setText(QString(VSRC[0]->GetName()));
	ui.VSRCname_1->setText(QString(VSRC[1]->GetName()));
	ui.VSRCname_2->setText(QString(VSRC[2]->GetName()));
	ui.VSRCname_3->setText(QString(VSRC[3]->GetName()));
	ui.ISRCname_0->setText(QString(ISRC[0]->GetName()));
	ui.ISRCname_1->setText(QString(ISRC[1]->GetName()));
	ui.ISRCname_2->setText(QString(ISRC[2]->GetName()));
	ui.ISRCname_3->setText(QString(ISRC[3]->GetName()));
	ui.ISRCname_4->setText(QString(ISRC[4]->GetName()));
	ui.ISRCname_5->setText(QString(ISRC[5]->GetName()));
	ui.ISRCname_6->setText(QString(ISRC[6]->GetName()));
	ui.ISRCname_7->setText(QString(ISRC[7]->GetName()));
	ui.ISRCname_8->setText(QString(ISRC[8]->GetName()));
	ui.ISRCname_9->setText(QString(ISRC[9]->GetName()));
	ui.ISRCname_10->setText(QString(ISRC[10]->GetName()));
	ui.ISRCname_11->setText(QString(ISRC[11]->GetName()));

	UpdateSystem(); // update system information
}

GPAC_Example::~GPAC_Example()
{

}

void GPAC_Example::onDeviceChange()
{
	if (OnDeviceChange()) // call to SiLibUSB
		UpdateSystem();
}

void GPAC_Example::UpdateSystem()
{
	std::stringstream ssbuf;

	if (myTLUSB->Open(-1))
	{
		myAnalogCard->Init(*myTLUSB);  
		ssbuf << myTLUSB->GetName() << " ID: " << (int)myTLUSB->GetId() << ", Analog card ID: " << (int)myAnalogCard->GetId();
		ui.CardIDspin->setValue(myAnalogCard->GetId());
		ui.statusLabel->setText(ssbuf.str().c_str());
	}
	else
	{
		ui.CardIDspin->setValue(0);
		ui.statusLabel->setText("no board found");
	}
}

void GPAC_Example::ConfFPGADialog()
{

// static version -> native OS dialog
  QString fileName = QFileDialog::getOpenFileName(this,
     tr("Select FPGA configuration file"), ".", tr("BIT Files (*.bit)"));
	myTLUSB->DownloadXilinx(fileName.toLatin1());
}

void GPAC_Example::writeGPIO()
{
	HL_addr HLaddr;
	HLaddr.LocalBusType    = BT_FPGA;
	HLaddr.LocalAddress    = 0x70;

	unsigned char data = ui.GpioEdit->text().toInt();
	myTLUSB->Write(HLaddr.raw, &data, 1);
}

void GPAC_Example::writeReg(int add, unsigned char *data)
{
	HL_addr HLaddr;
	HLaddr.LocalBusType    = BT_FPGA;
	HLaddr.LocalAddress    = add;
	
	myTLUSB->Write(HLaddr.raw, data, 1);
}

void GPAC_Example::readReg(int add, unsigned char *data)
{
	HL_addr HLaddr;
	HLaddr.LocalBusType    = BT_FPGA;
	HLaddr.LocalAddress    = add;
	
	myTLUSB->Read(HLaddr.raw, data, 1);
}

void GPAC_Example::testDIO()
{
	unsigned char data;
	unsigned char tmp;
	bool error_flag = 0;
	bool powerState = ui.PWR0CheckBox->checkState();

	if (powerState == false)
	  PWR[0]->Switch(ON);


	DBGOUT("Digital I/O test started... " );
	PWR[0]->Switch(ON);

  // LVDS loop back
	for (int i = 0; i < 4; i++)
	{
    data = 1 << i;
    writeReg(LVDS_REG_ADDR, &data);
		readReg(LVDS_REG_ADDR, &tmp);

		if (tmp >> 4 != data)
		{
			DBGOUT(endl <<" LVDS loopback error bit " << i << endl);
			error_flag = true;
		}
	}
	
	// DIO low loop back
	myAnalogCard->CalGPIO->ClearBit(CALMUX_GPIO_INHB); // enable mux output
	myAnalogCard->CalGPIO->ClearBit(CALMUX_GPIO_SEL);  // select low byte
	for (int i = 0; i < 8; i++)
	{
    data = 1 << i;
    writeReg(DOUTL_REG_ADDR, &data);
		readReg(DIN_REG_ADDR, &tmp);

		if (tmp != data)
		{
			DBGOUT(" DIO low byte loopback error bit " << i << endl);
			error_flag = true;
		}
	}	
	
	// DIO low loop back
	myAnalogCard->CalGPIO->SetBit(CALMUX_GPIO_SEL);  // select low byte
	for (int i = 0; i < 8; i++)
	{
    data = 1 << i;
    writeReg(DOUTH_REG_ADDR, &data);
		readReg(DIN_REG_ADDR, &tmp);

		if (tmp != data)
		{
			DBGOUT(" DIO high byte loopback error bit " << i << endl);
			error_flag = true;
		}
	}

	if (!error_flag)
	{
  	DBGOUT("passed. " << endl);
	}
	else
		DBGOUT("Digital I/O test failed. " << endl);

	myAnalogCard->CalGPIO->SetBit(CALMUX_GPIO_INHB); // disable mux output

  PWR[0]->Switch(powerState);  // switch back to original power state

}


void  GPAC_Example::enablePWR0(bool on_off){	PWR[0]->Switch(on_off);}
void  GPAC_Example::enablePWR1(bool on_off){	PWR[1]->Switch(on_off);}
void  GPAC_Example::enablePWR2(bool on_off){	PWR[2]->Switch(on_off);}
void  GPAC_Example::enablePWR3(bool on_off){	PWR[3]->Switch(on_off);}

void  GPAC_Example::setPWR0(double val){	PWR[0]->SetVoltage(val);}
void  GPAC_Example::setPWR1(double val){	PWR[1]->SetVoltage(val);}
void  GPAC_Example::setPWR2(double val){	PWR[2]->SetVoltage(val);}
void  GPAC_Example::setPWR3(double val){	PWR[3]->SetVoltage(val);}

void  GPAC_Example::setVSRC0(double val){	VSRC[0]->SetVoltage(val);}
void  GPAC_Example::setVSRC1(double val){	VSRC[1]->SetVoltage(val);}
void  GPAC_Example::setVSRC2(double val){	VSRC[2]->SetVoltage(val);}
void  GPAC_Example::setVSRC3(double val){	VSRC[3]->SetVoltage(val);}

void  GPAC_Example::setISRC0(double val){	ISRC[0]->SetCurrent(val);}
void  GPAC_Example::setISRC1(double val){	ISRC[1]->SetCurrent(val);}
void  GPAC_Example::setISRC2(double val){	ISRC[2]->SetCurrent(val);}
void  GPAC_Example::setISRC3(double val){	ISRC[3]->SetCurrent(val);}
void  GPAC_Example::setISRC4(double val){	ISRC[4]->SetCurrent(val);}
void  GPAC_Example::setISRC5(double val){	ISRC[5]->SetCurrent(val);}
void  GPAC_Example::setISRC6(double val){	ISRC[6]->SetCurrent(val);}
void  GPAC_Example::setISRC7(double val){	ISRC[7]->SetCurrent(val);}
void  GPAC_Example::setISRC8(double val){	ISRC[8]->SetCurrent(val);}
void  GPAC_Example::setISRC9(double val){	ISRC[9]->SetCurrent(val);}
void  GPAC_Example::setISRC10(double val){	ISRC[10]->SetCurrent(val);}
void  GPAC_Example::setISRC11(double val){	ISRC[11]->SetCurrent(val);}

void GPAC_Example::UI2HW()
{
	setPWR0(ui.PWR0spin->value());
	setPWR1(ui.PWR1spin->value());
	setPWR2(ui.PWR2spin->value());
	setPWR3(ui.PWR3spin->value());
	setVSRC0(ui.VSRC0spin->value());
	setVSRC1(ui.VSRC1spin->value());
	setVSRC2(ui.VSRC2spin->value());
	setVSRC3(ui.VSRC3spin->value());
	setISRC0(ui.ISRC0spin->value());
	setISRC1(ui.ISRC1spin->value());
	setISRC2(ui.ISRC2spin->value());
	setISRC3(ui.ISRC3spin->value());
	setISRC4(ui.ISRC4spin->value());
	setISRC5(ui.ISRC5spin->value());
	setISRC6(ui.ISRC6spin->value());
	setISRC7(ui.ISRC7spin->value());
	setISRC8(ui.ISRC8spin->value());
	setISRC9(ui.ISRC9spin->value());
	setISRC10(ui.ISRC10spin->value());
	setISRC11(ui.ISRC11spin->value());
	
	enablePWR0(ui.PWR0CheckBox->isChecked());
	enablePWR1(ui.PWR1CheckBox->isChecked());
	enablePWR2(ui.PWR2CheckBox->isChecked());
	enablePWR3(ui.PWR3CheckBox->isChecked());
}

void GPAC_Example::setCurrLim()
{
  PWR[0]->SetCurrentLimit(ui.CurrLimBox->value());
}

void GPAC_Example::enableTimer(bool yes)
{
	if (yes)
		timer->start(100);
	else
		timer->stop();
}

void GPAC_Example::updateMeasurements()
{
	PWR[0]->UpdateMeasurements();
	PWR[1]->UpdateMeasurements();
	PWR[2]->UpdateMeasurements();
	PWR[3]->UpdateMeasurements();

	ui.PWR0VLCD->display(QString::number(PWR[0]->GetVoltage(),'f',0));
	ui.PWR1VLCD->display(QString::number(PWR[1]->GetVoltage(),'f',0));
	ui.PWR2VLCD->display(QString::number(PWR[2]->GetVoltage(),'f',0));
	ui.PWR3VLCD->display(QString::number(PWR[3]->GetVoltage(),'f',0));

	ui.PWR0CLCD->display(QString::number(PWR[0]->GetCurrent(),'f',0));
	ui.PWR1CLCD->display(QString::number(PWR[1]->GetCurrent(),'f',0));
	ui.PWR2CLCD->display(QString::number(PWR[2]->GetCurrent(),'f',0));
	ui.PWR3CLCD->display(QString::number(PWR[3]->GetCurrent(),'f',0));

	VSRC[0]->UpdateMeasurements();
	VSRC[1]->UpdateMeasurements();
	VSRC[2]->UpdateMeasurements();
	VSRC[3]->UpdateMeasurements();

	ui.VSRC0VLCD->display(QString::number(VSRC[0]->GetVoltage(),'f',0));
	ui.VSRC1VLCD->display(QString::number(VSRC[1]->GetVoltage(),'f',0));
	ui.VSRC2VLCD->display(QString::number(VSRC[2]->GetVoltage(),'f',0));
	ui.VSRC3VLCD->display(QString::number(VSRC[3]->GetVoltage(),'f',0));

	ui.VSRC0CLCD->display(QString::number(VSRC[0]->GetCurrent(),'f',0));
	ui.VSRC1CLCD->display(QString::number(VSRC[1]->GetCurrent(),'f',0));
	ui.VSRC2CLCD->display(QString::number(VSRC[2]->GetCurrent(),'f',0));
	ui.VSRC3CLCD->display(QString::number(VSRC[3]->GetCurrent(),'f',0));

  for (int i = 0; i < MAX_ISRC; i ++)
		ISRC[i]->UpdateMeasurements();

	ui.ISRC0VLCD->display(QString::number(ISRC[0]->GetVoltage(),'f',0));
	ui.ISRC1VLCD->display(QString::number(ISRC[1]->GetVoltage(),'f',0));
	ui.ISRC2VLCD->display(QString::number(ISRC[2]->GetVoltage(),'f',0));
	ui.ISRC3VLCD->display(QString::number(ISRC[3]->GetVoltage(),'f',0));
	ui.ISRC4VLCD->display(QString::number(ISRC[4]->GetVoltage(),'f',0));
	ui.ISRC5VLCD->display(QString::number(ISRC[5]->GetVoltage(),'f',0));
	ui.ISRC6VLCD->display(QString::number(ISRC[6]->GetVoltage(),'f',0));
	ui.ISRC7VLCD->display(QString::number(ISRC[7]->GetVoltage(),'f',0));
	ui.ISRC8VLCD->display(QString::number(ISRC[8]->GetVoltage(),'f',0));
	ui.ISRC9VLCD->display(QString::number(ISRC[9]->GetVoltage(),'f',0));
	ui.ISRC10VLCD->display(QString::number(ISRC[10]->GetVoltage(),'f',0));
	ui.ISRC11VLCD->display(QString::number(ISRC[11]->GetVoltage(),'f',0));

	ui.ISRC0CLCD->display(QString::number(ISRC[0]->GetCurrent(),'f',0));
	ui.ISRC1CLCD->display(QString::number(ISRC[1]->GetCurrent(),'f',0));
	ui.ISRC2CLCD->display(QString::number(ISRC[2]->GetCurrent(),'f',0));
	ui.ISRC3CLCD->display(QString::number(ISRC[3]->GetCurrent(),'f',0));
	ui.ISRC4CLCD->display(QString::number(ISRC[4]->GetCurrent(),'f',0));
	ui.ISRC5CLCD->display(QString::number(ISRC[5]->GetCurrent(),'f',0));
	ui.ISRC6CLCD->display(QString::number(ISRC[6]->GetCurrent(),'f',0));
	ui.ISRC7CLCD->display(QString::number(ISRC[7]->GetCurrent(),'f',0));
	ui.ISRC8CLCD->display(QString::number(ISRC[8]->GetCurrent(),'f',0));
	ui.ISRC9CLCD->display(QString::number(ISRC[9]->GetCurrent(),'f',0));
	ui.ISRC10CLCD->display(QString::number(ISRC[10]->GetCurrent(),'f',0));
	ui.ISRC11CLCD->display(QString::number(ISRC[11]->GetCurrent(),'f',0));
}

void GPAC_Example::initGPIB()
{
	std::string devList[16];
	int numDev;

  DBGOUT("Start GPIB discovery..." << endl);
	myGPIBIf->SearchDevices(devList);

	numDev = myGPIBIf->GetNumberOfDevices();
	if (numDev == 0)
	{
	  DBGOUT("No GPIB device found" << endl);		
		return;
	}

	for (int i = 0; i < numDev; i++)
	  DBGOUT("Device " << i << ", " << devList[i].c_str() << endl);
  
	if (mySMU != NULL) 
	{
		delete mySMU;
		mySMU = NULL;
	}
	mySMU = new TGPIB_Keithley24xx(myGPIBIf, ui.SMUAddrBox->value());


}

void GPAC_Example::saveCalibrationData()
{
	myAnalogCard->SetId(ui.CardIDspin->value());
	myAnalogCard->WriteCalDataEEPROM();
}

void GPAC_Example::saveCalibrationDataToFile()
{
	myAnalogCard->SetId(ui.CardIDspin->value());
	myAnalogCard->WriteCalDataFile();
}

void GPAC_Example::loadCalibrationDataFromFile()
{
	myAnalogCard->ReadCalDataFile();
	ui.CardIDspin->setValue(myAnalogCard->GetId());
}

void GPAC_Example::eraseEEPROM()
{
	myAnalogCard->EraseCalDataEEPROM();
}

void GPAC_Example::selectCalMux()
{
	if (ui.CalMuxSpinBox->value() >= 0)
	  myAnalogCard->CH[ui.CalMuxSpinBox->value()]->Select4Calibration();  // select active channel
}




void GPAC_Example::calibrateAll()
{
	double USMU1;
	double USMU2;
	double ISMU1;
	double ISMU2;
	double IGPAC1;
	double IGPAC2;
	double UGPAC1;
	double UGPAC2;
	double VADC1;
	double VADC2;
	double CADC1;
	double CADC2;

	unsigned char data;

	// Set up SMU defaults
  mySMU->Set4WireSense(true);

  // VSRC & PWR calibration procedure
	// Set SMU to current mode
	mySMU->SwitchOff();
	mySMU->SetSourceType(CURRENTMODE);
  mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
	mySMU->SwitchOn();
	mySMU->Measure(ISMU1, USMU1);// neede to settle the SMU ???
  PWR[0]->SetCurrentLimit(2000); // current limit in mA
 
	// Select power channels 
	for (int i = 0; i < 4; i++) 
	{
  delete mySMU;
	mySMU = new TGPIB_Keithley24xx(myGPIBIf, 4);
  mySMU->Set4WireSense(true);
	mySMU->SwitchOff();

	mySMU->SetSourceType(CURRENTMODE);
  mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 3V output compliance
	mySMU->SwitchOn();
  PWR[i]->SetCurrentLimit(2000); // current limit in mA

  // PWR calibration procedure
		DBGOUT("Calibrating PWR[" << i <<"]...");
	
		// calibrate voltage setting and measurement
		PWR[i]->Select4Calibration();  // select active channel
		PWR[i]->SetValue(DAC_LOW, RAW);//CH->set low DAC value
		PWR[i]->Switch(ON);
    mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
 		PWR[i]->UpdateMeasurements(N_CAL_SAMPLES);
		VADC1 = (unsigned int)PWR[i]->GetVoltage(RAW); // get raw ADC count

		PWR[i]->SetValue(DAC_HIGH, RAW);//CH->set high DAC value
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get USMU1 
 		PWR[i]->UpdateMeasurements(N_CAL_SAMPLES);
		VADC2 = (unsigned int)myAnalogCard->PWR[i]->GetVoltage(RAW); // get raw ADC count

    PWR[i]->CalibrateDAC(DAC_LOW, USMU1*1000.0, DAC_HIGH, USMU2*1000.0);  // calibrate DAC
    PWR[i]->CalibrateVADC(USMU1*1000.0, VADC1, USMU2*1000.0, VADC2);      // calibrate voltage ADC

		// calibrate current measurement
		PWR[i]->SetValue(1500); // set medium output voltage

		mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1); // SMU->get USMU1 
 		PWR[i]->UpdateMeasurements(N_CAL_SAMPLES);
		CADC1 = (unsigned int)PWR[i]->GetCurrent(RAW); // get raw ADC count

		mySMU->SetCurrent(-SMU_CURRENT_HIGH, SMU_VOLTAGE_COMPLIANCE);  // high load current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get ISMU2, USMU2
 		PWR[i]->UpdateMeasurements(N_CAL_SAMPLES);
		CADC2 = (unsigned int)myAnalogCard->PWR[i]->GetCurrent(RAW); // get raw ADC count
		PWR[i]->CalibrateIADC(ISMU1*1000, CADC1, ISMU2*1000, CADC2); // calibrate current ADC

		PWR[i]->Switch(OFF);

		DBGOUT(" done!" << endl);

		DBGOUT("  DACGain    = " << PWR[i]->CalData.DACGain << endl);
		DBGOUT("  DACOffset  = " << PWR[i]->CalData.DACOffset << endl);
		DBGOUT("  VADCGain   = " << PWR[i]->CalData.VADCGain << endl);
		DBGOUT("  VADCOffset = " << PWR[i]->CalData.VADCOffset << endl);
		DBGOUT("  IADCGain   = " << PWR[i]->CalData.IADCGain << endl);
		DBGOUT("  IADCOffset = " << PWR[i]->CalData.IADCOffset << endl);
	} // end of power & voltage source calibration

	mySMU->SwitchOff();
	PWR[0]->SetVoltage(0, RAW);  // set to maximum value
	PWR[0]->Switch(ON);
  mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, output compliance
	mySMU->SwitchOn();
	// Select voltage mode channels
	for (int i = 0; i < 4; i++) 
	{
		DBGOUT("Calibrating VSRC[" << i <<"]...");
		// calibrate voltage setting and measurement
		VSRC[i]->Select4Calibration();  // select active channel
 		VSRC[i]->SetValue(DAC_LOW, RAW);//CH->set low DAC value
    mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance

		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
 		VSRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		VADC1 = (unsigned int)VSRC[i]->GetVoltage(RAW); // get raw ADC count

		VSRC[i]->SetValue(DAC_HIGH, RAW);//CH->set high DAC value
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get USMU1 
 		VSRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		VADC2 = (unsigned int)VSRC[i]->GetVoltage(RAW); // get raw ADC count

    VSRC[i]->CalibrateDAC(DAC_LOW, USMU1*1000, DAC_HIGH, USMU2*1000);  // calibrate DAC
    VSRC[i]->CalibrateVADC(USMU1*1000, VADC1, USMU2*1000, VADC2);      // calibrate voltage ADC

		// calibrate current measurement
		VSRC[i]->SetValue(1000); // set medium output voltage

		mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // 0 current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1); // SMU->get USMU1 
		Sleep(SETTLING_TIME);
 		VSRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
	//	CADC1 = (int)VSRC[i]->GetCurrent(RAW); // get raw ADC count
    CADC1 = 0; // test: force IADC offset to (almost) zero
		mySMU->SetCurrent(-SMU_CURRENT_LOW, SMU_VOLTAGE_COMPLIANCE);  // low load current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get ISMU2, USMU2
		Sleep(SETTLING_TIME);
 		VSRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		CADC2 = (int)VSRC[i]->GetCurrent(RAW); // get raw ADC count
		VSRC[i]->CalibrateIADC(ISMU1*1e6, CADC1, ISMU2*1e6, CADC2); // calibrate current ADC


		DBGOUT(" done!" << endl);
		DBGOUT("  DACGain    = " << VSRC[i]->CalData.DACGain << endl);
		DBGOUT("  DACOffset  = " << VSRC[i]->CalData.DACOffset << endl);
		DBGOUT("  VADCGain   = " << VSRC[i]->CalData.VADCGain << endl);
		DBGOUT("  VADCOffset = " << VSRC[i]->CalData.VADCOffset << endl);
		DBGOUT("  IADCGain   = " << VSRC[i]->CalData.IADCGain << endl);
		DBGOUT("  IADCOffset = " << VSRC[i]->CalData.IADCOffset << endl);

	} // end of power & voltage source calibration

	
	// Select injection channels (2x VINJ)
	for (int i = 0; i < 2; i++) 
	{
	  DBGOUT("Calibrating VINJ[" << i <<"]...");

		VINJ[i]->Select4Calibration();  // select active channel
		data = i;
    writeReg(INJECT_REG, &data);
 		VINJ[i]->SetValue(DAC_LOW, RAW);//CH->set low DAC value
    mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance

		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 

		VINJ[i]->SetValue(DAC_HIGH, RAW);//CH->set high DAC value
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get USMU1 

    VINJ[i]->CalibrateDAC(DAC_LOW, USMU1*1000, DAC_HIGH, USMU2*1000);  // calibrate DAC
 
    DBGOUT(" done!" << endl);
		DBGOUT("  DACGain    = " << VINJ[i]->CalData.DACGain << endl);
		DBGOUT("  DACOffset  = " << VINJ[i]->CalData.DACOffset << endl);
	} // end of injection source calibration

 	mySMU->SwitchOff();
	PWR[0]->Switch(OFF);
	mySMU->SetSourceType(VOLTAGEMODE);
  mySMU->SetVoltage(0, SMU_CURRENT_COMPLIANCE);  // zero voltage,  current limit
	mySMU->SwitchOn();
	PWR[0]->Switch(ON);


	for (int i = 0; i < MAX_ISRC; i++)
	{
		DBGOUT("Calibrating ISRC[" << i <<"]...");

		ISRC[i]->Select4Calibration();
		ISRC[i]->SetCurrent(DAC_LOW, RAW); // set negative output current
    mySMU->SetVoltage(SMU_VOLTAGE_MID, SMU_CURRENT_COMPLIANCE);  // medium voltage,  current limit
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1, ISMU1
		ISRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		CADC1 = (int)ISRC[i]->GetCurrent(RAW); // get raw ADC count

		ISRC[i]->SetCurrent(DAC_HIGH, RAW); // set positive output current
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get USMU2, ISMU2
		ISRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		CADC2 = (int)ISRC[i]->GetCurrent(RAW); // get raw ADC count

    ISRC[i]->CalibrateDAC(DAC_LOW, ISMU1*1e6, DAC_HIGH, ISMU2*1e6);  // calibrate DAC
		ISRC[i]->CalibrateIADC(ISMU1*1e6, CADC1, ISMU2*1e6, CADC2);      // calibrate current ADC

		ISRC[i]->SetCurrent(DAC_MID, RAW); // set almost zero output current
    mySMU->SetVoltage(SMU_VOLTAGE_LOW, SMU_CURRENT_COMPLIANCE);  // low voltage,  current limit
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1, ISMU1
		ISRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		VADC1 = (unsigned int)ISRC[i]->GetVoltage(RAW); // get raw ADC count

    mySMU->SetVoltage(SMU_VOLTAGE_HIGH, SMU_CURRENT_COMPLIANCE);  // low voltage,  current limit
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU2, USMU2);// SMU->get USMU2, ISMU2
		ISRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		VADC2 = (unsigned int)ISRC[i]->GetVoltage(RAW); // get raw ADC count

		ISRC[i]->CalibrateVADC(USMU1*1e3, VADC1, USMU2*1e3, VADC2);      // calibrate current ADC

		DBGOUT(" done!" << endl);
		DBGOUT("  DACGain    = " << ISRC[i]->CalData.DACGain << endl);
		DBGOUT("  DACOffset  = " << ISRC[i]->CalData.DACOffset << endl);
		DBGOUT("  VADCGain   = " << ISRC[i]->CalData.VADCGain << endl);
		DBGOUT("  VADCOffset = " << ISRC[i]->CalData.VADCOffset << endl);
		DBGOUT("  IADCGain   = " << ISRC[i]->CalData.IADCGain << endl);
		DBGOUT("  IADCOffset = " << ISRC[i]->CalData.IADCOffset << endl);

	} // current source calibration

  // Performance check  
	

//TODO
// Injection strobe control
// Current limit

//
	mySMU->Send(":SYST:BEEP:STAT ON");
	// Cm chord ;-)
	mySMU->Send(":SYST:BEEP:IMM 523,0.2");  // C
	Sleep (200);
	mySMU->Send(":SYST:BEEP:IMM 622,0.2");  // Dis
	Sleep (200);
	mySMU->Send(":SYST:BEEP:IMM 784,0.2");  // G
//	mySMU->Send(":SYST:BEEP:STAT OFF");

  UI2HW(); // restore settings
}


void GPAC_Example::testAnalog()
{
	double USMU1;
	double USMU2;
	double ISMU1;
	double ISMU2;
	double IGPAC1;
	double IGPAC2;
	double UGPAC1;
	double UGPAC2;
	double VADC1;
	double VADC2;
	double CADC1;
	double CADC2;

	double VSETerror;
	double ISETerror;
	double VSNSerror;
	double ISNSerror;
	// Set up SMU defaults


	mySMU->SwitchOff();
  mySMU->Set4WireSense(true);
	mySMU->SetSourceType(CURRENTMODE);
  mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
	mySMU->SwitchOn();
	mySMU->Measure(ISMU1, USMU1);// neede to settle the SMU ???

  PWR[0]->SetCurrentLimit(200); // current limit in mA


	for (int i = 0; i < MAX_PWR; i++)
	{
		PWR[i]->Select4Calibration();
		PWR[i]->SetVoltage(GPAC_VOLTAGE);
		PWR[i]->Switch(ON);
    mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		PWR[i]->UpdateMeasurements(N_CAL_SAMPLES);
		UGPAC1 = PWR[i]->GetVoltage();
		IGPAC1 = PWR[i]->GetCurrent();
		VSETerror = GPAC_VOLTAGE - USMU1 * 1000;  // mV
		VSNSerror = USMU1 * 1000 - UGPAC1;  // mV
		ISNSerror = ISMU1 * 1000 - IGPAC1;  // mA
		DBGOUT("Testing PWR[" << i << "]: @" << int(GPAC_VOLTAGE) << "mV, 0mA: " << fixed );
		if (!((VSETerror > 2)||(VSNSerror > 2)||(ISNSerror > 2)))
		{DBGOUT("Ok"<< endl);}
		else
		{DBGOUT(endl);}
		if (VSETerror > 2)
		 DBGOUT("  Voltage output error = " << fixed << setprecision(2)<< VSETerror << "mV" << endl);
		if (VSNSerror > 2)
		DBGOUT("  Voltage sense error = "  << fixed << setprecision(2)<< VSNSerror << "mV" << endl);
		if (ISNSerror > 2)
		DBGOUT("  Current sense error = "  << fixed << setprecision(2)<< ISNSerror << "mA" << endl);

    mySMU->SetCurrent(-SMU_CURRENT_HIGH, SMU_VOLTAGE_COMPLIANCE);  // high current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		PWR[i]->UpdateMeasurements(N_CAL_SAMPLES);
		UGPAC1 = PWR[i]->GetVoltage();
		IGPAC1 = PWR[i]->GetCurrent();
		VSETerror = GPAC_VOLTAGE - USMU1 * 1000;  // mV
		VSNSerror = USMU1 * 1000 - UGPAC1;  // mV
		ISNSerror = ISMU1 * 1000 - IGPAC1;  // mA
		DBGOUT("Testing PWR[" << i << "]: @" << int(GPAC_VOLTAGE) << "mV, " << fixed << setprecision(2)<< SMU_CURRENT_HIGH * 1000 << " mA:");
		if (!((VSETerror > 2)||(VSNSerror > 2)||(ISNSerror > 2)))
		{DBGOUT("Ok"<< endl);}
		else
		{DBGOUT(endl);}
		if (VSETerror > 2)
		DBGOUT("  Voltage output error = " << fixed << setprecision(2)<< VSETerror << "mV" << endl);
		if (VSNSerror > 2)
		DBGOUT("  Voltage sense error = "  << fixed << setprecision(2)<< VSNSerror << "mV" << endl);
		if (ISNSerror > 2)
		DBGOUT("  Current sense error = "  << fixed << setprecision(2)<< ISNSerror << "mA" << endl);

		PWR[i]->Switch(OFF);
	}

	PWR[0]->SetVoltage(2500); // for clamp diode
	PWR[0]->Switch(ON);

	for (int i = 0; i < MAX_VSRC; i++)
	{
		VSRC[i]->Select4Calibration();
		VSRC[i]->SetVoltage(SMU_VOLTAGE_MID*1e3);
    mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		VSRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		UGPAC1 = VSRC[i]->GetVoltage();
		IGPAC1 = VSRC[i]->GetCurrent();
		VSETerror = (SMU_VOLTAGE_MID - USMU1) * 1000;  // mV
		VSNSerror = USMU1 * 1e3 - UGPAC1;  // mV
		ISNSerror = ISMU1 * 1e6 - IGPAC1;  // uA
		DBGOUT("Testing VSRC[" << i << "]: @" << int(SMU_VOLTAGE_MID*1e3) << "mV, 0mA: ");
		if (!((VSETerror > 2)||(VSNSerror > 2)||(ISNSerror > 2)))
		{DBGOUT("Ok"<< endl);}
		else
		{DBGOUT(endl);}
		if (VSETerror > 2)
		DBGOUT("  Voltage output error = " << fixed << setprecision(2)<< VSETerror << "mV" << endl);
		if (VSNSerror > 2)
		DBGOUT("  Voltage sense error = "  << fixed << setprecision(2)<< VSNSerror << "mV" << endl);
		if (ISNSerror > 2)
		DBGOUT("  Current sense error = "  << fixed << setprecision(2)<< ISNSerror << "uA" << endl);

    mySMU->SetCurrent(-SMU_CURRENT_LOW, SMU_VOLTAGE_COMPLIANCE);  // low current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		VSRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		UGPAC1 = VSRC[i]->GetVoltage();
		IGPAC1 = VSRC[i]->GetCurrent();
		VSETerror = (SMU_VOLTAGE_MID - USMU1) * 1000;  // mV
		VSNSerror = USMU1 * 1e3 - UGPAC1;  // mV
		ISNSerror = ISMU1 * 1e6 - IGPAC1;  // uA
		DBGOUT("Testing VSRC[" << i << "]: @" << int(SMU_VOLTAGE_MID*1e3) << "mV, " << SMU_CURRENT_LOW * 1000 << " mA: " );
		if (!((VSETerror > 2)||(VSNSerror > 2)||(ISNSerror > 2)))
		{DBGOUT("Ok"<< endl);}
		else
		{DBGOUT(endl);}
		if (VSETerror > 2)
		DBGOUT("  Voltage output error = " << fixed << setprecision(2)<< VSETerror << "mV"<< endl);
		if (VSNSerror > 2)
		DBGOUT("  Voltage sense error = "  << fixed << setprecision(2)<< VSNSerror << "mV"<< endl);
		if (ISNSerror > 2)
		DBGOUT("  Current sense error = "  << fixed << setprecision(2)<< ISNSerror << "uA"<< endl);

	}

	for (int i = 0; i < MAX_VINJ; i++)
	{
		VINJ[i]->Select4Calibration();
		VINJ[i]->SetVoltage(SMU_VOLTAGE_MID*1e3);
    mySMU->SetCurrent(0, SMU_VOLTAGE_COMPLIANCE);  // zero current, 2V output compliance
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		VSETerror = (SMU_VOLTAGE_MID - USMU1) * 1000;  // mV
		DBGOUT("Testing VINJ[" << i << "]: @" << int(SMU_VOLTAGE_MID) << "V: ");
		if (!(VSETerror > 2))
		{DBGOUT("Ok" << endl);}	
		else 
	  {DBGOUT(endl << "  Voltage output error = " << VSETerror << "mV" << endl);}
	}

	mySMU->SwitchOff();
	mySMU->SetSourceType(VOLTAGEMODE); // prepare for ISRC test
  mySMU->SetVoltage(1, SMU_CURRENT_COMPLIANCE);  
	mySMU->SwitchOn();

	for (int i = 0; i < MAX_ISRC; i++)
	{
		ISRC[i]->Select4Calibration();
		ISRC[i]->SetCurrent(GPAC_CURRENT);
 		mySMU->SetVoltage(1, SMU_CURRENT_COMPLIANCE);  // 
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		ISRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		UGPAC1 = ISRC[i]->GetVoltage();
		IGPAC1 = ISRC[i]->GetCurrent();
		ISETerror = (GPAC_CURRENT - ISMU1*1e6);  // µA
		VSNSerror = USMU1 * 1e3 - UGPAC1;     // mV
		ISNSerror = ISMU1 * 1e6 - IGPAC1;  // µA
		DBGOUT("Testing ISRC[" << i << "]: @" << int(GPAC_CURRENT) << "µA, " << "1V: ");
		if (!((ISETerror > 2)||(VSNSerror > 2)||(ISNSerror > 2)))
		{DBGOUT("Ok"<< endl);}
		else
		DBGOUT(endl);		
		if (ISETerror > 2)
		DBGOUT("  Current output error = " << fixed << setprecision(2)<< ISETerror << "µA" << endl);
		if (VSNSerror > 2)
		DBGOUT("  Voltage sense error = "  << fixed << setprecision(2)<< VSNSerror << "mV" << endl);
		if (ISNSerror > 2)
		DBGOUT("  Current sense error = "  << fixed << setprecision(2)<< ISNSerror << "µA" << endl);

	
	//	ISRC[i]->SetCurrent(-GPAC_CURRENT);
 		mySMU->SetVoltage(0.5, SMU_CURRENT_COMPLIANCE);  // 
		Sleep(SETTLING_TIME);
		mySMU->Measure(ISMU1, USMU1);// SMU->get USMU1 
		ISRC[i]->UpdateMeasurements(N_CAL_SAMPLES);
		UGPAC1 = ISRC[i]->GetVoltage();
		IGPAC1 = ISRC[i]->GetCurrent();
		ISETerror = (GPAC_CURRENT - ISMU1*1e6);  // µA
		VSNSerror = USMU1 * 1e3 - UGPAC1;     // mV
		ISNSerror = ISMU1 * 1e6 - IGPAC1;  // µA
		DBGOUT("Testing ISRC[" << i << "]: @" << int(GPAC_CURRENT) << "µA, " << "0.5V: ");
		if (!((ISETerror > 2)||(VSNSerror > 2)||(ISNSerror > 2)))
		{DBGOUT("Ok"<< endl);}
		else
		DBGOUT(endl);		
		if (ISETerror > 2)
		DBGOUT("  Current output error = " << fixed << setprecision(2)<< ISETerror << "µA" << endl);
		if (VSNSerror > 2)
		DBGOUT("  Voltage sense error = "  << fixed << setprecision(2)<< VSNSerror << "mV" << endl);
		if (ISNSerror > 2)
		DBGOUT("  Current sense error = "  << fixed << setprecision(2)<< ISNSerror << "µA" << endl);

	}
	mySMU->SwitchOff();

  UI2HW(); // restore settings

}