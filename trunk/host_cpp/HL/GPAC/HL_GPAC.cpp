
#ifdef WIN32
    #include <Windows.h>
#endif

#include <math.h>
#include "QDataStream.h"

#include "HL_GPAC.h"

void * memcpy_reverse(const void* src, void* dst, int size)
{
	return memcpy(dst, src, size);
}

I2C_MUX::I2C_MUX(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress):I2CDevice(HL, busAddress, slaveAddress)
{
  ;
}

void I2C_MUX::SelectI2CBus(unsigned char I2Cbus)
{
	mHL->Write(mHLAdd , &I2Cbus, 1);  // set output lines
}

I2CIO_PCA9554::I2CIO_PCA9554(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress, unsigned char outputEnableMask):I2CDevice(HL, busAddress, slaveAddress)
{
	Write(0x00);
	OutputEnable(outputEnableMask);
}

void I2CIO_PCA9554::OutputEnable(unsigned char outputEnableMask)
{
	unsigned char buffer[2];

	buffer[0] = PCA9554_CFG;
	buffer[1] = outputEnableMask;
	mHL->Write(mHLAdd, buffer, 2);  // configure output lines
}

unsigned char I2CIO_PCA9554::Read(void)
{
	unsigned char buffer;

	mHL->Read(mHLAdd, &buffer, 1);  // read input lines
	return buffer;
}

void I2CIO_PCA9554::Write(unsigned char val)
{
	unsigned char buffer[2];

	buffer[0] = PCA9554_OUT;
	buffer[1] = val;
	mHL->Write(mHLAdd, buffer, 2);  /// write output lines
}

void I2CIO_PCA9554::SetBit(unsigned char bitVal)
{
	unsigned char oBuffer;
	unsigned char iBuffer;
	
	iBuffer = Read() ;
	oBuffer = iBuffer | bitVal;
	Write(oBuffer);  
}

void I2CIO_PCA9554::ClearBit(unsigned char bitVal)
{
	unsigned char oBuffer;
	unsigned char iBuffer;
	
	iBuffer = Read() ;
	oBuffer = iBuffer & ~bitVal;
	Write(oBuffer);    
}

bool I2CIO_PCA9554::GetBit(unsigned char bitVal)
{
	unsigned char iBuffer;
	
	iBuffer = Read();
	return (((iBuffer & bitVal) == bitVal)? true : false);
}

DAC_DAC7578::DAC_DAC7578(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress):I2CDevice(HL, busAddress, slaveAddress)
{
}

DAC_DAC7578::~DAC_DAC7578(void)
{
	;
}

bool DAC_DAC7578::SetDAC(unsigned char channel, unsigned short  val)
{
	unsigned char buffer[3];
	
	buffer[0] = DAC7578_CMD_UPDATE_CH | channel;
	buffer[1] = val >> 4;  // MSB first
	buffer[2] = val << 4;  // LSB left aligned

	return (mHL->Write(mHLAdd, buffer, 3));
}

bool DAC_DAC7578::SetDAC(int slaveAdd, unsigned char channel, unsigned short  val)
{
	unsigned char buffer[3];
	unsigned char temp_addr =	mHLAdd.LocalDeviceAddress;  // push slave address

	mHLAdd.LocalDeviceAddress = slaveAdd; // temporary overwrite slave address

	buffer[0] = DAC7578_CMD_UPDATE_CH & channel;
	buffer[1] = val >> 4;  // MSB first
	buffer[2] = val << 4;  // LSB left aligned

	return (mHL->Write(mHLAdd, buffer, 3));
	mHLAdd.LocalDeviceAddress = temp_addr; // pop slave address

}

ADC_MAX11644::ADC_MAX11644(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress):I2CDevice(HL, busAddress, slaveAddress)
{
	nAverage = 8;
}

ADC_MAX11644::~ADC_MAX11644(void)
{
}

bool ADC_MAX11644::ReadADC(double *data_ch_0, double *data_ch_1, int nsamples)
{
  unsigned char confByte = MAX11644_SCAN | MAX11644_SGL | MAX11644_CS0; // single-ended inputs, conversion of both channels in a scan
  unsigned char rawData[4];
	bool status;

	*data_ch_0 = 0;
	*data_ch_1 = 0;
	
	for (int i = 0; i < nsamples; i++)
	{
 		status = mHL->Write(mHLAdd, &confByte, 1);
		if (!status)
		{
			DBGOUT("ADC_MAX11644::ReadADC:WriteI2C(...) failed\n");
		}
		status = mHL->Read(mHLAdd, rawData, 4);
		if (!status)
		{
			DBGOUT("ADC_MAX11644::ReadADC:ReadI2C(...) failed\n");
		}

		*data_ch_0 += ((0x0f & rawData[0]) << 8) + rawData[1];
		*data_ch_1 += ((0x0f & rawData[2]) << 8) + rawData[3];
  }
  *data_ch_0 = *data_ch_0/(double)nsamples;
	*data_ch_1 = *data_ch_1/(double)nsamples;
	
	return status;
}

void  ADC_MAX11644::SetupADC(unsigned char flags)
{
	unsigned char buf = flags | MAX11644_SETUP;
	mHL->Write(mHLAdd, &buf, 1);
}

AnalogChannel::	AnalogChannel(HL_GPAC &HL, const char* name, int DACadd, int DACchannel, int ADCchannel): ADC_MAX11644(HL, I2CBUS_ADC, MAX11644_ADD), DAC_DAC7578(HL, I2CBUS_DAC, DACadd)
{
	mDACChannel  = DACchannel;
	mADCChannel  = ADCchannel;
	Name         = name;

	CalData.DACOffset  = 0.0;
	CalData.DACGain    = 0.5;
	CalData.VADCOffset = 0.0;
	CalData.VADCGain   = 2.0;
	CalData.IADCOffset = 0.0;
	CalData.IADCGain   = 2.0;
  CalData.MinValue   = 0;
  CalData.MaxValue   = 1;
  CalData.DefaultValue = 0;
  CalData.Limit      = 0;  // PWR only
  strncpy_s(CalData.name, name, min(MAX_CHANNEL_NAME_SIZE, strlen(name)));


	CALmux = new I2CIO_PCA9554(HL, I2CBUS_DEFAULT, CALMUX_GPIO_ADD, CALMUX_GPIO_CFG);
	ADCmux = new I2CIO_PCA9554(HL, I2CBUS_ADC, ADCMUX_GPIO_ADD, ADCMUX_GPIO_CFG);
//	SetValue(defaultVal, false);
}

const char* AnalogChannel::GetName(void)
{
	return UserName.c_str();
}

void AnalogChannel::SetupADC(unsigned char flags)
{
	ADC_MAX11644::SetupADC(flags);
}

void AnalogChannel::SetValue(double val, bool setRaw)
{
	int DACval;

	if (setRaw)
  {
    DACval = (int) val;
  }  
  else
  {
    if (val > CalData.MaxValue) val = CalData.MaxValue;
    if (val < CalData.MinValue) val = CalData.MinValue;      
	  DACval = (int) ((val - CalData.DACOffset)/ CalData.DACGain);
  }
	if (DACval > 4095) DACval = 4095;
	if (DACval < 0)	  DACval = 0;
	SetDAC(mDACChannel, DACval);
}

void AnalogChannel::UpdateMeasurements(int samples)
{
	ADCmux->Write(mADCChannel);
	ReadADC(&VoltageRaw, &CurrentRaw, samples);
}

double AnalogChannel::GetVoltage(bool getRaw)
{
	if (getRaw)
		return VoltageRaw;
	else
	  return (double)((VoltageRaw - CalData.VADCOffset) / CalData.VADCGain);
}

double AnalogChannel::GetCurrent(bool getRaw)
{
    if (getRaw) 
			return (CurrentRaw - VoltageRaw);
		else
		  return (double)(((CurrentRaw - VoltageRaw) - CalData.IADCOffset) / CalData.IADCGain);
}

void AnalogChannel::Select4Calibration(void)
{
	CALmux->Write(mADCChannel);
}


bool AnalogChannel::CalculateGainAndOffset(double x1, double y1, double x2, double y2, double &gain, double &offset)
{
  double g_nom = y2 - y1;
	double g_denom = x2 - x1;

	if (g_denom == 0)
		return false;

	gain = g_nom/g_denom;
  offset = y1 - x1 * gain;
	return true;
}

bool AnalogChannel::CalibrateDAC(double x1, double y1, double x2, double y2)
{
  double g_nom = y2 - y1;
	double g_denom = x2 - x1;

	if (g_denom == 0)
		return false;

	CalData.DACGain   = g_nom/g_denom;
  CalData.DACOffset = y1 - x1 * CalData.DACGain ;
	return true;
}

bool AnalogChannel::CalibrateVADC(double x1, double y1, double x2, double y2)
{
  double g_nom = y2 - y1;
	double g_denom = x2 - x1;

	if (g_denom == 0)
		return false;

	CalData.VADCGain   = g_nom/g_denom;
  CalData.VADCOffset = y1 - x1 * CalData.VADCGain;
	return true;
}

bool AnalogChannel::CalibrateIADC(double x1, double y1, double x2, double y2)
{
  double g_nom = y2 - y1;
	double g_denom = x2 - x1;

	if (g_denom == 0)
		return false;

	CalData.IADCGain   = g_nom/g_denom;
  CalData.IADCOffset = y1 - x1 * CalData.IADCGain;
	return true;
}

VoltageSource::VoltageSource(HL_GPAC &HL, const char* name, int channel): 
	             AnalogChannel(HL, name, VSRCAddressLUT[channel][0],  VSRCAddressLUT[channel][1],  VSRCAddressLUT[channel][2])
{
	// set specific design defaults
	CalData.DACOffset  = 0.0;
	CalData.DACGain    = 0.5;
	CalData.VADCOffset = 0.0;
	CalData.VADCGain   = 2.0;
	CalData.IADCOffset = 0.0;
	CalData.IADCGain   = 2.0;
}

VoltageSource* VoltageSource::Init(const char* uName, double minVal, double maxVal, double defaultVal)
{
	UserName = uName;
	

  CalData.MinValue   = minVal;
  CalData.MaxValue   = maxVal;
  CalData.DefaultValue = defaultVal;
	SetVoltage(defaultVal);
	return this;
}


void VoltageSource::SetVoltage(double mV, bool setRaw)
{
  SetValue(mV, setRaw);
}

InjVoltageSource::InjVoltageSource(HL_GPAC &HL, const char* name, int channel): 
	             AnalogChannel(HL, name, VSRCAddressLUT[channel][0],  VSRCAddressLUT[channel][1],  VSRCAddressLUT[channel][2])
{
}

InjVoltageSource* InjVoltageSource::Init(const char* uName, double minVal, double maxVal, double defaultVal)
{
	UserName = uName;
	
	// set specific design defaults
	CalData.DACOffset  = 0.0;
	CalData.DACGain    = 0.5;
  CalData.MinValue   = minVal;
  CalData.MaxValue   = maxVal;
  CalData.DefaultValue = defaultVal;
	SetVoltage(defaultVal);
	return this;
}

void InjVoltageSource::SetVoltage(double mV, bool setRaw)
{
  SetValue(mV, setRaw);
}

CurrentSource::CurrentSource(HL_GPAC &HL, const char* name, int channel): 
	             AnalogChannel(HL, name, ISRCAddressLUT[channel][0], ISRCAddressLUT[channel][1], ISRCAddressLUT[channel][2])
{
	// set specific design defaults
	CalData.DACOffset  = -1024.0;
	CalData.DACGain    = 0.5;
	CalData.VADCOffset = 0.0;
	CalData.VADCGain   = 2.0;
	CalData.IADCOffset = 0.0;
	CalData.IADCGain   = 2.0;
}

CurrentSource* CurrentSource::Init(const char* uName, double minVal, double maxVal, double defaultVal)
{
	UserName = uName;
	

  CalData.MinValue   = minVal;
  CalData.MaxValue   = maxVal;
  CalData.DefaultValue = defaultVal;
	SetCurrent(defaultVal);
	return this;
}

void CurrentSource::SetCurrent(double mA, bool setRaw)
{
  SetValue(mA, setRaw);
}

PowerSupply::PowerSupply(HL_GPAC &HL, const char* name, int channel): 
	             AnalogChannel(HL, name, PWRAddressLUT[channel][0], PWRAddressLUT[channel][1],  PWRAddressLUT[channel][2])
{
	// set specific design defaults
	CalData.DACOffset  = 2826.0;
	CalData.DACGain    =   -0.5;
	CalData.VADCOffset =    0.0;
	CalData.VADCGain   =    1.0;
	CalData.IADCOffset =    0.0;
	CalData.IADCGain   =   10.0;	
	mEnableBit = PWRAddressLUT[channel][3];
	PWRswitch = new I2CIO_PCA9554(HL, I2CBUS_DAC, POWER_GPIO_ADD, POWER_GPIO_CFG);
}

PowerSupply* PowerSupply::Init(const char* uName, double minVal, double maxVal, double defaultVal, double limit)
{
	UserName = uName;
	
  CalData.MinValue   = minVal;
  CalData.MaxValue   = maxVal;
  CalData.DefaultValue = defaultVal;
  CalData.Limit      = limit;  // PWR only
	SetVoltage(defaultVal);
	Switch(false);
	return this;
}

void PowerSupply::SetVoltage(double mV, bool setRaw)
{
  SetValue(mV, setRaw);
}

void PowerSupply::UpdateMeasurements(int samples)
{
	ADCmux->Write(mADCChannel);
	SetupADC(MAX11644_INT_REF);  // 4.096 reference
	Sleep(10);
	ReadADC(&VoltageRaw, &CurrentRaw, samples);
	SetupADC(MAX11644_EXT_REF);  // back to 2.048 reference
}

double PowerSupply::GetCurrent(bool getRaw)
{
    if (getRaw) 
			return (CurrentRaw);
		else
		  return (double)((CurrentRaw - CalData.IADCOffset) / CalData.IADCGain);
}

void PowerSupply::SetCurrentLimit(double mA_value)
{
	unsigned short raw = mA_value * CURRENT_LIMIT_GAIN;  
	SetDAC(CURRENT_LIMIT_DAC_SLAVE_ADD, CURRENT_LIMIT_DAC_CH, raw);
}

void PowerSupply::Switch(bool on_off)
{
	if (on_off)
	  PWRswitch->SetBit(mEnableBit);
	else
	  PWRswitch->ClearBit(mEnableBit);
}

HL_GPAC::HL_GPAC(TL_base &TL): HL_base(TL)
{	
  IniFileName = "GPAC.ini";
	IniFile = new CDataFile(IniFileName);
	Id = -1;
	I2Cmux  = new I2C_MUX(*this, I2CBUS_DEFAULT, PCA9540B_ADD);
	CalGPIO = new I2CIO_PCA9554(*this, I2CBUS_DEFAULT, CALMUX_GPIO_ADD, CALMUX_GPIO_CFG);

  //                        ( parent,     name, ch)
	PWR[0]   = new PowerSupply(  *this,   "PWR0", 0);
	PWR[1]   = new PowerSupply(  *this,   "PWR1", 1);
	PWR[2]   = new PowerSupply(  *this,   "PWR2", 2);
	PWR[3]   = new PowerSupply(  *this,   "PWR3", 3);

	VSRC[0]  = new VoltageSource(*this,  "VSRC0",  0);
	VSRC[1]  = new VoltageSource(*this,  "VSRC1",  1);
	VSRC[2]  = new VoltageSource(*this,  "VSRC2",  2);
	VSRC[3]  = new VoltageSource(*this,  "VSRC3",  3);

	VINJ[0]  = new InjVoltageSource(*this,  "VINJ0",  4);
	VINJ[1]  = new InjVoltageSource(*this,  "VINJ1",  5);

	ISRC[0]  = new CurrentSource(*this,  "ISRC0",  0);
	ISRC[1]  = new CurrentSource(*this,  "ISRC1",  1);
	ISRC[2]  = new CurrentSource(*this,  "ISRC2",  2);
	ISRC[3]  = new CurrentSource(*this,  "ISRC3",  3);
	ISRC[4]  = new CurrentSource(*this,  "ISRC4",  4);
	ISRC[5]  = new CurrentSource(*this,  "ISRC5",  5);
	ISRC[6]  = new CurrentSource(*this,  "ISRC6",  6);
	ISRC[7]  = new CurrentSource(*this,  "ISRC7",  7);
	ISRC[8]  = new CurrentSource(*this,  "ISRC8",  8);
	ISRC[9]  = new CurrentSource(*this,  "ISRC9",  9);
	ISRC[10] = new CurrentSource(*this, "ISRC10", 10);
	ISRC[11] = new CurrentSource(*this, "ISRC11", 11);

  // linear mapping of all P/V/C channels
	CH[0]  = PWR[0];
	CH[1]  = PWR[1];
	CH[2]  = PWR[2];
	CH[3]  = PWR[3];

	CH[4]  = VSRC[0];
	CH[5]  = VSRC[1];
	CH[6]  = VSRC[2];
	CH[7]  = VSRC[3];
	CH[8]  = VINJ[0]; // inject low
	CH[9]  = VINJ[1]; // inject high
  
	CH[10] = ISRC[0];
	CH[11] = ISRC[1];
	CH[12] = ISRC[2];
	CH[13] = ISRC[3];
	CH[14] = ISRC[4];
	CH[15] = ISRC[5];
	CH[16] = ISRC[6];
	CH[17] = ISRC[7];
	CH[18] = ISRC[8];
	CH[19] = ISRC[9];
	CH[20] = ISRC[10];
	CH[21] = ISRC[11];

	if (!ReadCalDataEEPROM())  
	  ReadCalDataFile();

	// do some init stuff
	PWR[0]->SetCurrentLimit(100);    // common for all power supplies
	PWR[0]->SetupADC(MAX11644_EXT_REF); // do this once for all}
}

HL_GPAC::~HL_GPAC(void)
{
	IniFile->Save();
	delete IniFile;

	for (int i = 0; i < MAX_PWR; i++)
		delete PWR[i];
	for (int i = 0; i < (MAX_VSRC + MAX_VINJ); i++)
		delete VSRC[i];
	for (int i = 0; i < MAX_ISRC; i++)
		delete ISRC[i];
	delete VINJ[0];
	delete VINJ[1];
	delete CalGPIO;
}

void HL_GPAC::Init(TL_base &TL)
{
	SetTLhandle(TL);
	IniFile->SetFileName(DEFAULT_INIFILE_NAME);

	if (!ReadCalDataEEPROM())  // EPPROM not found or Rev 1.0 Adapter Card
		ReadCalDataFile();
}

bool HL_GPAC::ReadCalDataFile(const char * adcfilename)
{
	
	bool status = false;
	std::stringstream ss;

	if (adcfilename != NULL)
  	status = IniFile->Load(adcfilename);
	else
  	status = IniFile->Load(IniFileName);

	for (int i = 0; i < MAX_CH; i++)
	{ 
		ss.str("");
		ss << CH[i]->CalData.name << " calibration constants";
		CH[i]->CalData.DefaultValue = IniFile->GetFloat("Default value", ss.str().c_str(), CH[i]->CalData.DefaultValue);
		CH[i]->CalData.DACOffset  = IniFile->GetFloat("DAC offset", ss.str().c_str(), CH[i]->CalData.DACOffset);
		CH[i]->CalData.DACGain    = IniFile->GetFloat("DAC gain",   ss.str().c_str(), CH[i]->CalData.DACGain);
		CH[i]->CalData.VADCOffset = IniFile->GetFloat("Voltage sense offset", ss.str().c_str(), CH[i]->CalData.VADCOffset);
		CH[i]->CalData.VADCGain   = IniFile->GetFloat("Voltage sense gain",   ss.str().c_str(), CH[i]->CalData.VADCGain);
		CH[i]->CalData.IADCOffset = IniFile->GetFloat("Current sense offset", ss.str().c_str(), CH[i]->CalData.IADCOffset);
		CH[i]->CalData.IADCGain   = IniFile->GetFloat("Current sense gain",   ss.str().c_str(), CH[i]->CalData.IADCGain);
	}
	return status;
}

bool HL_GPAC::WriteCalDataFile(const char * adcfilename)
{
	std::stringstream ss; 

	if (adcfilename != NULL)
	  IniFile->SetFileName(adcfilename);
	else
	  IniFile->SetFileName(IniFileName);

	for (int i = 0; i < MAX_CH; i++)
	{ 
		ss.str("");
		ss << CH[i]->CalData.name << " calibration constants";
		IniFile->SetFloat("Default voltage", CH[i]->CalData.DefaultValue, "Default value", ss.str().c_str());
		IniFile->SetFloat("DAC offset", CH[i]->CalData.DACOffset, "DAC offset (counts)", ss.str().c_str());
		IniFile->SetFloat("DAC gain",   CH[i]->CalData.DACGain ,  "DAC gain (counts)",   ss.str().c_str());
		IniFile->SetFloat("Voltage sense offset", CH[i]->CalData.VADCOffset, "VADC offset (counts)", ss.str().c_str());
		IniFile->SetFloat("Voltage sense gain",   CH[i]->CalData.VADCGain ,  "VADC gain (counts/V)",   ss.str().c_str());
		IniFile->SetFloat("Current sense offset", CH[i]->CalData.IADCOffset, "CADC offset (counts)", ss.str().c_str());
		IniFile->SetFloat("Current sense gain",   CH[i]->CalData.IADCGain ,  "CADC gain (counts/A)",   ss.str().c_str());
	}
	return IniFile->Save();
}

bool HL_GPAC::ReadCalDataEEPROM()
{
	unsigned int size;
	unsigned short header;
	unsigned char *dataBuf;
	unsigned char tmpBuf[2];
	unsigned int dataPtr;
	bool status;

	tmpBuf[0] = 0;
	tmpBuf[1] = 0;

	status = ReadCalEEPROMBytes(0, &tmpBuf[0], 2);
	header = (tmpBuf[0] << 8) + tmpBuf[1];

	if (!status)
	{
		DBGOUT("GPAC::ReadEEPROM()... No EEPROM found\n");
	  return false;
	}

	switch (header)
	{
	case CAL_DATA_HEADER_V1: 
    size = sizeof(eepromCalData);
		break;
	default: 
		DBGOUT("GPAC::ReadCalDataEEPROM()... No EEPROM or valid header found\n");
    return false;
	}
	
	dataBuf = 0;
	dataBuf = new unsigned char[size];

	if (!dataBuf)
		return false;

  status = ReadCalEEPROMBytes(0, dataBuf, size);

	dataPtr = 0;

	header = (dataBuf[dataPtr++] << 8) +  dataBuf[dataPtr++];
	Id     = (dataBuf[dataPtr++] << 8) +  dataBuf[dataPtr++];

//	if (calDataVersion == CAL_DATA_V2)
	{
	// de-serialize data struct (portability!)
		
		dataPtr = 2;  // skip header

		Id = (dataBuf[dataPtr] << 8) + dataBuf[dataPtr+1];
		dataPtr += 2;

		for (int i = 0; i < MAX_CH; i++)
		{
	//		memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.name), MAX_CHANNEL_NAME_SIZE);
			dataPtr += MAX_CHANNEL_NAME_SIZE;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.DefaultValue), 8);
			dataPtr += 8;
      memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.MinValue), 8);
			dataPtr += 8;
      memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.MaxValue), 8);
			dataPtr += 8;			
      memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.IADCGain), 8);
			dataPtr += 8;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.IADCOffset), 8);
			dataPtr += 8;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.VADCGain), 8);
			dataPtr += 8;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.VADCOffset), 8);
			dataPtr += 8;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.DACGain), 8);
			dataPtr += 8;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.DACOffset), 8);
			dataPtr += 8;
			memcpy_reverse(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.Limit), 8);
			dataPtr += 8;
		}
	}

	delete[] dataBuf;
	return status;
}

bool HL_GPAC::WriteCalDataEEPROM()
{
	unsigned int size;
	unsigned char *dataBuf;
	unsigned int dataPtr = 0;
	bool status = true;

	// hack
	int calDataVersion = CAL_DATA_V1;
	
	switch(calDataVersion)
	{
	  case CAL_DATA_V1:	
	    size = sizeof(eepromCalData); 
			break;
		case CAL_DATA_FILE:
			WriteCalDataFile(); return false;
		default: 
			DBGOUT("GPAC::WriteCalDataEEPROM()... no CAL_DATA_VERSION defined\n");
      return false;
	}

	dataBuf = 0;
	dataBuf = new unsigned char[size];

	if (!dataBuf)
		return false;

// serialize data struct (portability!)

	dataBuf[dataPtr++] = 0xff & (CAL_DATA_HEADER_V1 >> 8);
	dataBuf[dataPtr++] = 0xff & (CAL_DATA_HEADER_V1);
	dataBuf[dataPtr++] = 0xff & (Id >> 8);
	dataBuf[dataPtr++] = 0xff & (Id);

	for (int i = 0; i < MAX_CH; i++)
	{
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.name), MAX_CHANNEL_NAME_SIZE);
		dataPtr += MAX_CHANNEL_NAME_SIZE;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.DefaultValue), 8);
		dataPtr += 8;
    memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.MinValue), 8);
		dataPtr += 8;
    memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.MaxValue), 8);
		dataPtr += 8;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.IADCGain), 8);
		dataPtr += 8;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.IADCOffset), 8);
		dataPtr += 8;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.VADCGain), 8);
		dataPtr += 8;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.VADCOffset), 8);
		dataPtr += 8;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.DACGain), 8);
		dataPtr += 8;
		memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.DACOffset), 8);
		dataPtr += 8;
    memcpy(&dataBuf[dataPtr], (unsigned char*)(&CH[i]->CalData.Limit), 8);
		dataPtr += 8;
	}

	size = sizeof(eepromCalData); 
	status &= WriteCalEEPROMBytes(0, dataBuf, size);
	delete[] dataBuf;
	return status;
}

bool HL_GPAC::EraseCalDataEEPROM()
{
	int size;
	unsigned char *dataBuf;
	bool status = true;

  size = sizeof(eepromCalData); 
	dataBuf = 0;
	dataBuf = new unsigned char[size];
	if (!dataBuf)
		return false;

	for (int i = 0; i < size; i++)
		dataBuf[i] = 0xff;

	status &= WriteCalEEPROMBytes(0, dataBuf, size);
	delete[] dataBuf;
	return status;
}

bool HL_GPAC::WriteCalEEPROMBytes(int add, unsigned char * data, int size)
{
	HL_addr localHL;
  bool status = true;
	unsigned int nPages, nBytes;
	unsigned char add_data_buf[CAL_EEPROM_PAGE_SIZE + 2];
	unsigned int dataPtr;
	unsigned int addrPtr;

	localHL.LocalBusType       = BT_I2C;
	localHL.LocalBusAddress    = I2CBUS_DAC;
	localHL.LocalDeviceAddress = EEPROM_ADD;

	nPages = size / CAL_EEPROM_PAGE_SIZE;
	nBytes = size % CAL_EEPROM_PAGE_SIZE;

  addrPtr = add;
	dataPtr = 0;
	for (unsigned int i = 0; i < nPages; i++)  // 64 byte page write
	{
		// address offset  TODO: fix non page boundary address offset
		add_data_buf[0] = (unsigned char)(0x3f & (addrPtr >> 8));
		add_data_buf[1] = (unsigned char)(0xff & addrPtr);

		for (int j = 0; j < CAL_EEPROM_PAGE_SIZE; j++)
			add_data_buf[j + 2] = data[dataPtr + j];
	
		status &= this->Write(localHL, add_data_buf, CAL_EEPROM_PAGE_SIZE + 2);
		Sleep(10);
		dataPtr += CAL_EEPROM_PAGE_SIZE;
		addrPtr += CAL_EEPROM_PAGE_SIZE;
	} 

	if (nBytes > 0)
	{
		// address offset  TODO: fix non page boundary address offset
		add_data_buf[0] = (unsigned char)(0x3f & (addrPtr >> 8));
		add_data_buf[1] = (unsigned char)(0xff & addrPtr);

		for (unsigned int j = 0; j < nBytes; j++)
			add_data_buf[j + 2] = data[dataPtr + j];
	

		status &= this->Write(localHL, add_data_buf, nBytes + 2);
	}

	return status;
}

bool HL_GPAC::ReadCalEEPROMBytes(int add, unsigned char * data, int size)
{
	HL_addr localHL;
  bool status;
	unsigned char addBuf[2];
	unsigned int nPages, nBytes;
	unsigned int dataPtr;

	localHL.LocalBusType       = BT_I2C;
	localHL.LocalBusAddress    = I2CBUS_DAC;
	localHL.LocalDeviceAddress = EEPROM_ADD;

	nPages = size / CAL_EEPROM_PAGE_SIZE;
	nBytes = size % CAL_EEPROM_PAGE_SIZE;

	addBuf[0] = (unsigned char)(0x3f & (add >> 8));
	addBuf[1] = (unsigned char)(0xff & add);
  status  = this->Write(localHL, addBuf, 2);

	dataPtr = 0;
	for (unsigned int i = 0; i < nPages; i++)  // 64 byte page read
	{
  	status &= this->Read(localHL, &data[dataPtr], CAL_EEPROM_PAGE_SIZE);
		dataPtr += CAL_EEPROM_PAGE_SIZE;
	}
	if (nBytes > 0)
  status &= this->Read(localHL, &data[dataPtr], nBytes);

	return status;
}

void HL_GPAC::UpdateMeasurements()
{
	for (int i = 0; i < MAX_PWR; i++)
		PWR[i]->UpdateMeasurements();
  
	for (int i = 0; i < MAX_VSRC; i++)
		VSRC[i]->UpdateMeasurements();

	for (int i = 0; i < MAX_ISRC; i++)
		ISRC[i]->UpdateMeasurements();
}

bool HL_GPAC::Write(HL_addr &hAddr, unsigned char *data, int nBytes)
{
	bool status;
	//unsigned char LocalBusType       = hAddr.LocalBusType;
	//unsigned char LocalDeviceAddress = hAddr.LocalDeviceAddress;
	//unsigned long LocalAddress       = hAddr.LocalAddress;

	switch (hAddr.LocalBusAddress)
	{
	  case (I2CBUS_DEFAULT): 
									//	 I2Cmux->SelectI2CBus(I2CBUS_DEFAULT);
			               status = mTL->Write(hAddr.raw, data, nBytes); 
			               break;
	  case (I2CBUS_DAC): 
			               I2Cmux->SelectI2CBus(I2CBUS_DAC);
										 status = mTL->Write(hAddr.raw, data, nBytes); 
										 I2Cmux->SelectI2CBus(I2CBUS_DEFAULT);
										 break;
	  case (I2CBUS_ADC): 
			               I2Cmux->SelectI2CBus(I2CBUS_ADC);
										 status = mTL->Write(hAddr.raw, data, nBytes); 
										 I2Cmux->SelectI2CBus(I2CBUS_DEFAULT);
									 	 break;
		default:         status = false;
			               break;
	}
	return status;
}

bool HL_GPAC::Read(HL_addr &hAddr, unsigned char *data, int nBytes)
{
	bool status;
	//unsigned char LocalBusType       = hAddr.LocalBusType;
	//unsigned char LocalDeviceAddress = hAddr.LocalDeviceAddress;
	//unsigned long LocalAddress       = hAddr.LocalAddress;

	switch (hAddr.LocalBusAddress)
	{
	  case (I2CBUS_DEFAULT): 
			                     // I2Cmux->SelectI2CBus(I2CBUS_DEFAULT);
													 status = mTL->Read(hAddr.raw, data, nBytes); 
			                     break;
	  case (I2CBUS_DAC): I2Cmux->SelectI2CBus(I2CBUS_DAC);
										   status = mTL->Read(hAddr.raw, data, nBytes); 
										   I2Cmux->SelectI2CBus(I2CBUS_DEFAULT);
										   break;
	  case (I2CBUS_ADC): I2Cmux->SelectI2CBus(I2CBUS_ADC);
										   status = mTL->Read(hAddr.raw, data, nBytes); 
										   I2Cmux->SelectI2CBus(I2CBUS_DEFAULT);
									 	   break;
		default:           status = false;
			                 break;
	}
	return status;
}


