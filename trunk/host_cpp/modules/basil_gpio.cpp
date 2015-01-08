#include "basil_gpio.h"


basil_gpio::basil_gpio(HL_base *HL, string name, int address, int nBytes, bool isOutput, bool isTristate)
{
	mHL = HL;
	mAddr = address;
	mBytes = nBytes;
	UserName = name;
	mHLAdd.LocalBusType       = BT_FPGA;
	//mHLAdd.LocalBusAddress    = busAddress;
	mHLAdd.LocalAddress = address;
}


basil_gpio::~basil_gpio(void)
{
}

void basil_gpio::Set(int val)
{
	mHLAdd.LocalAddress = mAddr + GPIO_WRITE_ADD;
	mHL->Write(mHLAdd , (byte*) &val, mBytes);  
}

int  basil_gpio::Get()
{
	int val;
	mHLAdd.LocalAddress = mAddr + GPIO_READ_ADD;
	mHL->Read(mHLAdd, (byte*) &val, mBytes);  
	return val;
}

void basil_gpio::Reset()
{
	mHLAdd.LocalDeviceAddress = mAddr + GPIO_RESET_ADD;
	mHL->Write(mHLAdd, 0, mBytes);  
}

const char* basil_gpio::GetName(void)
{
	return UserName.c_str();
}
