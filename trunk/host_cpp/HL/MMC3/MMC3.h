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


class MMC3
{
public:
	MMC3(void);
	~MMC3(void);
	void Init();
	double GetVoltage();
	double GetCurrent();
	void ReadRegister(byte RegAdd, int *data);
	void WriteRegister(byte RegAdd, int *data);
};

