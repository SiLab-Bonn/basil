#include "SiUSBLib.h"
#include "SiUSBDeviceManager.h"


TUSBDeviceManager *USBDevMan = NULL;

/*
 * Initiliaze the USB Subsystem and create the list of the available USB
 * devices.
 */
bool
InitUSB()
{
	if(USBDevMan != NULL) {
		return false;
	}
	USBDevMan = new TUSBDeviceManager();
	USBDevMan->HandleDeviceChange();
	return true;
}

TUSBDeviceManager *GetUSBDevMan()
{
	return USBDevMan;
}

int
GetNumberOfUSBBoards()
{
	return USBDevMan->GetNumberofDevices();
}

int
GetMaxNumberOfUSBBoards()
{
	return USBDevMan->GetMaxNumberofDevices();
}

void *
GetUSBDevice(int Id, int DevClass)
{
	if (DevClass == -1)
		return (SiUSBDevice*)(USBDevMan->GetDevice(Id));
	else
		return (void*)(USBDevMan->GetDevice(Id, DevClass));
}

void *
GetUSBDeviceIndexedNoDeviceManager(int index)
{
	TUSBDevice *dev;
	dev = new TUSBDevice (index);

	if (dev->StartDriver()) {
		return (void*)(dev);
	} else {
		return NULL;
	}
}

void *
GetUSBDeviceIndexed(int index)
{
	if (USBDevMan->DeviceList[index].DevicePresent) {
		return (void*)(USBDevMan->DeviceList[index].Device);
	} else {
		return NULL;
	}
}

std::stringstream
*GetDevInfoString(int index)
{
	return (USBDevMan->devInfoStrings[index]);
}

/*
 * message handling
 */
#if defined WIN32
bool
OnDeviceChange(void)
{
	return USBDevMan->HandleDeviceChange();
}
#else
bool __stdcall
OnDeviceChange(void)
{
	return USBDevMan->HandleDeviceChange();
}
bool __stdcall 
OnDeviceChange2()
{
	return USBDevMan->HandleDeviceChange();
}
#endif

/* Exported Functions */
SiUSBDevice::SiUSBDevice( void * USBdev){ dev = USBdev;}
SiUSBDevice::~SiUSBDevice(){;}
void SiUSBDevice::SetDeviceHandle(void * USBdev){dev = USBdev;};
bool SiUSBDevice::HandlePresent(){return (dev != NULL);};
int SiUSBDevice::GetId(){if (dev == NULL) return 0; return ((TUSBDevice *)(dev))->GetId();};
int SiUSBDevice::GetIndex(){if (dev == NULL) return 0; return ((TUSBDevice *)(dev))->GetIndex();};
const char* SiUSBDevice::GetName(){if (dev == NULL) return ""; return ((TUSBDevice *)(dev))->GetName();};
const char* SiUSBDevice::GetEndpointInfo(){if (dev == NULL) return ""; return ((TUSBDevice *)(dev))->GetEndpointInfo();};
bool SiUSBDevice::GetUserInformation(void){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->GetUserInformation();};
int SiUSBDevice::GetVendorId(){if (dev == NULL) return 0; return ((TUSBDevice *)(dev))->GetVendorId();};
int SiUSBDevice::GetDeviceId(){if (dev == NULL) return 0; return ((TUSBDevice *)(dev))->GetDeviceId();};
int SiUSBDevice::GetClass(){if (dev == NULL) return 0; return ((TUSBDevice *)(dev))->GetClass();};
int SiUSBDevice::GetFWVersion(){if (dev == NULL) return 0; return ((TUSBDevice *)(dev))->GetFWVersion();};
// access EEPROM programmable device parameters
//bool SiUSBDevice::ReadIDFromEEPROM(){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadIDFromEEPROM();};
bool SiUSBDevice::WriteIDToEEPROM(int id){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteIDToEEPROM( id);};
//bool SiUSBDevice::ReadNameFromEEPROM(){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadNameFromEEPROM();};
bool SiUSBDevice::WriteNameToEEPROM(const char *name){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteNameToEEPROM( name);};
//bool SiUSBDevice::ReadDeviceClassFromEEPROM(){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadDeviceClassFromEEPROM();};
bool SiUSBDevice::WriteDeviceClassToEEPROM(unsigned char dc){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteDeviceClassToEEPROM( dc);};
//bool SiUSBDevice::ReadFirmwareVersion(){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadFirmwareVersion();};
// access 8051 internal registers
bool SiUSBDevice::Write8051(unsigned short address, unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->Write8051(address, Data, length);};
bool SiUSBDevice::Read8051(unsigned short address, unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->Read8051(address, Data, length);};
bool SiUSBDevice::SetBit8051(unsigned short address, unsigned char  mask, bool   set){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->SetBit8051(address, mask, set);};
bool SiUSBDevice::GetBit8051(unsigned short address, unsigned char  mask, bool & get){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->GetBit8051(address, mask, get);};
// FPGA access
bool SiUSBDevice::WriteXilinx(unsigned short address, unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteXilinx(address, Data, length);};
bool SiUSBDevice::ReadXilinx(unsigned short address, unsigned char *Data, int length ){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadXilinx(address, Data, length );};
bool SiUSBDevice::WriteFPGA(unsigned short address, unsigned char *Data, int length){return WriteXilinx(address, Data, length);};
bool SiUSBDevice::ReadFPGA(unsigned short address, unsigned char *Data, int length ){return ReadXilinx(address, Data, length);};
// FPGA configuration
bool SiUSBDevice::DownloadXilinx(const char *fileName){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->DownloadXilinx(std::string(fileName));};
// UART
bool SiUSBDevice::WriteSerial(unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteSerial(Data, length);};
bool SiUSBDevice::ReadSerial(unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadSerial(Data, length);};
// generic access to external data bus
bool SiUSBDevice::WriteExternal(unsigned short address, unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteExternal(address, Data, length);};
bool SiUSBDevice::ReadExternal(unsigned short address, unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadExternal(address, Data, length);};
// access to fast data bus
bool SiUSBDevice::WriteBlock (unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->FastBlockWrite(Data, length);};
bool SiUSBDevice::ReadBlock  (unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->FastBlockRead(Data, length);};
// access to fast data bus with address (function overload)
bool SiUSBDevice::WriteBlock (long long address, unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->FastBlockWrite(address, Data, length);};
bool SiUSBDevice::ReadBlock  (long long address, unsigned char *Data, int length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->FastBlockRead(address, Data, length);};
// FIFO access (application specific)
//bool WriteFIFO     (unsigned char *Data, unsigned short Length);
unsigned short SiUSBDevice::ReadFIFO(unsigned char *Data, int Length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadFIFO(Data, Length);};
//unsigned short ReadFIFO2(unsigned char *Data, unsigned short Length);
// EEPROM access
bool SiUSBDevice::WriteEEPROM(unsigned short address, unsigned char *Data, unsigned short Length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteEEPROM(address, Data, Length);};
bool SiUSBDevice::ReadEEPROM(unsigned short address, unsigned char *Data, unsigned short Length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadEEPROM(address, Data, Length);};
// generic I2C access
bool SiUSBDevice::I2CAck(){return ((TUSBDevice *)(dev))->I2CAck ();};
bool SiUSBDevice::WriteI2C(unsigned char SlaveAdd, unsigned char *data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteI2C(SlaveAdd, data, length);};
bool SiUSBDevice::WriteI2Cnv(unsigned char SlaveAdd, unsigned char *data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteI2Cnv(SlaveAdd, data, length);};
bool SiUSBDevice::ReadI2C(unsigned char SlaveAdd, unsigned char *data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadI2C(SlaveAdd, data, length);};
// SPI access (application specific)
void SiUSBDevice::InitSPI(){if (dev == NULL) return; ((TUSBDevice *)(dev))->InitSPI();};
bool SiUSBDevice::WriteSPI(int add, unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteSPI(add, Data, length);};
bool SiUSBDevice::ReadSPI(int add, unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadSPI(add, Data, length);};
bool SiUSBDevice::ReadAdcSPI(unsigned char address, unsigned char *Data){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadAdcSPI(address, Data);};
// leagacy functions
bool SiUSBDevice::WriteLatch(unsigned char *Data){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteLatch(Data);};
bool SiUSBDevice::WriteCommand(unsigned char *Data, unsigned short length){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteCommand(Data, length);};
bool SiUSBDevice::ReadADC(unsigned char address, int *Data){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadADC(address, Data);};
// direct access to dedicated endpoints
bool SiUSBDevice::WriteRegister(unsigned char * Data){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->WriteRegister(Data);};
bool SiUSBDevice::ReadRegister(unsigned char * Data){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->ReadRegister(Data);};
// firmware download
bool SiUSBDevice::LoadFirmwareFromFile(const char * FileName){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->LoadFirmwareFromFile(std::string(FileName));};
bool SiUSBDevice::LoadHexFileToEeprom(const char * FileName){if (dev == NULL) return false; return ((TUSBDevice *)(dev))->LoadHexFileToEeprom(std::string(FileName));};
