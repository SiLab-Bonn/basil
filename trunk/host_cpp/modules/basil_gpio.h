#pragma once
#include "TL_USB.h"

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


class BASILDECLDIR basil_gpio 
{
public:
	basil_gpio(TL_USB *TL, string name, int address, int nBytes, bool isOutput, bool isTristate);
	~basil_gpio(void);
	void Set(int val);
	int  Get();
	void Reset();
	const char* GetName(void);

private:
	HL_addr mTLAdd;
	int mAddr;
	TL_USB *mTL;
	int mBytes;
	string UserName;
};

