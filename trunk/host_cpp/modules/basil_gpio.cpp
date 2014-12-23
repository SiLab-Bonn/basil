#include "basil_gpio.h"


basil_gpio::basil_gpio(HL_base &HL, int address, int nBytes, bool isOutput, bool isTristate)
{
	mHL = &HL;
	mAddr = address;
	mBytes = nBytes;
	mHLAdd.LocalBusType       = BT_FPGA;
	//mHLAdd.LocalBusAddress    = busAddress;
	mHLAdd.LocalDeviceAddress = address;
}


basil_gpio::~basil_gpio(void)
{
}

void basil_gpio::Set(int &val)
{
	mHLAdd.LocalDeviceAddress = mAddr + GPIO_WRITE_ADD;
	mHL->Write(mHLAdd , (byte*) val, mBytes);  
}

int  basil_gpio::Get()
{
	int val;
	mHLAdd.LocalDeviceAddress = mAddr + GPIO_READ_ADD;
	mHL->Read(mHLAdd , (byte*) &val, mBytes);  
	return val;
}

void basil_gpio::Reset()
{
	mHLAdd.LocalDeviceAddress = mAddr + GPIO_RESET_ADD;
	mHL->Write(mHLAdd , 0, mBytes);  
}