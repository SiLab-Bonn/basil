//------------------------------------------------------------------------------
//       I2CDevice.h
//
//       SILAB, Phys. Inst Bonn, HK
//
//  I2C device class
//
//  History:
//  04.03.03  added generic I2C Master
//  26.02.02  created
//------------------------------------------------------------------------------

#ifndef I2CDeviceH
#define I2CDeviceH

#include "SiUSBDevice.h"
#include <math.h>

#ifndef MSB
#define MSB(word)		(unsigned char)(((unsigned short)word >> 8) & 0xff)
#endif
#ifndef LSB
#define LSB(word)		(unsigned char)((unsigned short)word & 0xff)
#endif

//--- I2C device type ID ---
#define I2C_DEV_TYPE_EEPROM   0x10
//#define I2C_DEV_TYPE_EEPROM   0xa0
#define I2C_DEV_TYPE_POT      0x50
#define I2C_DEV_TYPE_ADC      0x50

//--- Instruction bytes for Digital Potentiometer Xicor X9582 ---
#define X9582_INSTR_SETWHIPER   0xa0
#define X9582_INSTR_SETREGISTER 0xc0
#define X9582_INSTR_XFRR2W      0xd0
#define X9582_INSTR_XFRW2R      0xe0
#define X9582_INSTR_GXFRR2W     0x80
#define X9582_INSTR_GXFRW2R     0x20

//--- Instruction bytes for ADC MAX127/128 ---
#define MAX127_CTRL_START       0x80
#define MAX127_CTRL_BIPOL       0x04
#define MAX127_CTRL_RNG         0x08
#define MAX127_CTRL_PWRON       0x00
#define MAX127_CTRL_STDBY       0x02
#define MAX127_CTRL_PWRDN       0x03
#define MAX127_VREF             4096

//--- Register table for CY22150 Clock Generator
#define CG_ADD_CLKOE                0x09
#define CG_ADD_DIV1                 0x0c
#define CG_ADD_INPDRV               0x12
#define CG_ADD_INPCAP               0x13
#define CG_ADD_CHG_PB               0x40
#define CG_ADD_PB                   0x41
#define CG_ADD_PO_Q                 0x42
#define CG_ADD_XS1                  0x44
#define CG_ADD_XS2                  0x45
#define CG_ADD_XS3                  0x46
#define CG_ADD_DIV2                 0x47

#define CG_LCLK1_EN                 0x01
#define CG_LCLK2_EN                 0x02
#define CG_LCLK3_EN                 0x04
#define CG_LCLK4_EN                 0x08
#define CG_CLK5_EN                  0x10
#define CG_CLK6_EN                  0x20
#define CG_DEF_INPDRV               0x20
#define CG_DEF_INPCAP               0x00

#define CG_FREF                     ((double) 24.0)
#define CG_FREF_FX                  ((double) 48.0)

#define IS_INTEGER(a)               (a - ceil(a) == 0) ? true : false
#define IS_EVEN(a)                  ((a % 2) == 0) ? true : false


class TI2CMaster;

class TI2CDevice
{
public:
	TI2CDevice(TI2CMaster *Master);
	bool isOk;
protected:
	TI2CMaster *I2CMaster;
	unsigned char SlaveAdd;
private:

};

class TI2CEeprom: public TI2CDevice
{
public:
	TI2CEeprom(unsigned char DevAdd, bool isDoubleByteAdd, TI2CMaster *Master);
	//  ~TI2CEeprom();
	bool ReadByte(unsigned short Add, unsigned char *Data);
	bool WriteByte(unsigned short Add, unsigned char *Data);
private:
	bool isDoubleByte;
	unsigned char AddLength;
};

class TI2CPot: public TI2CDevice
{
public:
	TI2CPot(unsigned char DevAdd, TI2CMaster *Master);
	~TI2CPot();
	bool SetWhiper(unsigned char PotiId, unsigned char *Data);
	bool SetRegister(unsigned char PotiId, unsigned char RegId, unsigned char *Data);
	bool XFRReg2Whiper(unsigned char PotId, unsigned char RegId);
	bool XFRWhiper2Reg(unsigned char PotId, unsigned char RegId);
	bool GlobalXFRReg2Whiper(unsigned char RegId);
	bool GlobalXFRWhiper2Reg(unsigned char RegId);
};


class TI2CAdc: public TI2CDevice
{
public:
	TI2CAdc(unsigned char DevAdd, bool IsHalfInputRange, bool IsBipolar, TI2CMaster * Master);
	//  ~TI2CAdc();
	bool GetVoltage(unsigned char ChannelId, double *Val);
	void SetGain(double Gain);
	void SetOffset(double Offset);
	double GetGain();
	double GetOffset();
	void SetRangeAndPolarity(bool IsHalfInputRange, bool IsBipolar);
private:
	unsigned char ControlByte;
	double Gain;
	double Offset;
};


class TI2CClockGen: public TI2CDevice
{
public:
	TI2CClockGen(TI2CMaster * Master, double mfref);
	bool SetFrequency(double freq);
	bool SetRefClockFrequency(double f);
	double fout;
	bool last_status;
	int  p_counter;
	unsigned char p_0;
	int  p_total;
	unsigned char q_counter;
	unsigned char q_total;
	unsigned char div;
	unsigned char div1N;
	unsigned char div1SRC;
	unsigned char div2N;
	unsigned char div2SRC;
	unsigned char clk1SRC;
	unsigned char clk2SRC;
	unsigned char chg_pump;
	double fref;
	bool SetRegister(unsigned char add, unsigned char data);
	unsigned char GetRegister(unsigned char add);


private:
	bool CalculatePLLParameters(double freq);
	void UpdatePLLRegisters();
	bool ReadByte(unsigned char add, unsigned char *data);
	bool WriteByte(unsigned char add, unsigned char *data);


};
#endif

