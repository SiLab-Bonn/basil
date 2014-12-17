#include "TL_USB.h"

TL_USB::TL_USB(void):TL_base()
{
	InitUSB();  // start USB device manager
	mUSB_device = new SiUSBDevice(NULL);

	mTLAdd.raw = 0; // initialize 
	mTLAdd.InterfaceType = IF_USB;
	
  devAddList = new int[GetMaxNumberOfUSBBoards()]; // prepare device list
}

TL_USB::TL_USB(SiUSBDevice *mUSB):TL_base()
{
	mUSB_device = mUSB;

	mTLAdd.raw = 0; // initialize 
	mTLAdd.InterfaceType = IF_USB;
	
  devAddList = new int[GetMaxNumberOfUSBBoards()]; // prepare device list
}

TL_USB::~TL_USB(void)
{
	delete[] devAddList;
}

int TL_USB::TL_ListDevices(int *devAddList)
{
	SiUSBDevice USBdev(NULL);
	int devsFound = GetNumberOfUSBBoards();  // number of USB systems connected to the local host


	for (int i = 0; i < devsFound; i++)  // build device list: VID / PID / CLASS / INDEX
	{
    USBdev.SetDeviceHandle(GetUSBDeviceIndexed(i));
		devAddList[i] = (USBdev.GetVendorId() << 24) + (USBdev.GetDeviceId() << 16) + (USBdev.GetClass() << 8) + USBdev.GetIndex();
	}
	return devsFound;		
}

bool TL_USB::TL_Open(int devAdd)
{
	void * HANDLE = GetUSBDevice(devAdd);

	if (HANDLE != NULL)
	{
		mUSB_device->SetDeviceHandle(HANDLE);	
		mTLAdd.VendorID  = (unsigned short)mUSB_device->GetVendorId();
		mTLAdd.ProductID = (unsigned short)mUSB_device->GetDeviceId();
		mTLAdd.Class     = (unsigned char) mUSB_device->GetClass();
		mTLAdd.Index     = (unsigned char) mUSB_device->GetIndex();
  	return true;
	}
	else 
		return false;
}

bool TL_USB::TL_Close(int devAdd)
{
		mTLAdd.VendorID  = 0;
		mTLAdd.ProductID = 0;
		mTLAdd.Class     = 0;
		mTLAdd.Index     = 0;
	return true;
}

bool TL_USB::TL_Write(__int64 add, unsigned char *data, int nBytes)
{
	bool status = false; 
	HL_addr *HL_addr_ptr = (HL_addr*)(&add);
	unsigned char LocalBusType       = HL_addr_ptr->LocalBusType;
	unsigned char LocalDeviceAddress = HL_addr_ptr->LocalDeviceAddress;
	unsigned int LocalAddress       = HL_addr_ptr->LocalAddress;
	
	switch (LocalBusType)
	{
	  case (BT_FPGA)       : status = mUSB_device->WriteXilinx((unsigned short)LocalAddress, data, nBytes); break;
	  case (BT_FPGA_BLOCK) : status = mUSB_device->WriteBlock(data, nBytes); break;
	  case (BT_I2C)        : status = mUSB_device->WriteI2C((unsigned char)LocalDeviceAddress, data, nBytes); break;
	  case (BT_SPI)        : status = mUSB_device->WriteSPI((unsigned int)LocalDeviceAddress, data, nBytes); break;
	}  

	return status;
}

bool TL_USB::TL_Read(__int64 add, unsigned char *data, int nBytes)
{
	bool status = false; 
	HL_addr *HL_addr_ptr = (HL_addr*)(&add);
	unsigned char LocalBusType       = HL_addr_ptr->LocalBusType;
	unsigned char LocalDeviceAddress = HL_addr_ptr->LocalDeviceAddress;
	unsigned int LocalAddress       = HL_addr_ptr->LocalAddress;
	
	switch (LocalBusType)
	{
	  case (BT_FPGA)       : status = mUSB_device->ReadXilinx((unsigned short)LocalAddress, data, nBytes); break;
	  case (BT_FPGA_BLOCK) : status = mUSB_device->ReadBlock(data, nBytes); break;
	  case (BT_I2C)        : status = mUSB_device->ReadI2C((unsigned char)LocalDeviceAddress | I2C_SLAVE_ADD_READ_BIT, data, nBytes); break;
	  case (BT_SPI)        : status = mUSB_device->ReadSPI((unsigned short)LocalDeviceAddress, data, nBytes); break;
	}  

	return status;
}

bool TL_USB::TL_Read(__int64 add, unsigned char *data, int nBytes, int *nBytesReceived)  // not implemeted yet
{
	return TL_Read(add, data, nBytes);
}