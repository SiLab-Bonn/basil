//------------------------------------------------------------------------------
//       USBDeviceManager.h
//
//       SILAB, Phys. Inst Bonn, HK
//
//  Handle multiple USB devices associated to slbusb.sys device driver
//
//  History:
//  31.01.03   BLUETRAK version!!!
//  03.10.01  HK  created
//  22.02.02  PF  see .cpp file
//------------------------------------------------------------------------------


#ifndef USBDeviceManagerH
#define USBDeviceManagerH

#ifdef WIN32
  #include <Windows.h>
  #include <setupapi.h>
#endif

#include <sstream>
#include <stdlib.h>
#include <vector>
#include <iostream>
#include <strsafe.h>

#include "myutils.h"
#include "SiUSBDevice.h"

const int MAX_USB_DEV_NUMBER = 16;         // number of devices

// SILAB USB device interface class, supported by winusb.sys
// {CF2531EE-7B75-4b3a-B20D-2F5E2925E729}
static const GUID GUID_DEVINTERFACE_SILAB_USB_DEVICE = 
{ 0xcf2531ee, 0x7b75, 0x4b3a, { 0xb2, 0xd, 0x2f, 0x5e, 0x29, 0x25, 0xe7, 0x29 } };

static const GUID GUID_DEVINTERFACE_USB_DEVICE = 
{ 0xA5DCBF10, 0x6530, 0x11D2, {0x90, 0x1F, 0x00, 0xC0, 0x4F, 0xB9, 0x51, 0xED} };

BOOL EnumerateDevices(GUID guidDeviceInterface, PHANDLE hDeviceHandle);
//void printdev(libusb_device *dev); //prototype of the list function 


typedef struct  _SLB_USB_DEVICE_TYPE       // Used in constant array 'DeviceTypeList'
{
	unsigned short                    VendorID;
	unsigned short                    ProductID;
	//	SLB_USB_DEVICE_TYPE_NAME  DeviceTypeName;
	char                    * FirmwareFilename;
} SLB_USB_DEVICE_TYPE;

typedef struct _USB_DEVICE_LIST_ITEM
{
	bool                      DevicePresent;
	TUSBDevice              * Device;
	std::string               DevicePathName;
	//SLB_USB_DEVICE_TYPE_NAME  DeviceTypeName;
} USB_DEVICE_LIST_ITEM;

class TUSBDevice;
class TUSBDeviceManager
{
public:
	TUSBDeviceManager();
	~TUSBDeviceManager();
	bool HandleDeviceChange(void);
	bool WinUsb_HandleDeviceChange(void);
	int  DevToIndex(TUSBDevice *dev);
	int  DevToId(TUSBDevice *dev);
	bool IsBusy();
	int GetNumberofDevices();
	int GetMaxNumberofDevices();
	void ForceRefresh();
	void SetAddCallBack(void (*addfunc) (TUSBDevice*, void*), void *cnt);
	void SetRemoveCallBack(void (*remfunc) (TUSBDevice*, void*), void *cnt);
	void* GetDevice(int id = -1);
	void* GetDevice(int id, int DevClass);
	USB_DEVICE_LIST_ITEM DeviceList[MAX_USB_DEV_NUMBER];
	std::vector <std::stringstream*> devInfoStrings;

private:
	bool PurgeDeviceList(void);
	int  GetFreeDeviceListIndex(void);
	bool AddDeviceToList      (int index);
	bool RemoveDeviceFromList (int index);
	int  UpdateDevStringList ();
	bool busy;
	void * DeviceContext;
	void (* onDevicePlugged) (TUSBDevice* dev, void *ptr);
	void (* onDeviceUnplugged) (TUSBDevice* dev, void *ptr);
};

#endif
