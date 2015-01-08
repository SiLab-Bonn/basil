#include "HL_base.h"


I2CDevice::I2CDevice(HL_base &HL, unsigned char busAddress, unsigned char slaveAddress)
{
	mHL = &HL;
	mHLAdd.LocalBusType       = BT_I2C;
	mHLAdd.LocalBusAddress    = busAddress;
	mHLAdd.LocalDeviceAddress = slaveAddress;
}

HL_base::HL_base(TL_base &TL)
{
	mTL = &TL;
}

void HL_base::SetTLhandle(TL_base &TL)
{
	mTL = &TL;
}
