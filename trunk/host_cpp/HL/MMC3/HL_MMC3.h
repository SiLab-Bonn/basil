#pragma once

#include "TL_base.h"
#include "HL_base.h"
#include "basil_gpio.h"

#ifdef WIN32 
  #ifdef MMC3_DLL_EXPORT
    #define MMC3DECLDIR __declspec(dllexport)
  #else
    #define MMC3DECLDIR __declspec(dllimport)
  #endif
#endif

// I2C shunt sensor INA226
#define INA226_A_BASEADD 0x80
#define INA226_B_BASEADD 0x82
#define INA226_C_BASEADD 0x88
#define INA226_D_BASEADD 0x8A
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

#define INA226_DEFAULT_LIMIT       1 // ampere
#define INA_226_BUSV_GAIN          0.00125   // VBUS_ADC_LSB = 1.25mV 
#define INA_226_SHUNTV_GAIN        0.0000025 // VSHUNT_ADC_LSB = 2.5µV 


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

#define MAX_MMC3_PWR                4  // number of power channels on MMC3 board

#define I2CBUS_DEFAULT  0

#define PWR_EN_REG_ADD  0x1004    // gpio module for power enable bits
#define PWR_EN_A_BIT    0
#define PWR_EN_B_BIT    1
#define PWR_EN_C_BIT    2
#define PWR_EN_D_BIT    3



class  SENSEAMP_INA226: public I2CDevice
{
public:
	SENSEAMP_INA226(HL_base &HL, unsigned char busAddress, unsigned char slaveAddress, double Rsns);
	~SENSEAMP_INA226(void);
  double  ReadCurrent();
  double  ReadVoltage();
	bool    SetCurrentLimit(double currentLimit);
  bool    Configure();

protected:
	double mRsns;

};

class MMC3DECLDIR PowerChannel: public SENSEAMP_INA226
{
public:
	PowerChannel(HL_base &HL, const char* name, int address, double Rsns);
	//~PowerChannel();
	void   UpdateMeasurements();
	double GetVoltage();
	double GetCurrent();
	void   Switch(bool on_off);
	const char* GetName(void);

protected:
	string mName;
	SENSEAMP_INA226 *SenseAmp;
	double Voltage;
	double Current;
	double VoltageRaw;
	double CurrentRaw;
};


class MMC3DECLDIR HL_MMC3: public HL_base
{
public:
	HL_MMC3(TL_base &TL);
	~HL_MMC3(void);
	void Init(TL_base &TL);
	bool Write(HL_addr &hAdd, unsigned char *data, int nBytes);
	bool Read(HL_addr &hAdd, unsigned char *data, int nBytes);
	void UpdateMeasurements();
	void PwrSwitch(byte idx, bool on_off);
	PowerChannel  *PWR[MAX_MMC3_PWR];

private:
	void InitChannels();
	basil_gpio *PWR_EN;
	unsigned short Id;
};


