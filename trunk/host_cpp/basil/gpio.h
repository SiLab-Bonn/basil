#pragma once
#include "HL_base.h"

#ifdef WIN32 
  #ifdef BASIL_DLL_EXPORT
    #define BASILDECLDIR __declspec(dllexport)
  #else
    #define BASILDECLDIR __declspec(dllimport)
  #endif
#endif

#define GPIO_RESET_ADD 0
#define GPIO_READ_ADD  1
#define GPIO_WRITE_ADD 2
#define GPIO_OUTEN_ADD 4


class BASILDECLDIR gpio 
{
public:
	gpio(HL_base &HL, int address, int nBytes, bool isOutput, bool isTristate);
	~gpio(void);
	void Set(int &val);
	int  Get();
	void Reset();

private:
	HL_addr mHLAdd;
	int mAddr;
	HL_base *mHL;
	int mBytes;
};

