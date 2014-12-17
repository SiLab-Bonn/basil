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

#define DEFAULT_INIFILE_NAME "GPAC.ini"

// I2C bus multiplexer (PCA9540B) 
#define PCA9540B_ADD      (0xE0)  // slave address
#define PCA9540B_SEL_CH0  (0x04)  // select channel 0
#define PCA9540B_SEL_CH1  (0x05)  // select channel 1
#define PCA9540B_SEL_NONE (0x00)  // de-select channels

#define I2CBUS_ADC      PCA9540B_SEL_CH1
#define I2CBUS_DAC      PCA9540B_SEL_CH0
#define I2CBUS_DEFAULT  PCA9540B_SEL_NONE

// GPIO extension (PCA9554) 
#define PCA9554_ADD (0x40)    // generic slave address
#define PCA9554_CFG (0x03)    // configuration register: 1->input (default), 0->output
#define PCA9554_OUT (0x01)    // output port register

#define POWER_GPIO_ADD  (PCA9554_ADD | 0x02 ) 
#define POWER_GPIO_CFG  (0xf0)  // LSB -> ON, MSB-> OC (over current read back)

#define ADCMUX_GPIO_ADD  (PCA9554_ADD ) 
#define ADCMUX_GPIO_CFG  (0x00)  // all outputs

#define CALMUX_GPIO_ADD  (PCA9554_ADD | 0x08 ) 
#define CALMUX_GPIO_CFG  (0x00)  // all outputs
#define CALMUX_GPIO_SEL   0x20
#define CALMUX_GPIO_INHB  0x40


// EEPROM (calibration data storage)
#define EEPROM_ADD (0xA8)    //slave address
#define CAL_DATA_HEADER_V1 ((unsigned short)(0xa101))
#define CAL_DATA_HEADER_V2 ((unsigned short)(0xa102))
#define CAL_EEPROM_PAGE_SIZE 32
#define MAX_CHANNEL_NAME_SIZE 64
enum {CAL_DATA_V1, CAL_DATA_V2, CAL_DATA_FILE};

// DAC (DAC7578)
#define DAC7578_1_ADD (0x90)  // slave addresses
#define DAC7578_2_ADD (0x94)
#define DAC7578_3_ADD (0x98)
#define DAC7578_CMD_UPDATE_CH (0x30)  // load DAC register (n -> [2:0]) and update DAC 

// ADC (MAX11644)
#define MAX11644_ADD     (0x6C)  // slave address
// setup register
#define MAX11644_SETUP   (0x80)  // defines setup register access
#define MAX11644_EXT_REF (0x20)  // select external reference (2.048V)
#define MAX11644_INT_REF (0x50)  // select internal reference (4.096V)
#define MAX11644_EXT_CLK (0x08)  // select external clock (SCL)
// configuration register
#define MAX11644_SCAN_SINGLE  (0x60)  // convert selected channel only
#define MAX11644_SCAN_SINGLE8 (0x20)  // convert selected channel 8 times
#define MAX11644_SCAN         (0x00)  // convert channel 0 - CS0 (default)
#define MAX11644_CS0          (0x02)  // set scan range to channel 1
#define MAX11644_SGL          (0x01)  // sets single-ended mode conversion

#define NSAMPLES 4

#define MAX_PWR    4
#define MAX_VSRC   4  
#define MAX_VINJ   2  
#define MAX_ISRC  12
#define MAX_CH   (MAX_PWR + MAX_VSRC + MAX_VINJ + MAX_ISRC)

#define CURRENT_LIMIT_GAIN  20  // hack -> calibrate!
#define CURRENT_LIMIT_DAC_CH 0
#define CURRENT_LIMIT_DAC_SLAVE_ADD DAC7578_1_ADD

#define RAW true
#define ON  true
#define OFF false

const unsigned char PWRAddressLUT[4][4] =
// DAC I2C addr, DAC ch, ADC mux, on/off bit
{{DAC7578_1_ADD, 1, 16, 0x01},  // PWR
 {DAC7578_1_ADD, 2, 17, 0x02},
 {DAC7578_1_ADD, 3, 18, 0x04},
 {DAC7578_1_ADD, 4, 19, 0x08}};
 
const unsigned char VSRCAddressLUT[6][3] =
// DAC I2C addr, DAC ch, ADC mux
{{DAC7578_3_ADD, 1, 15},     // VSRC 
 {DAC7578_3_ADD, 2, 14},      
 {DAC7578_3_ADD, 3, 13},      
 {DAC7578_3_ADD, 4, 12},
 {DAC7578_3_ADD, 5, 0},      // inject low   
 {DAC7578_3_ADD, 6, 0}};     // inject high 
                             
const unsigned char ISRCAddressLUT[12][3] =
// DAC I2C addr, DAC ch, ADC mux
{{DAC7578_1_ADD, 5, 20},     // ISRC   
 {DAC7578_1_ADD, 6, 21},      
 {DAC7578_1_ADD, 7, 22},      
 {DAC7578_2_ADD, 0, 23},      
 {DAC7578_2_ADD, 1, 24},      
 {DAC7578_2_ADD, 2, 25},      
 {DAC7578_2_ADD, 3, 26},      
 {DAC7578_2_ADD, 4, 27},
 {DAC7578_2_ADD, 5, 28},      
 {DAC7578_2_ADD, 6, 29},      
 {DAC7578_2_ADD, 7, 30},      
 {DAC7578_3_ADD, 0, 31}};   

#pragma pack(push)  
#pragma pack(1)  // avoid byte packing
typedef struct calConstStruct_
{
	char   name[MAX_CHANNEL_NAME_SIZE];
	double DACOffset;
  double DACGain;
	double IADCOffset;
  double IADCGain;
	double VADCOffset;
  double VADCGain;
	double DefaultValue;
	double MinValue;
	double MaxValue;
  double Limit;
	double VREF;
} calConstStruct;

typedef struct eepromDataStruct_
{ 
	unsigned short header;
  unsigned short Id;
  calConstStruct chCalData[MAX_CH];
} eepromDataStruct;
#pragma pack(pop)


class HL_GPAC;

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

class PIXDECLDIR I2CIO_PCA9554: public I2CDevice
{
public:
	I2CIO_PCA9554(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress, unsigned char outputEnableMask);
	void OutputEnable(unsigned char bitMask);
	unsigned char Read(void);
	void Write(unsigned char val);
	void SetBit(unsigned char bitVal);
	void ClearBit(unsigned char bitVal);
	bool GetBit(unsigned char bitVal);
};

class  DAC_DAC7578: public I2CDevice
{
public:
	DAC_DAC7578(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress);
	~DAC_DAC7578(void);
  bool SetDAC(unsigned char channel, unsigned short val);
  bool SetDAC(int slaveAdd, unsigned char channel, unsigned short  val);
};

class  ADC_MAX11644: public I2CDevice
{
public:
	ADC_MAX11644(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress);
	~ADC_MAX11644(void);
  bool ReadADC(double *data_ch_0, double *data_ch_1, int sample = NSAMPLES);
	void SetupADC(unsigned char flags);
	int  nAverage;
};

class PIXDECLDIR AnalogChannel: public ADC_MAX11644, public DAC_DAC7578
{
public:
	AnalogChannel(HL_GPAC &HL, const char* name, int DACadd, int DACchannel, int ADCchannel);
	void   SetupADC(unsigned char flags); 
  void   SetValue(double val, bool setRaw = false);
	void   UpdateMeasurements(int samples = NSAMPLES);
	double GetVoltage(bool getRaw = false);
	double GetCurrent(bool getRaw = false);
	void   Select4Calibration(void);
	bool   CalculateGainAndOffset(double x1, double y1, double x2, double y2, double &gain, double &offset);
	bool   CalibrateDAC(double x1, double y1, double x2, double y2);
	bool   CalibrateVADC(double x1, double y1, double x2, double y2);
	bool   CalibrateIADC(double x1, double y1, double x2, double y2);
	calConstStruct CalData;
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

class PIXDECLDIR InjVoltageSource: public AnalogChannel
{
public:
	InjVoltageSource(HL_GPAC &HL, const char* name, int channel);
	~InjVoltageSource(){};
	InjVoltageSource* Init(const char* UserName, double minVal, double maxVal, double defaultVal);
	void SetVoltage(double val, bool setRaw = false);
protected:
};

class PIXDECLDIR VoltageSource: public AnalogChannel
{
public:
	VoltageSource(HL_GPAC &HL, const char* name, int channel);
	~VoltageSource(){};
	VoltageSource* Init(const char* UserName, double minVal, double maxVal, double defaultVal);
	void SetVoltage(double val, bool setRaw = false);
protected:
};

class PIXDECLDIR CurrentSource: public AnalogChannel
{
public:
	CurrentSource(HL_GPAC &HL, const char* name, int channel);
	~CurrentSource(){};
	CurrentSource* Init(const char* UserName, double minVal, double maxVal, double defaultVal);
	void SetCurrent(double val, bool setRaw = false);
protected:
};

class PIXDECLDIR PowerSupply: public AnalogChannel
{
public:
	PowerSupply(HL_GPAC &HL, const char* name, int channel);
	~PowerSupply(){};
	PowerSupply* Init(const char* UserName, double minVal, double maxVal, double defaultVal, double limit);
	void UpdateMeasurements(int samples = NSAMPLES);
	void SetVoltage(double val, bool setRaw = false);
	void Switch(bool on_off);	double GetCurrent(bool getRaw = false);
	void SetCurrentLimit(double mA_value);
protected:
  unsigned char mEnableBit;
	I2CIO_PCA9554 *PWRswitch;
};


class PIXDECLDIR HL_GPAC: public HL_base
{
public:
	HL_GPAC(TL_base &TL);
	~HL_GPAC(void);
	void Init(TL_base &TL);
	bool Write(HL_addr &hAdd, unsigned char *data, int nBytes);
	bool Read(HL_addr &hAdd, unsigned char *data, int nBytes);
	void UpdateMeasurements();
	bool ReadCalDataFile(const char * adcfilename = NULL);
	bool WriteCalDataFile(const char * adcfilename = NULL);
	bool WriteCalDataEEPROM();
  bool EraseCalDataEEPROM();
	bool ReadCalDataEEPROM();
	bool ReadCalEEPROMBytes(int add, unsigned char * data, int size);
	bool WriteCalEEPROMBytes(int add, unsigned char * data, int size);
	int  GetId(){ return Id;};
	void SetId(int nId){ Id = nId;};
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


