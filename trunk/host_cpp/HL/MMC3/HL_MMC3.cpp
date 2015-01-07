
#ifdef WIN32
#include <Windows.h>
#endif

#include <math.h>
#include "QDataStream.h"

#include "HL_MMC3.h"

SENSEAMP_INA226::SENSEAMP_INA226(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress, double Rsns): I2CDevice(HL, busAddress, slaveAddress)
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
  calReg = 0.00512/(0.0001 * mRsns);
	buffer[0] = INA226_CAL;
	buffer[1] = (byte)(0xff & calReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & calReg);
	status = mHL->Write(mHLAdd, buffer, 3);
	
	maskReg = 0x8001;  // shunt over voltage allert, latched
  buffer[0] = INA226_MASK;
	buffer[1] = (byte)(0xff & maskReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & maskReg);
	status = mHL->Write(mHLAdd, buffer, 3);

	return status;
}

bool SENSEAMP_INA226::SetCurrentLimit(double currentLimit)
{
	bool status = false;
	int limitReg;
	byte buffer[3];
	
	limitReg = mRsns * currentLimit;  // shunt voltage = Rsns * I_limit
  buffer[0] = INA226_ALLERT;
	buffer[1] = (byte)(0xff & limitReg >> 8); // MSB first
	buffer[2] = (byte)(0xff & limitReg);
	status = mHL->Write(mHLAdd, buffer, 3);

	return status;
}


SENSEAMP_INA226::~SENSEAMP_INA226(void)
{
	;
}

double SENSEAMP_INA226::GetCurrent(bool getRaw)
{
	unsigned char rawData[4];
	bool status;

	for (int i = 0; i < nsamples; i++)
	{
		status = mHL->Write(mHLAdd, &confByte, 1);
		if (!status)
		{
			DBGOUT("SENSEAMP_INA226::ReadCurrent:WriteI2C(...) failed\n");
		}
		status = mHL->Read(mHLAdd, rawData, 4);
	}
}

double SENSEAMP_INA226:: ReadVoltage()
{
	;
}

void   SENSEAMP_INA226:: Setup(unsigned char flags)
{
	;
}


PowerChannel::	PowerChannel(HL_base &HL, const char* name, int address): SENSEAMP_INA226(HL, I2CBUS_ADC, address)
{
	mName      = name;
}

const char* PowerChannel::GetName(void)
{
	return mName.c_str();
}


HL_MMC3::HL_MMC3(TL_base &TL): HL_base(TL)
{	
	Id = -1;
	//                        ( parent,     name, ch)
	PWR[0]   = new PowerSupply(  *this,   "PWR0", 0);
	PWR[1]   = new PowerSupply(  *this,   "PWR1", 1);
	PWR[2]   = new PowerSupply(  *this,   "PWR2", 2);
	PWR[3]   = new PowerSupply(  *this,   "PWR3", 3);

}

HL_MMC3::~HL_MMC3(void)
{
	for (int i = 0; i < MAX_PWR; i++)
		delete PWR[i];
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
  default:    
		status = false;
		break;
	}
	return status;
}

bool HL_MMC3::Read(HL_addr &hAddr, unsigned char *data, int nBytes)
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
	default:           
		status = false;
		break;
	}
	return status;
}


