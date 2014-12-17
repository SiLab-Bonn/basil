#include "stdafx.h"
#include "MainForm.h"


MainForm::MainForm(void):QWidget()
{
  setupUi(this);
	timer = new QTimer(this);
  connect(PWR0CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR0(bool)));
  connect(PWR1CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR1(bool)));
  connect(PWR2CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR2(bool)));
  connect(PWR3CheckBox, SIGNAL(clicked(bool)), this, SLOT(enablePWR3(bool)));
  connect(PWR0spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR0(double)));
  connect(PWR1spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR1(double)));
  connect(PWR2spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR2(double)));
  connect(PWR3spin, SIGNAL(valueChanged(double)), this, SLOT(setPWR3(double)));
  connect(VSRC0spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC0(double)));
  connect(VSRC1spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC1(double)));
  connect(VSRC2spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC2(double)));
  connect(VSRC3spin, SIGNAL(valueChanged(double)), this, SLOT(setVSRC3(double)));
  connect(ISRC0spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC0(double)));
  connect(ISRC1spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC1(double)));
  connect(ISRC2spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC2(double)));
  connect(ISRC3spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC3(double)));
  //connect(ISRC4spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC4(double)));
  //connect(ISRC5spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC5(double)));
  //connect(ISRC6spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC6(double)));
  //connect(ISRC7spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC7(double)));
  //connect(ISRC8spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC8(double)));
  //connect(ISRC9spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC9(double)));
  //connect(ISRC10spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC10(double)));
  //connect(ISRC11spin, SIGNAL(valueChanged(double)), this, SLOT(setISRC11(double)));

  connect(CurrLimBox, SIGNAL(valueChanged(double)), this, SLOT(setCurrLim()));
  	
  InitUSB();
	myUSB    = new TL_USB();
	myUSB->Open(-1);
	myGPIBIf = new TGPIB_Interface_USB();
  mySMU    = new TGPIB_Keithley24xx(myGPIBIf, 11);
//	mySMU->Set4WireSense(true);
	
	myAnalogCard = new HL_GPAC(*myUSB);

	PWR0spin-> setValue(myAnalogCard-> PWR[0]->CalData.DefaultValue);
	PWR1spin-> setValue(myAnalogCard-> PWR[1]->CalData.DefaultValue);
	PWR2spin-> setValue(myAnalogCard-> PWR[2]->CalData.DefaultValue);
	PWR3spin-> setValue(myAnalogCard-> PWR[3]->CalData.DefaultValue);
	VSRC0spin->setValue(myAnalogCard->VSRC[0]->CalData.DefaultValue);
	VSRC1spin->setValue(myAnalogCard->VSRC[1]->CalData.DefaultValue);
	VSRC2spin->setValue(myAnalogCard->VSRC[2]->CalData.DefaultValue);
	VSRC3spin->setValue(myAnalogCard->VSRC[3]->CalData.DefaultValue);
	ISRC0spin->setValue(myAnalogCard->ISRC[0]->CalData.DefaultValue);
	ISRC1spin->setValue(myAnalogCard->ISRC[1]->CalData.DefaultValue);
	ISRC2spin->setValue(myAnalogCard->ISRC[2]->CalData.DefaultValue);
	ISRC3spin->setValue(myAnalogCard->ISRC[3]->CalData.DefaultValue);

	PWRname_0-> setText(QString(myAnalogCard-> PWR[0]->Name.c_str()));
	PWRname_1-> setText(QString(myAnalogCard-> PWR[1]->Name.c_str()));
	PWRname_2-> setText(QString(myAnalogCard-> PWR[2]->Name.c_str()));
	PWRname_3-> setText(QString(myAnalogCard-> PWR[3]->Name.c_str()));
	VSRCname_0->setText(QString(myAnalogCard->VSRC[0]->Name.c_str()));
	VSRCname_1->setText(QString(myAnalogCard->VSRC[1]->Name.c_str()));
	VSRCname_2->setText(QString(myAnalogCard->VSRC[2]->Name.c_str()));
	VSRCname_3->setText(QString(myAnalogCard->VSRC[3]->Name.c_str()));
	ISRCname_0->setText(QString(myAnalogCard->ISRC[0]->Name.c_str()));
	ISRCname_1->setText(QString(myAnalogCard->ISRC[1]->Name.c_str()));
	ISRCname_2->setText(QString(myAnalogCard->ISRC[2]->Name.c_str()));
	ISRCname_3->setText(QString(myAnalogCard->ISRC[3]->Name.c_str()));

	UpdateSystem(); // check for USB devices
}

MainForm::~MainForm(void)
{
 // delete myAnalogCard;
	//delete myUSB;
	//delete mySMU;	
	//delete myGPIBIf;
}

void MainForm::UpdateSystem()
{
	std::stringstream ssbuf;
	hUSB = GetUSBDevice(-1);

	if (hUSB != NULL)
	{
//		myAnalogCard->SetUSBHandle(myUSBdev);
		ssbuf << myUSB->GetName() << " ID: " << (int)myUSB->GetId() << ", Adapter card ID: " << (int)myAnalogCard->GetId();
		statusLabel->setText(ssbuf.str().c_str());
		IdNumBox->setValue(myAnalogCard->GetId());
		Power(false);
	  SelectChannel(-1);
	}
	else
	{
	//	myUSBdev->SetDeviceHandle(NULL);
	//	myAnalogCard->SetUSBHandle(NULL);
		statusLabel->setText("no board found");
	}
}

void MainForm::onDeviceChange()
{
	if (OnDeviceChange()) // call to USBBoardLib.dll
		UpdateSystem();
}

void MainForm::openFileDialog()
{
	/*
	FPGAFileName = QFileDialog::getOpenFileName(this,
		   tr("Select FPGA Configuration File"), "d:/icwiki_svn/USBpixI4/host/trunk/config", tr("Bit Files (*.bit)"));

	if (!FPGAFileName.isEmpty())
       fileLineEdit->setText(FPGAFileName);
 */ 
}

void MainForm::refreshGPIBList()
{
	std::string devList[16];
	myGPIBIf->SearchDevices(devList);
	
	textBrowser->clear();

	for (int i = 0; i < myGPIBIf->GetNumberOfDevices(); i++)
	  textBrowser->append(QString(devList[i].c_str()));
}

void MainForm::sendReceiveGPIB()
{
	std::stringstream ss;
	
	ss << "ID: " << deviceIdEdit->text().toStdString() << " send: "<< commandEdit->text().toStdString();

	ss << " received: " << myGPIBIf->SendAndReceive(deviceIdEdit->text().toInt(), commandEdit->text().toStdString());

	textBrowser->append(QString(ss.str().c_str()));
}

void MainForm::sendGPIB()
{
	std::stringstream ss;
	
	ss << "ID: " << deviceIdEdit->text().toStdString() << " send: "<< commandEdit->text().toStdString();

  myGPIBIf->Send(deviceIdEdit->text().toInt(), commandEdit->text().toStdString());

	textBrowser->append(QString(ss.str().c_str()));
}

void MainForm::clearGPIB()
{
	myGPIBIf->ClearDevice(deviceIdEdit->text().toInt());
}


void  MainForm::enablePWR0(bool on_off){	myAnalogCard->PWR[0]->Switch(on_off);}
void  MainForm::enablePWR1(bool on_off){	myAnalogCard->PWR[1]->Switch(on_off);}
void  MainForm::enablePWR2(bool on_off){	myAnalogCard->PWR[2]->Switch(on_off);}
void  MainForm::enablePWR3(bool on_off){	myAnalogCard->PWR[3]->Switch(on_off);}

void  MainForm::setPWR0(double val){	myAnalogCard->PWR[0]->SetVoltage(val);}
void  MainForm::setPWR1(double val){	myAnalogCard->PWR[1]->SetVoltage(val);}
void  MainForm::setPWR2(double val){	myAnalogCard->PWR[2]->SetVoltage(val);}
void  MainForm::setPWR3(double val){	myAnalogCard->PWR[3]->SetVoltage(val);}

void  MainForm::setVSRC0(double val){	myAnalogCard->VSRC[0]->SetVoltage(val);}
void  MainForm::setVSRC1(double val){	myAnalogCard->VSRC[1]->SetVoltage(val);}
void  MainForm::setVSRC2(double val){	myAnalogCard->VSRC[2]->SetVoltage(val);}
void  MainForm::setVSRC3(double val){	myAnalogCard->VSRC[3]->SetVoltage(val);}

void  MainForm::setISRC0(double val){	myAnalogCard->ISRC[0]->SetCurrent(val);}
void  MainForm::setISRC1(double val){	myAnalogCard->ISRC[1]->SetCurrent(val);}
void  MainForm::setISRC2(double val){	myAnalogCard->ISRC[2]->SetCurrent(val);}
void  MainForm::setISRC3(double val){	myAnalogCard->ISRC[3]->SetCurrent(val);}
//void  MainForm::setISRC4(double val){	myAnalogCard->ISRC[4]->SetCurrent(val);}
//void  MainForm::setISRC5(double val){	myAnalogCard->ISRC[5]->SetCurrent(val);}
//void  MainForm::setISRC6(double val){	myAnalogCard->ISRC[6]->SetCurrent(val);}
//void  MainForm::setISRC7(double val){	myAnalogCard->ISRC[7]->SetCurrent(val);}
//void  MainForm::setISRC8(double val){	myAnalogCard->ISRC[8]->SetCurrent(val);}
//void  MainForm::setISRC9(double val){	myAnalogCard->ISRC[9]->SetCurrent(val);}
//void  MainForm::setISRC10(double val){	myAnalogCard->ISRC[10]->SetCurrent(val);}
//void  MainForm::setISRC11(double val){	myAnalogCard->ISRC[11]->SetCurrent(val);}



void MainForm::updateMeasurements()
{

	myAnalogCard->UpdateMeasurements();  
	//myAnalogCard->PWR[0]->UpdateMeasuremnts();
	PWR0VLCD->display(QString::number(myAnalogCard->PWR[0]->GetVoltage(),'f',0));
	PWR1VLCD->display(QString::number(myAnalogCard->PWR[1]->GetVoltage(),'f',0));
	PWR2VLCD->display(QString::number(myAnalogCard->PWR[2]->GetVoltage(),'f',0));
	PWR3VLCD->display(QString::number(myAnalogCard->PWR[3]->GetVoltage(),'f',0));
	
	PWR0CLCD->display(QString::number(myAnalogCard->PWR[0]->GetCurrent(),'f',0));
	PWR1CLCD->display(QString::number(myAnalogCard->PWR[1]->GetCurrent(),'f',0));
	PWR2CLCD->display(QString::number(myAnalogCard->PWR[2]->GetCurrent(),'f',0));
	PWR3CLCD->display(QString::number(myAnalogCard->PWR[3]->GetCurrent(),'f',0));

	VSRC0VLCD->display(QString::number(myAnalogCard->VSRC[0]->GetVoltage(),'f',0));
	VSRC1VLCD->display(QString::number(myAnalogCard->VSRC[1]->GetVoltage(),'f',0));
	VSRC2VLCD->display(QString::number(myAnalogCard->VSRC[2]->GetVoltage(),'f',0));
	VSRC3VLCD->display(QString::number(myAnalogCard->VSRC[3]->GetVoltage(),'f',0));

	VSRC0CLCD->display(QString::number(myAnalogCard->VSRC[0]->GetCurrent(),'f',0));
	VSRC1CLCD->display(QString::number(myAnalogCard->VSRC[1]->GetCurrent(),'f',0));
	VSRC2CLCD->display(QString::number(myAnalogCard->VSRC[2]->GetCurrent(),'f',0));
	VSRC3CLCD->display(QString::number(myAnalogCard->VSRC[3]->GetCurrent(),'f',0));

	ISRC0VLCD->display(QString::number(myAnalogCard->ISRC[0]->GetVoltage(),'f',0));
	ISRC1VLCD->display(QString::number(myAnalogCard->ISRC[1]->GetVoltage(),'f',0));
	ISRC2VLCD->display(QString::number(myAnalogCard->ISRC[2]->GetVoltage(),'f',0));
	ISRC3VLCD->display(QString::number(myAnalogCard->ISRC[3]->GetVoltage(),'f',0));

	ISRC0CLCD->display(QString::number(myAnalogCard->ISRC[0]->GetCurrent(),'f',0));
	ISRC1CLCD->display(QString::number(myAnalogCard->ISRC[1]->GetCurrent(),'f',0));
	ISRC2CLCD->display(QString::number(myAnalogCard->ISRC[2]->GetCurrent(),'f',0));
	ISRC3CLCD->display(QString::number(myAnalogCard->ISRC[3]->GetCurrent(),'f',0));



//	mySMU->SwitchOn();
//	mySMU->Measure(currentVal, voltageVal);
	
//  VmeasLCD->display(QString::number(voltageVal,'f',3));
//	CmeasLCD->display(QString::number(currentVal,'f',3));

}

void MainForm::enableTimer(bool yes)
{
	if (yes)
		timer->start(100);
	else
		timer->stop();
}

void MainForm::calibrate()
{
	//memo1->clear();
	//switch(chSelBox->currentIndex())
	//{
	// // case 0: CalibrateAll(); break;
	//	case 0: CalibrateChannel(CH1); break;
	//	case 1: CalibrateChannel(CH2); break;
	//	case 2: CalibrateChannel(CH3); break;
	//	case 3: CalibrateChannel(CH4); break;
	//}
}

void MainForm::setSMUon()
{
	mySMU->SwitchOn();
	getSMUMeas();
}

void MainForm::setSMUoff()
{
	mySMU->SwitchOff();
  voltageLCD->display(QString::number(0,'f',4));
	currentLCD->display(QString::number(0,'f',4));
}

void MainForm::setSMUval()
{
	if (mySMU->DeviceStatus == VOLTAGEMODE)
		mySMU->SetVoltage(voltageVal->value(), 1);	
	
	if (mySMU->DeviceStatus == CURRENTMODE)
		mySMU->SetCurrent(currentVal->value(), 2.5);

	getSMUMeas();
}

void MainForm::setSMUCout()
{
	offBtn->setChecked(true);
	mySMU->SetSourceType(CURRENTMODE);
}

void MainForm::setSMUVout()
{
	offBtn->setChecked(true);
	mySMU->SetSourceType(VOLTAGEMODE);
}

void MainForm::getSMUMeas()
{
	double currentVal, voltageVal;
	
	mySMU->Measure(currentVal, voltageVal);
	
  voltageLCD->display(QString::number(voltageVal,'f',4));
	currentLCD->display(QString::number(currentVal,'f',4));
}

void MainForm::Power(bool on_off, int channel)
{
	if (channel == -1) // all channels
	  for (int i = 0; i < MAX_CH; i++)
      myAnalogCard->PWR[i]->Switch(on_off);
	else
      myAnalogCard->PWR[channel]->Switch(on_off);
}

void MainForm::SelectChannel(unsigned char ch)  // mux setting for AdapterCard Calibration Add-on Board
{
	unsigned char data;

 // switch (ch)
	//{
	//  case CH1: data = ~0x04; break;
	//  case CH2: data = ~0x06; break;
	//  case CH3: data = ~0x00; break;
	//  case CH4: data = ~0x02; break;
	//	default:  data =  0x00; break;
	//}

//	myUSBdev->WriteFPGA(CS_HARD_RST_CONTROL, *data);
}

void MainForm::CalibrateChannel(int ch)
{
//	double ADC_V1, ADC_V2, ADC_C1, ADC_C2, SMU_V1, SMU_V2, dummy;
//	int DAC_low = -100;
//	int DAC_high = 100;
//	double current_low  = 0.1;
//	double current_high = 0.9;
//	std::stringstream ss;
//
//	ss.str("");
//  
//  switch (ch)
//	{
//	  case CH1: 	ss << "Ch. " << (int) ch << " (CH1)" << std::endl; break;
//	  case CH2: 	ss << "Ch. " << (int) ch << " (CH2)" << std::endl; break;
//	  case CH3: 	ss << "Ch. " << (int) ch << " (CH3)" << std::endl; break;
//	  case CH4: 	ss << "Ch. " << (int) ch << " (CH4)" << std::endl; break;
//		default:      ss << "unknown channel: " << (int) ch << " exiting..." << std::endl; break;
//	}
//
//
//	//---- ADC calibration (voltage sense) ---
//  //
//	// Vmeas = VmeasGain * ADC + VmeasOffset
//
//	mySMU->SwitchOff();     // switch off SMU
//	mySMU->SetSourceType(CURRENTMODE); // set to current mode 
////	mySMU->SetCurrent(0, 2.5);  
//	mySMU->SetCurrent(-current_low, 2.5);  
//	mySMU->SwitchOn();
//
//	Power(false);
//	Power(true, ch);
//	SelectChannel(ch);
//
//	myAdapterCard->PSU[ch]->SetVoltage(DAC_high, true);
//	Sleep(100);
//	mySMU->Measure(dummy, SMU_V1);
//	myAdapterCard->UpdateMeasurements();
//	ADC_V1 = myAdapterCard->PSU[ch]->GetVoltage(true);
//	ADC_C1 = myAdapterCard->PSU[ch]->GetCurrent(RAW);
//
//
//	myAdapterCard->PSU[ch]->SetVoltage(DAC_low, true);
//	Sleep(100);
//	mySMU->Measure(dummy, SMU_V2);
//	myAdapterCard->UpdateMeasurements();
//	ADC_V2 = myAdapterCard->PSU[ch]->GetVoltage(true);
//	ADC_C2 = myAdapterCard->PSU[ch]->GetCurrent(RAW);
//
//	myAdapterCard->CalculateGainAndOffset(SMU_V1, ADC_V1, SMU_V2, ADC_V2, myAdapterCard->PSU[ch]->CalData.VmeasGain, myAdapterCard->PSU[ch]->CalData.VmeasOffset);
//
//	ss << "  ADC calibration" << std::endl;
//	ss << "    1. {#ADC, Vout} = {" << ADC_V1 << ", " << SMU_V1 << "}" << std::endl;
//	ss << "    2. {#ADC, Vout} = {" << ADC_V2 << ", " << SMU_V2 << "}" << std::endl;
//	ss << "    VmeasGain   = " << myAdapterCard->PSU[ch]->CalData.VmeasGain << std::endl;
//	ss << "    VmeasOffset = " << myAdapterCard->PSU[ch]->CalData.VmeasOffset << std::endl;
//
//	memo1->append(QString(ss.str().c_str()));
//	ss.str("");
//
//
//  //--- DAC calibration (voltage setting) ---
//
//	myAdapterCard->CalculateGainAndOffset(DAC_high, SMU_V1, DAC_low, SMU_V2, myAdapterCard->PSU[ch]->CalData.VsetGain, myAdapterCard->PSU[ch]->CalData.VsetOffset);
//
//	ss << "  DAC calibration" << std::endl;
//	ss << "    1. {#DAC, Vout} = {" << DAC_high << ", " << SMU_V1 << "}" << std::endl;
//	ss << "    2. {#DAC, Vout} = {" << DAC_low << ", " << SMU_V2 << "}" << std::endl;
//	ss << "    VsetGain   = " << myAdapterCard->PSU[ch]->CalData.VsetGain << std::endl;
//	ss << "    VsetOffset = " << myAdapterCard->PSU[ch]->CalData.VsetOffset << std::endl;
//
//	memo1->append(QString(ss.str().c_str()));
//  ss.str("");
//
//
//	// voltage dependent quiesent current
//  //
//	// Iq = IqGain * Vmeas + IqOffset
//
//	myAdapterCard->CalculateGainAndOffset(SMU_V1, ADC_C1, SMU_V2, ADC_C2, myAdapterCard->PSU[ch]->CalData.IqVgain, myAdapterCard->PSU[ch]->CalData.IqOffset);
//
//	ss << "  Iq calibration" << std::endl;
//	ss << "    1. {#ADC_I, Vout} = {" << ADC_C1 << ", " << SMU_V1 << "}" << std::endl;
//	ss << "    2. {#ADC_I, Vout} = {" << ADC_C2 << ", " << SMU_V2 << "}" << std::endl;
//	ss << "    IqGain   = " << myAdapterCard->PSU[ch]->CalData.IqVgain << std::endl;
//	ss << "    IqOffset = " << myAdapterCard->PSU[ch]->CalData.IqOffset << std::endl;
//
//	memo1->append(QString(ss.str().c_str()));
//  ss.str("");
//
//
//
//	// current sense calibration
//  //
//	// Imeas = ImeasGain * ADC + ImeasOffset
//
//
//	myAdapterCard->PSU[ch]->SetVoltage(DAC_low, true);
//	mySMU->SetCurrent(-current_low, 2.5);
//	Sleep(100);
//	myAdapterCard->UpdateMeasurements();
////	ADC_V1 = myAdapterCard->PSU[ch]->GetVoltage(true);
//	ADC_C1 = myAdapterCard->PSU[ch]->GetCurrent(RAW_IQ_COMPENSATED);
//
//	mySMU->SetCurrent(-current_high, 2.5);
//	Sleep(100);
//	myAdapterCard->UpdateMeasurements();
////	ADC_V1 = myAdapterCard->PSU[ch]->GetVoltage(true);
//	ADC_C2 = myAdapterCard->PSU[ch]->GetCurrent(RAW_IQ_COMPENSATED);
//
//	mySMU->SetCurrent(0, 2.5);
//  mySMU->SwitchOff();     // switch off SMU
//
//
//	myAdapterCard->CalculateGainAndOffset(current_low, ADC_C1, current_high, ADC_C2, myAdapterCard->PSU[ch]->CalData.ImeasGain, myAdapterCard->PSU[ch]->CalData.ImeasOffset);
//
//	ss << "  Imeas calibration" << std::endl;
//	ss << "    1. {#ADC_I, Iset} = {" << ADC_C1 << ", " << current_low << "}" << std::endl;
//	ss << "    2. {#ADC_I, Iset} = {" << ADC_C2 << ", " << current_high << "}" << std::endl;
//	ss << "    ImeasGain   = " << myAdapterCard->PSU[ch]->CalData.ImeasGain << std::endl;
//	ss << "    ImeasOffset = " << myAdapterCard->PSU[ch]->CalData.ImeasOffset << std::endl;
//
//	memo1->append(QString(ss.str().c_str()));
//  ss.str("");
//
//
//  // safe calibrations constants
//
//	// clean up and exit
//
//	Power(false);
//	SelectChannel(-1);
}

void MainForm::updateEEPROM()
{
	myAnalogCard->WriteCalDataEEPROM();
}
	
	
void MainForm::dumpEEPROM()
{
	myAnalogCard->ReadCalDataEEPROM();
	myAnalogCard->WriteCalDataFile();
	std::stringstream ssbuf;
	ssbuf << myUSB->GetName() << " ID: " << (int)myUSB->GetId() << ", Adapter card ID: " << (int)myAnalogCard->GetId();
	statusLabel->setText(ssbuf.str().c_str());
}

void MainForm::setId()
{
	myAnalogCard->SetId(IdNumBox->value());
}

void MainForm::setCurrLim()
{
	myAnalogCard->PWR[0]->SetCurrentLimit(CurrLimBox->value());
}

void MainForm::change4WireSense(bool enable)
{
	mySMU->Set4WireSense(enable);
}
