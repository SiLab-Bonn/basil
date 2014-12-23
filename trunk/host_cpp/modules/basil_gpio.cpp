#include "basil_gpio.h"


basil_gpio::basil_gpio(TL_USB *TL, string name, int address, int nBytes, bool isOutput, bool isTristate)
{
	mTL = TL;
	mAddr = address;
	mBytes = nBytes;
	UserName = name;
	mTLAdd.LocalBusType       = BT_FPGA;
	//mHLAdd.LocalBusAddress    = busAddress;
	mTLAdd.LocalAddress = address;
}


basil_gpio::~basil_gpio(void)
{
}

void basil_gpio::Set(int val)
{
	mTLAdd.LocalAddress = mAddr + GPIO_WRITE_ADD;
	mTL->Write(mTLAdd.raw , (byte*) &val, mBytes);  
}

int  basil_gpio::Get()
{
	int val;
	mTLAdd.LocalAddress = mAddr + GPIO_READ_ADD;
	mTL->Read(mTLAdd.raw , (byte*) &val, mBytes);  
	return val;
}

void basil_gpio::Reset()
{
	mTLAdd.LocalDeviceAddress = mAddr + GPIO_RESET_ADD;
	mTL->Write(mTLAdd.raw , 0, mBytes);  
}

const char* basil_gpio::GetName(void)
{
	return UserName.c_str();
}
