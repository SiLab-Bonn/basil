
#ifdef WIN32
#include <Windows.h>
#endif

#include <math.h>
#include "QDataStream.h"

#include "HL_MMC3.h"

SENSEAMP_INA226::SENSEAMP_INA226(HL_base &HL, unsigned char busAddress, unsigned char slaveAddress, double Rsns): I2CDevice(HL, busAddress, slaveAddress)
{
	mRsns = Rsns;
	Configure();
}

bool SENSEAMP_INA226::Configure()
{
	bool status = false;
	int confReg;
	int calReg;
	int maskReg;
	byte buffer[3];
	byte Avg = 0;      // 0..15 --> 1..1024 averges
	byte VbusCT = 4;   // 0..15 --> 140µs..8.24ms
	byte VshuntCT = 4; // 0..15 --> 140µs..8.24ms
	byte Mode = 7; // cont. shunt and bus monitoriung

	confReg = (Avg << INA226_CONFREG_AVG) + (VbusCT << INA226_CONFREG_VBHCT) + (VshuntCT << INA226_CONFREG_VSHCT) + (Mode << INA226_CONFREG_MODE);
	buffer[0] = INA226_CONFREG;
	buffer[1] = (byte)(0xff & confReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & confReg);
	status = mHL->Write(mHLAdd, buffer, 3);

	// CAL = 0.00512/(CURRENT_LSB * R_SNS), 
	// CURRENT_LSB = Imax / 2^15
	//  
	//  Imax = 3.2516A (@ Rsns=25mOhm) --> LSB = 99µA --> 100µA
	//  
	calReg = 0.00512/(INA226_CURRENT_LSB * mRsns);
	buffer[0] = INA226_CAL;
	buffer[1] = (byte)(0xff & calReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & calReg);
	status = mHL->Write(mHLAdd, buffer, 3);

	maskReg = 0x8001;  // shunt over voltage allert, latched
//	maskReg = 0x8002;  // shunt over voltage allert, active high, latched
	buffer[0] = INA226_MASK;
	buffer[1] = (byte)(0xff & maskReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & maskReg);
	status = mHL->Write(mHLAdd, buffer, 3);

	return status;
}

int SENSEAMP_INA226::ReadMaskReg()
{
	int maskReg;
	bool status = false;
	byte buffer[3];

	buffer[0] = INA226_MASK;
	status = mHL->Write(mHLAdd, buffer, 1);
	status = mHL->Read(mHLAdd, buffer, 2);

	return (int)((buffer[0] << 8) + buffer[1]) ;
}


SENSEAMP_INA226::~SENSEAMP_INA226(void)
{
	;
}

double SENSEAMP_INA226::ReadCurrent()
{
	byte add = INA226_CURR;
	byte rawData[2];
	bool status;

	status = mHL->Write(mHLAdd, &add, 1);
	//if (!status)
	//{
	//	DBGOUT("SENSEAMP_INA226::GetCurrent:WriteI2C(...) failed\n");
	//}
	status = mHL->Read(mHLAdd, rawData, 2);

	return (double) (signed short)(((rawData[0] << 8) + rawData[1]))* INA226_CURRENT_LSB;
}

double SENSEAMP_INA226:: ReadVoltage()
{
	byte add = INA226_BUSV;
	byte rawData[2];
	bool status;

	status = mHL->Write(mHLAdd, &add, 1);
	//if (!status)
	//{
	//	DBGOUT("SENSEAMP_INA226::GetCurrent:WriteI2C(...) failed\n");
	//}
	status = mHL->Read(mHLAdd, rawData, 2);

	return (double) (((rawData[0] << 8) + rawData[1]) * INA226_BUSV_GAIN);
}


PowerChannel::PowerChannel(HL_base &HL, const char* name, int I2Caddress, int regAdd, int regBit, double Rsns): SENSEAMP_INA226(HL, 0, I2Caddress, Rsns)
{
	mName   = name;
	mRegBit = regBit;
	PWR_EN  = new basil_gpio( &HL, name, regAdd, 1, true, false);	
	SetCurrentLimit(INA226_DEFAULT_LIMIT);
	ClearAlert();
}

void PowerChannel::Switch(bool on_off)
{
	byte buffer;
	buffer = PWR_EN->Get();

	if (on_off)
		buffer |= 1 << mRegBit;
	else
		buffer &= ~(1 << mRegBit);

	PWR_EN->Set(buffer);
}


const char* PowerChannel::GetName(void)
{
	return mName.c_str();
}

void PowerChannel::UpdateMeasurements()
{
	Voltage = ReadVoltage();
	Current = ReadCurrent();
}

double PowerChannel::GetVoltage()
{
	return Voltage;
}

double PowerChannel::GetCurrent()
{
	return Current;
}


bool PowerChannel::ClearAlert()
{
	return ((ReadMaskReg() & (1 << INA226_MASK_AFF)) == (1 << INA226_MASK_AFF));
}


bool PowerChannel::SetCurrentLimit(double currentLimit)
{
	bool status = false;
	int limitReg;
	byte buffer[3];

	limitReg = mRsns * currentLimit / INA226_SHUNTV_GAIN;  // shunt voltage = Rsns * I_limit
	buffer[0] = INA226_ALLERT;
	buffer[1] = (byte)(0xff & limitReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & limitReg);
	status = mHL->Write(mHLAdd, buffer, 3);

	return status;
}


HL_MMC3::HL_MMC3(TL_base &TL): HL_base(TL)
{	
	Id = -1;
	//                        ( parent,     name, ch)
	PWR[0]   = new PowerChannel(  *this,   "PWR_A", INA226_A_BASEADD, PWR_EN_REG_ADD, PWR_EN_A_BIT, 0.025);
	PWR[1]   = new PowerChannel(  *this,   "PWR_B", INA226_B_BASEADD, PWR_EN_REG_ADD, PWR_EN_B_BIT, 0.025);
	PWR[2]   = new PowerChannel(  *this,   "PWR_C", INA226_C_BASEADD, PWR_EN_REG_ADD, PWR_EN_C_BIT, 0.025);
	PWR[3]   = new PowerChannel(  *this,   "PWR_C", INA226_D_BASEADD, PWR_EN_REG_ADD, PWR_EN_D_BIT, 0.025);
}

HL_MMC3::~HL_MMC3(void)
{
	for (int i = 0; i < MAX_MMC3_PWR; i++)
	{
		PWR[i]->Switch(OFF);
		delete PWR[i];
	}
}

void HL_MMC3::Init(TL_base &TL)
{
	SetTLhandle(TL);
}

void HL_MMC3::UpdateMeasurements()
{
	for (int i = 0; i < MAX_MMC3_PWR; i++)
		PWR[i]->UpdateMeasurements();
}

bool HL_MMC3::Write(HL_addr &hAddr, unsigned char *data, int nBytes)
{
	return mTL->Write(hAddr.raw, data, nBytes); ;
}

bool HL_MMC3::Read(HL_addr &hAddr, unsigned char *data, int nBytes)
{
	return mTL->Read(hAddr.raw, data, nBytes); 
}


