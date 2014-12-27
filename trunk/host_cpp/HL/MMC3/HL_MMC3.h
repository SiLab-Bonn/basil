#pragma once

#include "TL_base.h"
#include "HL_base.h"
#include "CDataFile.h"

#ifdef WIN32 
  #ifdef GPAC_DLL_EXPORT
    #define PIXDECLDIR __declspec(dllexport)
  #else
    #define PIXDECLDIR __declspec(dllimport)
  #endif
#endif

#pragma once
#include "TL_base.h"
#include "HL_base.h"

#ifdef WIN32 
  #ifdef MMC3_DLL_EXPORT
    #define PIXDECLDIR __declspec(dllexport)
  #else
    #define PIXDECLDIR __declspec(dllimport)
  #endif
#endif

// I2C shunt sensor INA226
#define INA226_BASEADD 0x80
#define INA226_CONFREG 0
#define INA226_SHUNTV  1
#define INA226_BUSV    2
#define INA226_POWER   3
#define INA226_CURR    4
#define INA226_CAL     5
#define INA226_MASK    6
#define INA226_ALLERT  7

// INA226 config register bits location
#define INA226_CONFREG_MODE         0
#define INA226_CONFREG_VSHCT        3
#define INA226_CONFREG_VBHCT        6
#define INA226_CONFREG_AVG          9
#define INA226_CONFREG_RESET       15

// INA226 maske/enable register bits location
#define INA226_MASK_LEN        0
#define INA226_MASK_APOL       1
#define INA226_MASK_OVF        2
#define INA226_MASK_CVRF       3
#define INA226_MASK_AFF        4
#define INA226_MASK_CNVR       10
#define INA226_MASK_POL        11
#define INA226_MASK_BUL        12
#define INA226_MASK_BOL        13
#define INA226_MASK_SUL        14
#define INA226_MASK_SOL        15


class HL_MMC3: public HL_base
{
public:
	HL_MMC3(TL_base &TL);
	~HL_MMC3(void);
	void Init();
	double GetVoltage();
	double GetCurrent();
	void ReadRegister(byte RegAdd, int *data);
	void WriteRegister(byte RegAdd, int *data);
};




class I2CDevice
{
public:
	I2CDevice::I2CDevice(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress);
	HL_addr mHLAdd;
protected:
	HL_I2CMaster *mHL;
};

class  I2C_MUX: public I2CDevice
{
public:
	I2C_MUX(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress);
	void  SelectI2CBus(unsigned char I2Cbus);
};


class  SENSEAMP_INA226: public I2CDevice
{
public:
	SENSEAMP_INA226(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress);
	~SENSEAMP_INA226(void);
  bool ReadCurrent(double *data_ch_0, double *data_ch_1, int sample = NSAMPLES);
	void SetupADC(unsigned char flags);
	int  nAverage;
};

class PIXDECLDIR PowerChannel: public SENSEAMP_INA226
{
public:
	PowerChannel(HL_MMC3 &HL, const char* name, int DACadd, int DACchannel, int ADCchannel);
	~PowerChannel();
	void   UpdateMeasurements(int samples = NSAMPLES);
	double GetVoltage(bool getRaw = false);
	double GetCurrent(bool getRaw = false);

	const char* GetName(void);

protected:
	int    mDACSlaveAdd;
	int    mDACChannel;
	int    mADCChannel;
	double Voltage;
	double Current;
	double VoltageRaw;
	double CurrentRaw;
	double VsetRaw;
	string Name;
	string UserName;
	I2CIO_PCA9554 *ADCmux;
	I2CIO_PCA9554 *CALmux;
};



class PIXDECLDIR HL_MMC3: public HL_base
{
public:
	HL_MMC3(TL_base &TL);
	~HL_MMC3(void);
	void Init(TL_base &TL);
	bool Write(HL_addr &hAdd, unsigned char *data, int nBytes);
	bool Read(HL_addr &hAdd, unsigned char *data, int nBytes);
	void UpdateMeasurements();
	I2CIO_PCA9554 *CalGPIO;
	AnalogChannel    *CH[MAX_CH];	
	VoltageSource    *VSRC[MAX_VSRC];
	InjVoltageSource *VINJ[MAX_VINJ];
	CurrentSource    *ISRC[MAX_ISRC];
	PowerSupply      *PWR[MAX_PWR];

private:
	void InitChannels();
  I2C_MUX *I2Cmux;
	CDataFile  *IniFile;
	std::string IniFileName;
	eepromDataStruct eepromCalData;
	unsigned short Id;
};


