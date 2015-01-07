#include "HL_base.h"


I2CDevice::I2CDevice(HL_I2CMaster &HL, unsigned char busAddress, unsigned char slaveAddress)
{
	mHL = &HL;
	mHLAdd.LocalBusType       = BT_I2C;
	mHLAdd.LocalBusAddress    = busAddress;
	mHLAdd.LocalDeviceAddress = slaveAddress;
}


HL_I2CMaster::HL_I2CMaster(TL_base &TL)
{
	mTL = &TL;
}

void HL_I2CMaster::SetTLhandle(TL_base &TL)
{
	mTL = &TL;
}

HL_base::HL_base(TL_base &TL): HL_I2CMaster(TL)
{
}
