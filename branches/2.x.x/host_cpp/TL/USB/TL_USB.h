#pragma once

#include "SiLibUSB.h"
#include "TL_base.h"

#ifdef WIN32
  #ifdef DLL_EXPORT
    #define DECLDIR __declspec(dllexport)
  #elif USE_STATIC_LIB
    #define DECLDIR
  #else
    #define DECLDIR __declspec(dllimport)
  #endif
#endif

class DECLDIR TL_USB: public TL_base
{
public:
	TL_USB(void);
	TL_USB(SiUSBDevice *mUSBdev);
	~TL_USB(void);

	SiUSBDevice *mUSB_device;

	int  TL_ListDevices(int *devAddList);
	bool TL_Open(int devAdd);
	bool TL_Close(int devAdd);
	bool TL_Write(__int64 add, unsigned char *data, int nBytes);
	bool TL_Read( __int64 add, unsigned char *data, int nBytes);
	bool TL_Read( __int64 add, unsigned char *data, int nBytes, int *nBytesReceived);  
	// Silab USB legacy functions
	const char * GetName(void){return mUSB_device->GetName();};
	int GetId(void){return mUSB_device->GetId();};
	bool DownloadXilinx(const char * fileName) {return mUSB_device->DownloadXilinx(fileName);};
protected:
};

// 

