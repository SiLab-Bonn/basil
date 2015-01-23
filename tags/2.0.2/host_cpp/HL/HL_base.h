#pragma once

#include "TL_base.h"

#ifdef WIN32 
  #ifdef GPAC_DLL_EXPORT
    #define PIXDECLDIR __declspec(dllexport)
  #else
    #define PIXDECLDIR __declspec(dllimport)
  #endif
#endif


class HL_base
{
public:
	HL_base(TL_base &TL);	
	virtual bool Write(HL_addr &hAdd, unsigned char *data, int nBytes) = 0;
	virtual bool  Read(HL_addr &hAdd, unsigned char *data, int nBytes) = 0;
	void SetTLhandle(TL_base &TL);

protected:
	int mID;
	TL_base *mTL;
};

class I2CDevice
{
public:
	I2CDevice::I2CDevice(HL_base &HL, unsigned char busAddress, unsigned char slaveAddress);
	HL_addr mHLAdd;
protected:
	HL_base *mHL;
};