/*
 *       USBDevice.cpp
 *
 *       SILAB, Phys. Inst Bonn, HK
 *
 *  USB devices associated to winusb.sys device driver
 *
 *  History:
 *  10.10.12  WinUSB (32/64 bit) support, replacing slbusbXP.sys
 *            clean-up
 *  04.03.02  added generic I2C functions
 *  03.10.01  modifiedadded init functions (StartDriver, StopDriver)
 *            for TUSBDeviceManager
 *  31.08.01  added latch and adc access for mqube tracker
 */

#ifdef WIN32
#include <Windows.h>
#endif
#include <sstream>
//#include <algorithm> //!!!!!!!!!!!!!!!

#include "SURConstants.h"
#include "SiUSBDevice.h"
#include "SiI2CDevice.h"

using namespace std;

const char PIPE_TYPE_STRINGS[4][5] = {
	"CTRL",
	"ISO",
	"BULK",
	"INT"
};

const char PIPE_DIRECTION[2][4] = {
	"OUT",
	"IN"
};

int HexToInt2(std::string hString) {
	int val;

	val = strtol(hString.c_str(),(char **)NULL,16);

	return val;
}

void SwapBytes(unsigned char *data, int size) {
	unsigned char temp;

	for (int i = 0; i < size; i++) {
		temp = 0;

		for (unsigned char j = 0; j < 8; j++) {
			temp |= (unsigned char)(((data[i] & (0x01 << j)) >>  j) << (7 - j));
		}

		data[i] = temp;
	}
}

TUSBDevice::TUSBDevice(int index):TI2CMaster(), TSPIMaster(), TXilinxChip(true)
{
	USBDeviceHandle = INVALID_HANDLE_VALUE;        // handle to the driver
	DeviceDriverIndex = index;
	started    = false;
	configured = false;            // firmware active

	INIT_MUTEX;
}

TUSBDevice::~TUSBDevice()
{
	if (started)
	  StopDriver();
	FREE_MUTEX;
}


bool TUSBDevice::StartDriver()
{
#ifdef _LIBUSB_
	//	if (libusb_open(dev_handle, &USBDeviceHandle)) {
	if (libusb_open(NULL, &USBDeviceHandle)) {
		perror("Error: libusb_open");

		return false;
	}

	/* Claim interface 0 */
	if (libusb_claim_interface(USBDeviceHandle, 0)) {
		perror("Error: libusb_claim");

		return false;
	}
#else
	USBDeviceHandle = CreateFile(
		    DevicePathName.c_str(),
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        FILE_FLAG_OVERLAPPED,
        NULL);

	if (USBDeviceHandle == INVALID_HANDLE_VALUE)
	{
		CloseHandle(USBDeviceHandle);
  	DebugOutLastError("TUSBDevice::StartDriver: CreateFile failed");
		return false;
	}  
	
	if (!WinUsb_Initialize(USBDeviceHandle, &WinUSBInterfaceHandle))
	{
		DBGOUT("TUSBDevice::StartDriver(): WinUsb_Initialize failed");
   	return false;
	}
  
#endif
  Init();
	started = true;
	return true;
}

bool TUSBDevice::StopDriver()
{
	if(started) 
	{
		if (USBDeviceHandle == INVALID_HANDLE_VALUE) 
		{
			return false;
		} 
		else 
		{
#ifdef _LIBUSB_
			libusb_close(USBDeviceHandle); 
#else
      WinUsb_Free(WinUSBInterfaceHandle);
			//CloseHandle(USBDeviceHandle); // ???
#endif
		}
		return true;
	} 
	else 
		return false;
}


bool TUSBDevice::DeviceAvailable(void)
{
	UCHAR buffer;
	ULONG nBytes = 1;

	// test if the handle is still valid, i.e. the device responds, could be any access to the control EP
  if (!WinUsb_QueryDeviceInformation(WinUSBInterfaceHandle, DEVICE_SPEED, &nBytes, &buffer))  
	{
  	DebugOutLastError("TUSBDevice::DeviceAvailable");
	  return false;
	}
	else
    return true;
}

void TUSBDevice::Init()
{
	/* Get the device descriptor */
	if (!GetDeviceInformation()) {
		OutputDebugString("TUSBDevice::Init() error\n");
		return;
	}
	
	// If we got a FX3 device
	if ((ProductId >= 0x0300) && (ProductId < 0x0400))  {
		sur_control_pipe  = SUR_CONTROL_PIPE_FX;
		sur_data_out_pipe = SUR_DATA_OUT_PIPE_FX;
		sur_data_in_pipe  = SUR_DATA_IN_PIPE_FX;
		cpu_cs_reg        = CPUCS_REG_FX;
		eeprom_user_data_offset = EEPROM_USER_DATA_OFFSET_FX3;
		eeprom_mfg_addr  = EEPROM_MFG_ADDR_FX;
		eeprom_name_addr = EEPROM_NAME_ADDR_FX;
		eeprom_id_addr   = EEPROM_ID_ADDR_FX;
		eeprom_liac_addr = EEPROM_LIAC_ADDR_FX;
		xp_conf_port_cfg = PORTACFG_FX;
		xp_conf_port_oe  = OEA_FX;
		xp_conf_port_rd  = IOA_FX;
		xp_conf_port_wr  = IOA_FX;
		ControllerType = FX3;
	} 
	// If we got a FX2LP device
	if ((ProductId >= 0x0200) || (ProductId == 0x8613)) {
		sur_control_pipe  = SUR_CONTROL_PIPE_FX;
		sur_data_out_pipe = SUR_DATA_OUT_PIPE_FX;
		sur_data_in_pipe  = SUR_DATA_IN_PIPE_FX;
		cpu_cs_reg        = CPUCS_REG_FX;
		eeprom_user_data_offset = EEPROM_USER_DATA_OFFSET_FX;
		eeprom_mfg_addr  = EEPROM_MFG_ADDR_FX;
		eeprom_name_addr = EEPROM_NAME_ADDR_FX;
		eeprom_id_addr   = EEPROM_ID_ADDR_FX;
		eeprom_liac_addr = EEPROM_LIAC_ADDR_FX;
		xp_conf_port_cfg = PORTACFG_FX;
		xp_conf_port_oe  = OEA_FX;
		xp_conf_port_rd  = IOA_FX;
		xp_conf_port_wr  = IOA_FX;
		ControllerType = FX2;
	} 
	else 	
	{
		sur_control_pipe  = SUR_CONTROL_PIPE;
		sur_data_out_pipe = SUR_DATA_OUT_PIPE;
		sur_data_in_pipe  = SUR_DATA_IN_PIPE;
		cpu_cs_reg        = CPUCS_REG;
		eeprom_user_data_offset = EEPROM_USER_DATA_OFFSET;
		eeprom_mfg_addr  = EEPROM_MFG_ADDR;
		eeprom_name_addr = EEPROM_NAME_ADDR;
		eeprom_id_addr   = EEPROM_ID_ADDR;
		eeprom_liac_addr = EEPROM_LIAC_ADDR;
		xp_conf_port_cfg = PORTCCFG;
		xp_conf_port_oe  = OEC;
		xp_conf_port_rd  = PINSC;
		xp_conf_port_wr  = OUTC;
		ControllerType = FX;
	}

	if(iPipes != 0) // (some) firmware is available
	{
		configured = true;
		GetUserInformation();
	} 
	else 
	{
		Name = "not configured";
		Id    = 0;
		FwVer = 0;
		DeviceClass = 0;
	}
}

bool TUSBDevice::GetUserInformation()
{
	if (!configured) // only avaliable with firmware being active
		return false;

	ReadIDFromEEPROM();
	ReadNameFromEEPROM();
	ReadDeviceClassFromEEPROM();
	ReadFirmwareVersion();
	return true;
}

/*
 * Find specified vendor and product ID. It only supports the current Spartan 3 models.
 */
/*
bool TUSBDevice::finddev(libusb_device *dev)
{
        libusb_device_descriptor dev_desc;

				if (libusb_get_device_descriptor(dev, &dev_desc) < 0) {
                perror("Error: usb_get_device_descriptor");
                return false;
        }

        if (dev_desc.idVendor == 0x04b4 && dev_desc.idProduct == 0x8613) {
                return true;
        }

        return false;
}
*/
bool TUSBDevice::ReadIDFromEEPROM()
{
	EEPROM_ID_STRUCT idstr;
	void *ptr;
	std::string str;
	ptr = &idstr;
	if (!ReadEEPROM(eeprom_id_addr, (unsigned char*)ptr, EEPROM_ID_SIZE)) 
	{
		DebugOutLastError("TUSBDevice::ReadIDFromEEPROM");
		Id = 0;
		return false;
	}
	Id = atoi(idstr.content);
	return true;
}

bool TUSBDevice::ReadNameFromEEPROM()
{
	EEPROM_NAME_STRUCT namestr;
	void *ptr;
	std::string str;
	ptr = &namestr;

	if (!ReadEEPROM(eeprom_name_addr, (unsigned char*)ptr, EEPROM_NAME_SIZE))
	{
		Name = "unknown";
		DebugOutLastError("TUSBDevice::ReadNameFromEEPROM");
		return false;
	}
	str = namestr.content;
	Name.assign(str,0,namestr.length);
	return true;
}
bool TUSBDevice::ReadDeviceClassFromEEPROM()
{
	if (!ReadEEPROM(eeprom_liac_addr, &DeviceClass, EEPROM_LIAC_SIZE)) 
	{
		DeviceClass = 0;
		DebugOutLastError("TUSBDevice::ReadDeviceClassFromEEPROM");
		return false;
	}
	return true;
}

bool TUSBDevice::ReadFirmwareVersion()
{
	SILAB_USB_REQUEST sur;
	bool status;
	unsigned char Data[3];

	sur.type   = SUR_TYPE_FWVER;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = 0;
	sur.length = 2;

	status = SilabUsbRequest(&sur, Data);
	Data[2] = '\0';

	if (status) 
	{
		FwVer = atoi((char*)Data);
		return true;
	} 
	else 
	{
		DebugOutLastError("TUSBDevice::ReadFirmewareVersion");
		FwVer = 0;
		return false;
	}

}

bool TUSBDevice::WriteIDToEEPROM(int id)
{
	EEPROM_ID_STRUCT idstr;
	void *ptr;

	sprintf(idstr.content, "%d", id);
	idstr.length = min(strlen(idstr.content), (unsigned int)EEPROM_ID_SIZE-1);
	ptr = &idstr;
	if(!WriteEEPROM(eeprom_id_addr, (unsigned char*)ptr, (unsigned int)EEPROM_ID_SIZE))
	{
		DebugOutLastError("TUSBDevice::WriteIDToEEPROM");
		return false;
	}
	return true;
}

bool TUSBDevice::WriteNameToEEPROM(const char* Name)
{
	EEPROM_NAME_STRUCT namestr;
	void *ptr;
	std::string newName(Name);

	strcpy(namestr.content, newName.c_str());
	namestr.length  = min(newName.length(), EEPROM_NAME_SIZE-1);
	ptr = &namestr;
	
	if (!WriteEEPROM(eeprom_name_addr, (unsigned char*)ptr, EEPROM_NAME_SIZE)) 
	{
		DebugOutLastError("TUSBDevice::WriteNameToEEPROM");
		return false;
	}
	return true;
}

bool TUSBDevice::WriteDeviceClassToEEPROM(unsigned char dc)
{
	if (!WriteEEPROM(eeprom_liac_addr, &dc, (unsigned int)EEPROM_LIAC_SIZE)) 
	{
		DebugOutLastError("TUSBDevice::WriteDeviceClassToEEPROM");
		return false;
	}
	return true;
}


bool TUSBDevice::GetDeviceInformation()
{
	return WinUsb_GetDeviceInformation();
}

bool TUSBDevice::LibUsb_GetDeviceInformation()
{
	/*
	int result;

	// Get some memory, plus some guardband area 
	if ((pvDescriptorBuffer = malloc(sizeof (Usb_Device_Descriptor) + 128)) == NULL)
	{
		return false;
	}

	if (USBDeviceHandle != NULL) {
		result = libusb_get_device_descriptor(libusb_get_device(USBDeviceHandle),
				(struct libusb_device_descriptor *) pvDescriptorBuffer);
		if (!result) {
			Desc = (Usb_Device_Descriptor*) pvDescriptorBuffer;
			return true;
		}

		return false;
	}
	*/
	return false;

}
bool TUSBDevice::WinUsb_GetDeviceInformation()
{
	BOOL result;
	std::stringstream PipeInfoStringStream;
	unsigned long nBytes;
	int iConfigurations;
	int iInterfaces;
	std::stringstream buf;

	if (USBDeviceHandle == NULL)
		return false;
  
	PipeInfoStringStream.str() = "";
	//device descriptor (VID, PID, class ...)
	result = WinUsb_GetDescriptor (
	WinUSBInterfaceHandle,
	USB_DEVICE_DESCRIPTOR_TYPE, //URB_FUNCTION_GET_DESCRIPTOR_FROM_DEVICE,
	0,
	0x0409,
	(PUCHAR)&DeviceDescriptor,
	sizeof (DeviceDescriptor),
	&nBytes);

	if (!result)
	{
		DebugOutLastError("TUSBDevice::WinUsb_GetDeviceInformation(), USB_DEVICE_DESCRIPTOR_TYPE");
  	return false;
	}

	VendorId  = DeviceDescriptor.idVendor;
	ProductId = DeviceDescriptor.idProduct;
	PipeInfoStringStream << "VID 0x" << hex << setfill ('0') << setw (4) << VendorId;
	PipeInfoStringStream << "/PID 0x" << hex << setfill ('0') << setw (4) << ProductId << endl;

	iConfigurations = DeviceDescriptor.bNumConfigurations;
	DBGOUT("# Configurations: " << (int)iConfigurations << endl);

	if (iConfigurations == 0)
	{
	  DebugOutLastError("TUSBDevice::WinUsb_GetDeviceInformation(), DeviceDescriptor.bNumConfigurations == 0");
 	  return false;
	}

  for (int i = 0; i < iConfigurations; i++)
	{
	  DBGOUT("Select configuration: " << i << endl);
    PipeInfoStringStream << "Configuration " << i;
    ConfigurationDescriptor.iConfiguration = 0;
		
		//configuration descriptor (# interfaces, power consumption ...)
		if (!WinUsb_GetDescriptor (
		WinUSBInterfaceHandle,
		USB_CONFIGURATION_DESCRIPTOR_TYPE, //URB_FUNCTION_GET_DESCRIPTOR_FROM_DEVICE,
		0,
		0x0409,
		(PUCHAR)&ConfigurationDescriptor,
		sizeof (ConfigurationDescriptor),
		&nBytes))
		{
			DebugOutLastError("TUSBDevice::WinUsb_GetDeviceInformation(), USB_CONFIGURATION_DESCRIPTOR_TYPE");
  		return false;
		}

    iInterfaces = ConfigurationDescriptor.bNumInterfaces;

	  DBGOUT("# Interfaces: " <<  iInterfaces << endl);
  	 
		for (int j = 0; j < iInterfaces; j++)
		{
	    DBGOUT("Select interface: " << j << endl);
      PipeInfoStringStream << ", Interface " << j << endl;
			// interface descriptor (# endpoints, endpoint configuration ...)
			if (!WinUsb_QueryInterfaceSettings (WinUSBInterfaceHandle, j, &InterfaceDescriptor))
			{
			  DebugOutLastError("TUSBDevice::WinUsb_QueryInterfaceSettings()");
			  return false;
			}

			iPipes = InterfaceDescriptor.bNumEndpoints;
	    DBGOUT("# Pipes: " << iPipes << endl);

		  for (int k = 0; k < iPipes; k++)
			{
				// endpoint (size, direction ...))
				if (!WinUsb_QueryPipe(WinUSBInterfaceHandle, 0, k, &PipeInformation))
				{
					DebugOutLastError("TUSBDevice::WinUsb_QueryPipe()");
  				return false;
				}
				ULONG MaxTransferSize;
				if (!WinUsb_GetPipePolicy (WinUSBInterfaceHandle, 
					   PipeInformation.PipeId, 
						 MAXIMUM_TRANSFER_SIZE, 
						 &nBytes,
						 &MaxTransferSize))
				{
					DebugOutLastError("TUSBDevice::WinUsb_GetPipePolicy()");
  				return false;
				}
				pPipe[k].EndpointAddress   = PipeInformation.PipeId;
				pPipe[k].PipeType          = PipeInformation.PipeType;
				pPipe[k].MaximumPacketSize = PipeInformation.MaximumPacketSize;
				pPipe[k].MaximumTransferSize = MaxTransferSize;
				PipeInfoStringStream << "Pipe " << k << ", ";
				PipeInfoStringStream << "Endpoint " << (int) (0x7f & pPipe[k].EndpointAddress) << ", ";
				PipeInfoStringStream << PIPE_TYPE_STRINGS[pPipe[k].PipeType] << " ";
				PipeInfoStringStream << PIPE_DIRECTION[pPipe[k].EndpointAddress >> 7] << ", ";
				PipeInfoStringStream << "PacketSize " << dec << (int) (pPipe[k].MaximumPacketSize) << " ";
				PipeInfoStringStream << "TransferSize " << dec << (int) (pPipe[k].MaximumTransferSize) << endl;
				DBGOUT("Pipe " << k << ": " << endl);
				DBGOUT("  address: 0x" << hex << setfill ('0') << setw (2) << (int)PipeInformation.PipeId << endl);
				DBGOUT("  type: " << PipeInformation.PipeType << endl);
				DBGOUT("  max. packet size: " << dec << (int)(PipeInformation.MaximumPacketSize) << endl);
			} // pipes
		} // intefaces
	} // configurations
	PipeInfoString = PipeInfoStringStream.str();
 	return true;
}



bool TUSBDevice::WriteBulkEndpoint(int nPipe, unsigned char *outData, int outPacketSize)
{
	ULONG nBytes;

	if (WinUsb_WritePipe(
		           WinUSBInterfaceHandle,
							 pPipe[nPipe].EndpointAddress,
							 outData,
	             outPacketSize,
							 &nBytes,
							 NULL))
		return true;
	else
	{
		DebugOutLastError("TUSBDevice::WriteBulkEndpoint");
		return false;
	}
}

bool TUSBDevice::ReadBulkEndpoint(int nPipe, unsigned char *inData, int inPacketSize, int *nBytesRead)
{
	unsigned long nBytes;

	if (WinUsb_ReadPipe(
		           WinUSBInterfaceHandle,
							 pPipe[nPipe].EndpointAddress,
							 inData,
	             inPacketSize,
							 &nBytes,
							 NULL))
	{
	  *nBytesRead = (int) nBytes;
		return true;
	}
	else
	{
		DebugOutLastError("TUSBDevice::ReadBulkEndpoint");
		return false;
	}
}

bool TUSBDevice::VendorRequest(WINUSB_SETUP_PACKET MyRequest, unsigned char *data)
{
	ULONG nBytes;

	if (WinUsb_ControlTransfer(
		           WinUSBInterfaceHandle,
							 MyRequest,
							 data,
	             MyRequest.Length,
							 &nBytes,
							 NULL))
		return true;
	else
	{
		DebugOutLastError("TUSBDevice::VendorRequest");
		return false;
	}
}

bool TUSBDevice::SilabUsbRequest(PSILAB_USB_REQUEST psur, unsigned char* data, int biglength)
{
	bool status;
	int dataleft;
	int dataptr;

	if ((biglength == 0) || (biglength <= MAX_SUR_DATA_SIZE)) {
		return SilabUsbRequest(psur, data);
	} else {
		dataleft = biglength;
		dataptr  = 0;

		/* Transfer 64k blocks */
		do {
			psur->length = MAX_SUR_DATA_SIZE;
			status = SilabUsbRequest(psur,(unsigned char*)(data + dataptr));
			if (!status)
				return false;
			dataleft -= MAX_SUR_DATA_SIZE;
			dataptr  += MAX_SUR_DATA_SIZE;
		} while (dataleft >= MAX_SUR_DATA_SIZE);

		psur->length = dataleft;
		status = SilabUsbRequest(psur, (unsigned char*)(data + dataptr));
	}

	return status;
}

bool TUSBDevice::SilabUsbRequest(PSILAB_USB_REQUEST psur, unsigned char* data)
{
	unsigned short ptr = 0; // data offset in current transfer
	int blocksize; // data size in current transfer
	unsigned long dataleft; // requested data size
	int nBytes;
	bool status;
	unsigned char buffer[10];
	int buffersize;

	buffer[0] = psur->type;
	buffer[1] = psur->dir;
	
	if ((ControllerType == FX2) || (ControllerType == FX3)) {
		buffer[2] = (unsigned char)(0xff &  psur->addr);
		buffer[3] = (unsigned char)(0xff & (psur->addr >> 8));
		buffer[4] = (unsigned char)(0xff & (psur->addr >> 16));
		buffer[5] = (unsigned char)(0xff & (psur->addr >> 24));
		buffer[6] = (unsigned char)(0xff &  psur->length);
		buffer[7] = (unsigned char)(0xff & (psur->length >> 8));
		buffer[8] = (unsigned char)(0xff & (psur->length >> 16));
		buffer[9] = (unsigned char)(0xff & (psur->length >> 24));
		buffersize = 10;
	} else {
		buffer[2] = (unsigned char)(0xff &  psur->addr);
		buffer[3] = (unsigned char)(0xff & (psur->addr >> 8));
		buffer[4] = (unsigned char)(0xff &  psur->length);
		buffer[5] = (unsigned char)(0xff & (psur->length >> 8));
		buffersize = 6;
	}

	GET_MUTEX;
	status = WriteBulkEndpoint(sur_control_pipe, buffer, buffersize);

	if (!status) 
	{
		DebugOutLastError("TUSBDevice::SilabUsbRequest(setup phase)");
		return false;
	}

	dataleft = psur->length;

 	while (dataleft > 0) 
	{
		if (psur->dir == SUR_DIR_OUT) 
		{
      blocksize = min(dataleft, pPipe[sur_data_out_pipe].MaximumTransferSize);
			status &= WriteBulkEndpoint(sur_data_out_pipe, (unsigned char *) (data + ptr), blocksize);
		} 
		else 
		{
      blocksize = min(dataleft, pPipe[sur_data_in_pipe].MaximumTransferSize);
			status &= ReadBulkEndpoint(sur_data_in_pipe, (unsigned char *) (data + ptr), blocksize, &nBytes);
		}
  	ptr += blocksize;	
		dataleft -= blocksize;  
	}

	RELEASE_MUTEX;

	if (status && (dataleft == 0)) 
	{
		return true;
	} 
	else 
	{
		DebugOutLastError("TUSBDevice::SilabUsbRequest(data phase)");
		return false;
	}

}

bool TUSBDevice::WriteRegister(unsigned char * Data)
{
	bool status;

	/* minimum length of data array is 4 */
	status = WriteBulkEndpoint(SUR_DIRECT_OUT_PIPE, Data, 4);

	if (!status) {
		return false;
	}
	return true;
}

bool TUSBDevice::ReadRegister(unsigned char * Data)
{
	int nBytes;
	bool status;

	/* minimum length of data array is 4 */
	status = ReadBulkEndpoint(SUR_DIRECT_IN_PIPE, Data, 4, &nBytes);

	if (!status) {
		return false;
	}
	return true;
}

bool TUSBDevice::FastByteWrite(unsigned char *data)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_GPIFBYTE;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = 0;
	sur.length = 1;

	GET_MUTEX;
	/* send setup data to bulk endpoint 1 to initialize data transfer */
	status  = WriteBulkEndpoint(sur_control_pipe, (unsigned char *)&sur, 10);
	status &= WriteBulkEndpoint(sur_data_out_pipe, data, 1);
  RELEASE_MUTEX;
	
	if (!status) 
	{
		DebugOutLastError("TUSBDevice::SilabUsbRequest(setup phase)");
		return false;
	}
	return true;
}

bool TUSBDevice::FastByteRead(unsigned char *data)
{
	SILAB_USB_REQUEST sur;
	int nBytesRead;
	bool status;

	sur.type   = SUR_TYPE_GPIFBYTE;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = 0;
	sur.length = 1;

	GET_MUTEX;
	/* send setup data to bulk endpoint 1 to initialize data transfer */
	status  = WriteBulkEndpoint(sur_control_pipe, (unsigned char *)&sur, 10);
	status &= ReadBulkEndpoint(sur_data_in_pipe, data, 1, &nBytesRead);
  RELEASE_MUTEX;

	if (status) 
	{
		return true;
	} 
	else 
	{
		DebugOutLastError("TUSBDevice::FastBytewrite");
		return false;
	}
}

bool TUSBDevice::FastBlockWrite(unsigned char *data, int length)
{
	int addr = 0;
	unsigned char buffer[10];
	unsigned char buffersize = 10;
	int ptr = 0;
	int blocksize;          /* data size in current transfer */
	int nPad_bytes;
	int padded_length;
	byte *padded_buffer;
	byte *data_buffer;
	//int prev_blocksize; //!!!!!!!!!!!!!!!!!
	unsigned long dataleft;  /* initial requested data size */
	bool status = true;

	nPad_bytes = -length & 3;  // number of padding bytes
	padded_length = length + nPad_bytes; 

	if ((ControllerType == FX3) && (nPad_bytes != 0))  // do padding for FX3 32-bit word access
	{
		padded_buffer = new byte [padded_length];
 		memcpy(padded_buffer, data, length);
		data_buffer = padded_buffer;
	}
	else 
		data_buffer = data;

	/* send setup data to bulk endpoint 0 to initialize data transfer */
	buffer[0] = SUR_TYPE_GPIFBLOCK;
	buffer[1] = SUR_DIR_OUT;
	buffer[2] = (unsigned char)(0xff & addr);
	buffer[3] = (unsigned char)(0xff & (addr >> 8));
	buffer[4] = (unsigned char)(0xff & (addr >> 16));
	buffer[5] = (unsigned char)(0xff & (addr >> 24));
	buffer[6] = (unsigned char)(0xff &  length);
	buffer[7] = (unsigned char)(0xff & (length >> 8));
	buffer[8] = (unsigned char)(0xff & (length >> 16));
	buffer[9] = (unsigned char)(0xff & (length >> 24));

	GET_MUTEX;
	if (!WriteBulkEndpoint(sur_control_pipe, buffer, buffersize))
  {
		DebugOutLastError("TUSBDevice::FastBlockWrite(setup phase)");
		return false;
	}
	
	dataleft = padded_length;
	while (dataleft > 0) 
	{
		blocksize = min(dataleft, pPipe[SUR_DATA_FASTOUT_PIPE].MaximumTransferSize);
		status &= WriteBulkEndpoint(SUR_DATA_FASTOUT_PIPE, (unsigned char *) (data_buffer + ptr), blocksize);
		ptr      += blocksize; /* increment data pointer for next transfer */
		dataleft -= blocksize; /* remaining data fraction */
	}
  RELEASE_MUTEX;

	if (padded_buffer != NULL)
		delete[] padded_buffer;

	if (status && (dataleft == 0)) {
		return true;
	} else {
		DebugOutLastError("TUSBDevice::FastBlockwrite");

		return false;
	}
}

bool TUSBDevice::FastBlockWrite(long long Baddress, unsigned char *data, int length) // overloaded
{
	long long addr = Baddress;
	unsigned char buffer[10];
	unsigned char buffersize = 10;
	int ptr = 0;
	int blocksize;          /* data size in current transfer */
	int nPad_bytes;
	int padded_length;
	byte *padded_buffer = NULL;
	byte *data_buffer;
	unsigned long dataleft;  /* initial requested data size */
	bool status = true;

  nPad_bytes = -length & 3;  // number of padding bytes
	padded_length = length + nPad_bytes; 

	if ((ControllerType == FX3) && (nPad_bytes != 0))  // do padding for FX3 32-bit word access
	{
		padded_buffer = new byte [padded_length];
 		memcpy(padded_buffer, data, length);
		data_buffer = padded_buffer;
	}
	else 
		data_buffer = data;

	/* send setup data to bulk endpoint 0 to initialize data transfer */
	buffer[0] = SUR_TYPE_GPIFBLOCK;
	buffer[1] = SUR_DIR_OUT;
	buffer[2] = (unsigned char)(0xff & addr);
	buffer[3] = (unsigned char)(0xff & (addr >> 8));
	buffer[4] = (unsigned char)(0xff & (addr >> 16));
	buffer[5] = (unsigned char)(0xff & (addr >> 24));
	buffer[6] = (unsigned char)(0xff &  length);
	buffer[7] = (unsigned char)(0xff & (length >> 8));
	buffer[8] = (unsigned char)(0xff & (length >> 16));
	buffer[9] = (unsigned char)(0xff & (length >> 24));

	GET_MUTEX;
	if (!WriteBulkEndpoint(sur_control_pipe, buffer, buffersize))
  {
		DebugOutLastError("TUSBDevice::FastBlockWrite(setup phase)");
		return false;
	}

	dataleft = padded_length;
	while (dataleft > 0) 
	{
		blocksize = min(dataleft, pPipe[SUR_DATA_FASTOUT_PIPE].MaximumTransferSize);
		status &= WriteBulkEndpoint(SUR_DATA_FASTOUT_PIPE, (unsigned char *) (data_buffer + ptr), blocksize);
		ptr      += blocksize; /* increment data pointer for next transfer */
		dataleft -= blocksize; /* remaining data fraction */
	}
  RELEASE_MUTEX;

	if (padded_buffer != NULL)
		delete[] padded_buffer;

	if (status && (dataleft == 0)) {
		return true;
	} else {
		DebugOutLastError("TUSBDevice::FastBlockwrite");

		return false;
	}
}

bool TUSBDevice::FastBlockRead(unsigned char *data, int length)
{
	int addr = 0;
	unsigned char buffer[10];
	unsigned char buffersize = 10;
	int ptr = 0;
	int blocksize;          /* data size in current transfer */
	int nPad_bytes;
	byte *padded_buffer = NULL;
	byte *data_buffer;
	//int prev_blocksize; //!!!!!!!!!!!!!!!!!
	unsigned long dataleft;  /* initial requested data size */
	int nBytesRead;
	bool status = true;

	nPad_bytes = -length & 3;  // number of padding bytes

	if ((ControllerType == FX3) && (nPad_bytes != 0))  // do padding for FX3 32-bit word access
	{
		padded_buffer = new byte [length + nPad_bytes];
		data_buffer = padded_buffer;
		length += nPad_bytes;
	}
	else 
		data_buffer = data;

	GET_MUTEX;

	dataleft = length;
	while (dataleft > 0) 
	{
	    //prev_blocksize = min(dataleft, pPipe[SUR_DATA_FASTOUT_PIPE].MaximumTransferSize);
		//blocksize = min(prev_blocksize, 5);		
		blocksize = min(dataleft, pPipe[SUR_DATA_FASTIN_PIPE].MaximumTransferSize);

		/* send setup data to bulk endpoint 0 to initialize data transfer */
		buffer[0] = SUR_TYPE_GPIFBLOCK;
		buffer[1] = SUR_DIR_IN;
		buffer[2] = (unsigned char)(0xff & (addr+ptr));
		buffer[3] = (unsigned char)(0xff & ((addr+ptr) >> 8));
		buffer[4] = (unsigned char)(0xff & ((addr+ptr) >> 16));
		buffer[5] = (unsigned char)(0xff & ((addr+ptr) >> 24));
		buffer[6] = (unsigned char)(0xff &  blocksize);
		buffer[7] = (unsigned char)(0xff & (blocksize >> 8));
		buffer[8] = (unsigned char)(0xff & (blocksize >> 16));
		buffer[9] = (unsigned char)(0xff & (blocksize >> 24));

		if (!WriteBulkEndpoint(sur_control_pipe, buffer, buffersize))
		{
			DebugOutLastError("TUSBDevice::FastBlockRead(setup phase)");
			return false;
		}

    status   &= ReadBulkEndpoint(SUR_DATA_FASTIN_PIPE, (unsigned char *) (data_buffer + ptr), blocksize, &nBytesRead);
		ptr      += nBytesRead; /* increment data pointer for next transfer */
		dataleft -= nBytesRead; /* remaining data fraction */
		if (status == false)
			break;
	}
  RELEASE_MUTEX;

  if (nPad_bytes != 0)
	{
	  memcpy(data, data_buffer, length);
		if (padded_buffer != NULL)
		  delete[] padded_buffer;
	}

	if (status && (dataleft == 0)) 
	{
		return true;
	} 
	else 
	{
		DebugOutLastError("TUSBDevice::FastBlockRead");
		return false;
	}
}

bool TUSBDevice::FastBlockRead(long long Baddress, unsigned char *data, int length) // overloaded
{
	long long addr = Baddress;
	//int addr = 0;
	unsigned char buffer[10];
	unsigned char buffersize = 10;
	int ptr = 0;
	int blocksize;          /* data size in current transfer */
	int nPad_bytes;
	byte *padded_buffer = NULL;
	byte *data_buffer;
	//int prev_blocksize; //!!!!!!!!!!!!!!!!!
	unsigned long dataleft;  /* initial requested data size */
	int nBytesRead;
	bool status = true;

	nPad_bytes = -length & 3;  // number of padding bytes

	if ((ControllerType == FX3) && (nPad_bytes != 0))  // do padding for FX3 32-bit word access
	{
		padded_buffer = new byte [length + nPad_bytes];
		data_buffer = padded_buffer;
		length += nPad_bytes;
	}
	else 
		data_buffer = data;

	GET_MUTEX;
	dataleft = length;
	while (dataleft > 0) 
	{
	    //prev_blocksize = min(dataleft, pPipe[SUR_DATA_FASTOUT_PIPE].MaximumTransferSize);
		//blocksize = min(prev_blocksize, 5);		
		blocksize = min(dataleft, pPipe[SUR_DATA_FASTIN_PIPE].MaximumTransferSize);

		/* send setup data to bulk endpoint 0 to initialize data transfer */
		buffer[0] = SUR_TYPE_GPIFBLOCK;
		buffer[1] = SUR_DIR_IN;
		buffer[2] = (unsigned char)(0xff & (addr+ptr));
		buffer[3] = (unsigned char)(0xff & ((addr+ptr) >> 8));
		buffer[4] = (unsigned char)(0xff & ((addr+ptr) >> 16));
		buffer[5] = (unsigned char)(0xff & ((addr+ptr) >> 24));
		buffer[6] = (unsigned char)(0xff &  blocksize);
		buffer[7] = (unsigned char)(0xff & (blocksize >> 8));
		buffer[8] = (unsigned char)(0xff & (blocksize >> 16));
		buffer[9] = (unsigned char)(0xff & (blocksize >> 24));

		if (!WriteBulkEndpoint(sur_control_pipe, buffer, buffersize))
		{
			DebugOutLastError("TUSBDevice::FastBlockRead(setup phase)");
			return false;
		}

    status   &= ReadBulkEndpoint(SUR_DATA_FASTIN_PIPE, (unsigned char *) (data_buffer + ptr), blocksize, &nBytesRead);
		ptr      += nBytesRead; /* increment data pointer for next transfer */
		dataleft -= nBytesRead; /* remaining data fraction */
		if (status == false)
			break;
	}
  RELEASE_MUTEX;

  if (nPad_bytes != 0)
	{
	  memcpy(data, data_buffer, length);
		if (padded_buffer != NULL)
		  delete[] padded_buffer;
	}

	if (status && (dataleft == 0)) 
	{
		return true;
	} 
	else 
	{
		DebugOutLastError("TUSBDevice::FastBlockRead");
		return false;
	}
}

bool TUSBDevice::WriteEEPROM(unsigned short address, unsigned char *Data, unsigned short Length)
{
#define EEPROM_PAGESIZE 64

	SILAB_USB_REQUEST sur;
	int temp_count;
	bool status = false;
 
	sur.type   = SUR_TYPE_EEPROM;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = address;
	sur.length = Length;

	if (Length < EEPROM_PAGESIZE) {
		status = SilabUsbRequest(&sur, Data);
	} else {
		temp_count = Length;
		sur.length = EEPROM_PAGESIZE;

		while (temp_count > 0) {
			status = SilabUsbRequest(&sur, Data);
			temp_count -= EEPROM_PAGESIZE;
			sur.length  = min(EEPROM_PAGESIZE, temp_count);
			sur.addr   += EEPROM_PAGESIZE;
			Data       += EEPROM_PAGESIZE;
		}
	}

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::WriteEEPROM");
		return false;
	}
}

bool TUSBDevice::ReadEEPROM(unsigned short address, unsigned char *Data, unsigned short Length)
{
	SILAB_USB_REQUEST sur;

	sur.type   = SUR_TYPE_EEPROM;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = address;
	sur.length = Length;

	if(!SilabUsbRequest(&sur, Data))
  {
		DebugOutLastError("TUSBDevice::ReadEEPROM");
		return false;
	}
	else 
		return true;
}

bool TUSBDevice::WriteExternal(unsigned short address, unsigned char *Data, int Length)
{
	if (ControllerType == FX3)
	  return FastBlockWrite(address, Data, Length);
	
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_EXTERNAL;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = address;
	sur.length = Length;

	if (Length <=  MAX_SUR_DATA_SIZE) {
		status = SilabUsbRequest(&sur, Data);
	} else {
		status = SilabUsbRequest(&sur, Data, Length);
	}

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::WriteExternal");
		return false;
	}
}

bool TUSBDevice::ReadExternal(unsigned short address, unsigned char *Data, int Length)
{
	if (ControllerType == FX3)
	  return FastBlockRead(address, Data, Length);

	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_EXTERNAL;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = address;
	sur.length = Length;

	if (Length <=  MAX_SUR_DATA_SIZE) {
		status = SilabUsbRequest(&sur, Data);
	} else {
		status = SilabUsbRequest(&sur, Data, Length);
	}
	if (status)
		return true;
	else
	{
		DebugOutLastError("TUSBDevice::ReadExternal");
		return false;
	}
}

unsigned short TUSBDevice::ReadFIFO(unsigned char *data, int size)
{
	int nBytes;
	bool status;
	unsigned char buffer[10];
	int buffersize;

	buffer[0] = SUR_TYPE_FIFO;
	buffer[1] = SUR_DIR_IN;

	if(ControllerType == FX2) {
		buffer[2] = 0;
		buffer[3] = 0;
		buffer[4] = 0;
		buffer[5] = 0;
		buffer[6] = (unsigned char)(0xff &  size);
		buffer[7] = (unsigned char)(0xff & (size >> 8));
		buffer[8] = (unsigned char)(0xff & (size >> 16));
		buffer[9] = (unsigned char)(0xff & (size >> 24));
		buffersize = 10;
	} else {
		buffer[2] = 0;
		buffer[3] = 0;
		buffer[4] = (unsigned char)(0xff &  size);
		buffer[5] = (unsigned char)(0xff & (size >> 8));
		buffersize = 6;
	}
  GET_MUTEX;
	status = WriteBulkEndpoint(sur_control_pipe, buffer, buffersize);
	status &= ReadBulkEndpoint(sur_data_in_pipe, data, size, &nBytes);
  RELEASE_MUTEX;

	if(!status) {
		return 0;
	} else {
		return nBytes;
	}
}

bool TUSBDevice::Write8051(unsigned short address, unsigned char *Data, unsigned short Length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_8051;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = address;
	sur.length = Length;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::Write8051");
		return false;
	}
}

bool TUSBDevice::Read8051(unsigned short address, unsigned char *Data, unsigned short Length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_8051;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = address;
	sur.length = Length;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::Read8051");
		return false;
	}
}

bool TUSBDevice::SetBit8051(unsigned short address, unsigned char mask, bool set)
{
	unsigned char portreg;

	if (!Read8051(address, &portreg)) {
	       	return false;
	}

	portreg = set ? portreg | mask : portreg & (unsigned char) ~mask;

	/*
	if (!set)
	portreg &= (unsigned char) ~mask;
	else
	portreg |= mask;
	*/

	if (!Write8051(address, &portreg)) {
		return false;
	}

	return true;
}

bool TUSBDevice::GetBit8051(unsigned short address, unsigned char mask, bool& get)
{
	unsigned char portreg;

	if (!Read8051(address, &portreg)) { 
		return false;
	}

	get = ((portreg & mask) != 0);

	return true;
}

bool TUSBDevice::WriteSerial(unsigned char *Data, unsigned short Length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_SERIAL;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = 0;
	sur.length = Length;

	status = SilabUsbRequest(&sur, Data);

	if (status) 

		return true;

	else 
	{
		DebugOutLastError("TUSBDevice::WriteSerial");
		return false;
	}
}

bool TUSBDevice::ReadSerial( unsigned char *Data, unsigned short Length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_SERIAL;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = 0;
	sur.length = Length;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::ReadSerial");
		return false;
	}
}


bool TUSBDevice::I2CAck()
{
	unsigned char dummy;

	if (ControllerType == FX2) {
		Read8051(I2CS_FX, &dummy, 1);
	} else {
		Read8051(I2CS, &dummy, 1);
	}

	return ((dummy & I2CS_NACK) != 0);
}


bool TUSBDevice::ReadI2C(unsigned char SlaveAdd, unsigned char *data, unsigned short length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_I2C;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = SlaveAdd;
	sur.length = length;

	status = SilabUsbRequest(&sur, data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::ReadI2C");
		return false;
	}
}

bool TUSBDevice::WriteI2C(unsigned char SlaveAdd, unsigned char *data, unsigned short length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_I2C;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = SlaveAdd;
	sur.length = length;

	status = SilabUsbRequest(&sur, data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::WriteI2C");
		return false;
	}
}

bool TUSBDevice::WriteI2Cnv(unsigned char SlaveAdd, unsigned char *data, unsigned short length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_I2C_NV;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = SlaveAdd;
	sur.length = length;

	status = SilabUsbRequest(&sur, data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::WriteI2Cnv");
		return false;
	}
}

bool TUSBDevice::WriteLatch(unsigned char *Data)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_LATCH;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = 0;
	sur.length = 1;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::WriteLatch");
		return false;
	}
}

bool TUSBDevice::WriteCommand(unsigned char *Data, unsigned short lenght)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_CMD;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = 0;
	sur.length = lenght;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("!!!!Error: TUSBDevice::WriteCommand");
		return false;
	}
}


/* 
 * Enable special function port lines for SPI use
 *
 * SDI   PA7/RxD1out
 * SDO   PB2/RxD1
 * SCK   PB3/TxD1  
 */
void TUSBDevice::InitSPI()
{
	SetBit8051(PORTACFG, bmBIT7, 1);

	SetBit8051(PORTBCFG, bmBIT2 | bmBIT3, 1);


	SetBit8051(PORTACFG, bmBIT6, 0);
	SetBit8051(OUTA, bmBIT6, 0);
	SetBit8051(OEA, bmBIT6, 1);

	/* address lines for chip select
	 *
	 *   ADD0  PB0
	 *   ADD1  PB1
	 *   ADD2  PB4
	 *   ADD3  PB5
	 *   ADD4  PB6
	 *
	 * ADC chip select
	 *  /CSADC PB7
	 */
	SetBit8051(PORTBCFG, bmBIT0 | bmBIT1 | bmBIT4 | bmBIT5 | bmBIT6 | bmBIT7, 0);
	SetBit8051(OUTB, bmBIT0 | bmBIT1 | bmBIT4 | bmBIT5 | bmBIT6, 0);
  SetBit8051(OUTB, bmBIT7, 1); /* de-select ADC */
	SetBit8051(OEB, bmBIT0 | bmBIT1 | bmBIT4 | bmBIT5 | bmBIT6 | bmBIT7, 1); /* enable outputs */

	/* enable UART for SPI functionality
	 *
	 * *** remember: UART sends and receives LSB first      ***
	 * *** transmit on falling edge, receive on rising edge ***
	 * *** half duplex communication, can't send and receive at the same time ***
	 *
	 * SCON1
	 * bit7   serial mode bit0
	 * bit6   serial mode bit1  (see EZ-USB C-31)
	 * bit5   multiprocessor enable
	 * bit4   receive enable
	 * bit3   9th data bit transmitted (mode 2 and 3 only)
	 * bit2   9th data bit received (mode 2 and 3 only)
	 * bit1   transmit interrupt flag
	 * bit0   receive interrupt flag
	 */
	SetBit8051(SCON1, 0x13, 1);  /* mode 0, baud 24MHz/12, enable receive */
}

bool TUSBDevice::WriteSPI(int add, unsigned char *Data, unsigned short length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_SPI;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = add;
	sur.length = length;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::WriteSPI");
		return false;
	}
}

bool TUSBDevice::ReadSPI(int add, unsigned char *Data, unsigned short length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_SPI;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = add;
	sur.length = length;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::ReadSPI");
		return false;
	}
}


bool TUSBDevice::ReadADC(unsigned char address, int *Data)
{
	SILAB_USB_REQUEST sur;
	bool status;
	unsigned char bData[2];

	sur.type   = SUR_TYPE_ADC;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = address;
	sur.length = 2;

	status = SilabUsbRequest(&sur, bData);

	*Data = (unsigned short) (bData[1] + (bData[0] << 8));

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::ReadADC");
		return false;
	}
}

bool TUSBDevice::ReadAdcSPI(unsigned char address, unsigned char *Data)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_ADCSPI;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = address;
	sur.length = 4;

	status = SilabUsbRequest(&sur, Data);

	if (status) 
		return true;
	else 
	{
		DebugOutLastError("TUSBDevice::ReadAdcSPI");
		return false;
	}
}

bool TUSBDevice::ResetPipe(int pipenum)
{
	if (!WinUsb_ResetPipe(WinUSBInterfaceHandle, pipenum))
	{
		DebugOutLastError("TUSBDevice::ResetPipe");
		return false;
	}
	return true;
}

bool TUSBDevice::FlushPipe(int pipenum)
{
	if (!WinUsb_FlushPipe(WinUSBInterfaceHandle, pipenum)) 
	{
		DebugOutLastError("TUSBDevice::FlushPipe");
		return false;
	}
	return true;
}

bool TUSBDevice::AbortPipe(int pipenum)
{
	if (!WinUsb_AbortPipe(WinUSBInterfaceHandle, pipenum)) 
	{
		DebugOutLastError("TUSBDevice::ResetPipe");
		return false;
	}
	return true;

}


void TUSBDevice::Hold8051()
{
	WINUSB_SETUP_PACKET  myRequest;
  UCHAR data;


	myRequest.Request      = VR_ANCHOR_DLD;   // Cypress specific vendor request 
	myRequest.RequestType  = VR_DOWNLOAD;     // direction host -> devoce
	myRequest.Value        = cpu_cs_reg;      // address 
	myRequest.Index        = 0;               // not used
	myRequest.Length       = 1;               // data length 
  data = 1;

	VendorRequest(myRequest, &data);
}

void TUSBDevice::Run8051()
{
	WINUSB_SETUP_PACKET  myRequest;
	UCHAR data;

	myRequest.Request      = VR_ANCHOR_DLD;   // Cypress specific vendor request 
	myRequest.RequestType  = VR_DOWNLOAD;     // direction host -> devoce
	myRequest.Value        = cpu_cs_reg;      // address 
	myRequest.Index        = 0;               // not used
	myRequest.Length       = 1;               // data length 
	data = 0;

	VendorRequest(myRequest, &data);
}


bool TUSBDevice::GetRevision(unsigned char *rev)
{
	WINUSB_SETUP_PACKET  myRequest;
	bool status;

	/* request handled by USB core */
	myRequest.RequestType = VR_ANCHOR_DLD;
	myRequest.Request  = (UCHAR)cpu_cs_reg;      /* 8051 control register */
	myRequest.Index    = 0;               /* not used */
	myRequest.Length   = 1;               /* data length */
	myRequest.Value    = 0;               /* readback data */

	status = VendorRequest(myRequest, NULL);

	if (status) {
		/* shift cpucs register to get rev. field */
		*rev = (unsigned char)((myRequest.Value >> 4) & 0x0F); // shift cpucs register to get rev. field
		return true;
	}
	else
		return false;
}

/* EEPROM data structure for firmware load:
 * 
 *   Address      Contents
 * ------------------------------------------------------
 *    0          0xB2 (0xC2), enables firmware download from EEPROM
 *    1          VID lb, Vendor ID
 *    2          VID hb
 *    3          PID lb, Product ID
 *    4          PID hb
 *    5          DID lb, Device ID
 *    6          DID hb
 *    7          config unsigned char (FX2LP only)
 * --------------------------------------------------------
 *     beginn of data records
 * ------------------------------------------------------
 *    7 (8)          Length hb, start of first data record
 *    8 (9)          Length lb
 *    9 (10)         Address hb
 *    10 (11)        Address lb
 *    11 (12)        first data unsigned char
 *    .           ...
 * -----------------------------------------------------
 *    more data records
 * -----------------------------------------------------
 * -----------------------------------------------------
 *    last data record (MSB of Length must be 1)
 *    write to CPUCS register to bring 8051 out of eset
 * -----------------------------------------------------
 *               0x80
 *               0x01
 *               0x7F  (0xE6)
 *               0x92  (0x00)
 *               0x00
 */
bool TUSBDevice::LoadFirmwareFromFile(std::string FileName)
{
//#define MAX_FILE_SIZE (1024*16)  // 16 k for FX2LP devices

	FILE *fpointer;
	unsigned char *buffer;
	int numread;
	unsigned long nBytes, fsize;
  WINUSB_SETUP_PACKET WinUsb_Setup_Packet;
	
	fpointer = fopen(FileName.c_str(),"rb");

	if (fpointer == NULL)
		return false;

	fseek(fpointer, 0, SEEK_END);
	fsize = ftell(fpointer);
	rewind(fpointer);
	buffer = new unsigned char[fsize];
	numread = fread(buffer, 1, fsize, fpointer);
	if (numread != fsize)
	{
	  delete[] buffer;
		return false;
	}
	fclose(fpointer);
	configured = false;

  WinUsb_Setup_Packet.Request     = VR_ANCHOR_DLD;  // vendor command
  WinUsb_Setup_Packet.RequestType = VR_DOWNLOAD;    // OUT (download)
	WinUsb_Setup_Packet.Index       = 0;              // not used 

	Hold8051();

  unsigned long dataleft = numread;
	unsigned long dataptr  = 0;
	unsigned long datasize;
  
	GET_MUTEX;
	do
	{
		datasize = min (dataleft, MAX_CONTROL_PACKET_SIZE);
		WinUsb_Setup_Packet.Value  = (unsigned short)(0xffff & dataptr); // address
		WinUsb_Setup_Packet.Length = (unsigned short)(0xffff & datasize);

		if (!WinUsb_ControlTransfer(
								 WinUSBInterfaceHandle,
								 WinUsb_Setup_Packet,
								 &buffer[dataptr],
								 datasize,
								 &nBytes,
								 NULL))
		{
			DebugOutLastError("LoadFirmwareFromFile::VendorRequest");
			delete[] buffer;
			return false;
		}
		dataleft -= datasize;
		dataptr  += datasize;
  } while(dataleft);
	RELEASE_MUTEX;

  Run8051();
	delete[] buffer;
	return true;
}

bool TUSBDevice::LoadHexFileToEeprom(std::string FileName) {
	struct HEX_RECORDS   *Hex_Records=NULL;
	struct HEX_RECORDS   *entry, *entry_prev=NULL, *current=NULL;
	FILE                 *image;
	int status=0;

	size_t              data_len = 0;
	int lines=0, bytes=0;

	unsigned char  magicword;
	unsigned char  VendorDeviceID[6];
	unsigned char  LastRecord[6];
	unsigned short  addoffset;


	if (ControllerType == FX2) {
		addoffset = 8;
		magicword = 0xc2;
	} else {
		addoffset = 7;
		magicword = 0xb2;
	}

	image = fopen (FileName.c_str(), "r");

	for (;;) {
		char            buf [512], *cp;
		char            tmp, type;
		size_t          len;
		unsigned        idx, off;

		cp = fgets(buf, sizeof buf, image);
		if (cp == 0) {
			fprintf (stderr, "EOF without EOF record!\n");
			status = -1;
			
			break;
		}

		lines++;

		if (buf[0] == '#')   continue;

		if (buf[0] != ':') {
			fprintf (stderr, "not an ihex record: %s", buf);
			status = -2;
			
			break;
		}

		tmp = buf[3]; buf[3] = 0;  len = strtoul(buf+1, 0, 16);  buf[3] = tmp;
		tmp = buf[7]; buf[7] = 0;  off = strtoul(buf+3, 0, 16);  buf[7] = tmp;
		tmp = buf[9]; buf[9] = 0; type = (char)strtoul(buf+7, 0, 16);  buf[9] = tmp;

		if (type == 1) {
			break;
		}

		if (type != 0) {
			fprintf (stderr, "unsupported record type: %u\n", type);
			status = -3;
			
			break;
		}

		if ((len * 2) + 11 >= strlen(buf)) {
			fprintf (stderr, "record too short?\n");
			status = -4;
			
			break;
		}

		if ((entry = (HEX_RECORDS*)calloc (1, sizeof *entry)) == 0) {
			status = -5; break;
		}

		entry->line_nr=lines;
		entry->HexRecord.Length=len;
		entry->HexRecord.Address=off;
		entry->HexRecord.Type=type;

		if (current)      current->next=entry;
		if (!Hex_Records) Hex_Records=entry;
		current=entry;

		for (idx = 0, cp = buf+9 ;  idx < len ;  idx += 1, cp += 2) {
			tmp = cp[2];   cp[2] = 0;
			entry->HexRecord.Data[idx]=(unsigned char)strtoul(cp, 0, 16);
			cp[2] = tmp;   bytes++;
		}
		data_len += len;
	}
  
	/* Write to EEPROM and free the memory */
	for (entry = Hex_Records; entry; entry = entry->next) {
		if (status==0) {
			WriteDataRecordToEeprom(entry->HexRecord, addoffset); /* write data to EEPROM */
			addoffset += (unsigned short)(entry->HexRecord.Length + 4);
		}
		free(entry_prev);  entry_prev=entry;
	} free(entry_prev);  

	fclose(image);

	if (status==0) {
		WriteEEPROM(0, &magicword, 1);

		VendorDeviceID[0] = LSB(VendorId);
		VendorDeviceID[1] = MSB(VendorId);
		VendorDeviceID[2] = LSB(ProductId);
		VendorDeviceID[3] = MSB(ProductId);
		VendorDeviceID[4] = LSB(DeviceId);
		VendorDeviceID[5] = MSB(DeviceId);
		WriteEEPROM(1, VendorDeviceID, 6);

		if(ControllerType == FX2) {
			unsigned char config = 0x01; /* connected, 400 kHz I2C */
			WriteEEPROM(7, &config, 1);
		}

		/* write last data record */
		LastRecord[0] = 0x80;
		LastRecord[1] = 0x01;
		LastRecord[2] = MSB(cpu_cs_reg);
		LastRecord[3] = LSB(cpu_cs_reg);
		LastRecord[4] = 0x00;
		WriteEEPROM(addoffset, LastRecord, 5); /* write last data to EEPROM */
	}

	if (status<0) return false;  else return true;
}

bool TUSBDevice::WriteDataRecordToEeprom(INTEL_HEX_RECORD HexRecordStruct, unsigned short Address)
{
	unsigned char *buffer;

	buffer = (unsigned char*) malloc (sizeof(INTEL_HEX_RECORD));

	*buffer     = MSB(HexRecordStruct.Length);
	*(buffer+1) = LSB(HexRecordStruct.Length);
	*(buffer+2) = MSB(HexRecordStruct.Address);
	*(buffer+3) = LSB(HexRecordStruct.Address);

	for (int j = 0; j < (HexRecordStruct.Length & 0x03ff); j++) {
		*(buffer+4+j) = HexRecordStruct.Data[j]; /* set data */
	}

	if ((Address + HexRecordStruct.Length + 4) >= eeprom_user_data_offset) {
		DebugOutLastError("Error: EEPROM code space overlaps with user data!");

		free (buffer);
		return false;
	}

	WriteEEPROM(Address, buffer, (unsigned short)(HexRecordStruct.Length + 4));

	free (buffer);
	return true;
}

/* 
 * Configure port bits for xilinx configuration
 *
 *   signal    dir    func
 *   INIT     read    signals ready(1)/error(0)  (old USB card only !!!)
 *   RDWR     write   selects configuration write or readback (FX only)
 *   BUSY     read    reads whether S3 chip is busy and not accepting new data (FX only)
 *   PROG     write   clear config data, active low
 *   DONE     read    device active, active high
 *   CS1      write   selects express config mode, active high
 */
bool TUSBDevice::InitXilinxConfPort()
{
	unsigned char portreg;

	/* configure bits on portc to I/O mode */
	if (!Read8051(xp_conf_port_cfg, &portreg, 1)) {
		return false;
	}


	/* select port i/o func. for all lines */
	if (ControllerType == FX2) {
		portreg &= (unsigned char)~xp_rdwr;
		portreg &= (unsigned char)~xp_busy;
	} else {
		portreg &= ~xp_init;
	}

	portreg &= (unsigned char)~xp_prog;
	portreg &= (unsigned char)~xp_done;
	portreg &= (unsigned char)~xp_cs1;

	if (!Write8051(xp_conf_port_cfg, &portreg, 1)) {
		return false;
	}


	/* select direction on portc lines */
	if (!Read8051(xp_conf_port_oe, &portreg, 1)) {
		return false;
	}

	if (ControllerType == FX2) {
		portreg |= (unsigned char) xp_rdwr;     /* write,  OE = 1 */
		portreg &= (unsigned char)~xp_busy;     /* read,  OE = 0 */
	} else {
		portreg &= (unsigned char)~xp_init;     /* read,  OE = 0 */
	}

	portreg |= (unsigned char) xp_prog;     /* write, OE = 1 */
	portreg &= (unsigned char)~xp_done;     /* read,  OE = 0 */
	portreg |= (unsigned char) xp_cs1;      /* write, OE = 1 */

	if (!Write8051(xp_conf_port_oe, &portreg, 1)) {
		return false;
	}

	return true;
}

bool TUSBDevice::SetXilinxConfPin(unsigned char pin, unsigned char data)
{
	unsigned char portreg;

	if (!Read8051(xp_conf_port_rd, &portreg, 1)) {
		return false;
	}

	if ((data & 0x01) == 0) {
		portreg &= (unsigned char)~pin;
	} else {
		portreg |= (unsigned char) pin;
	}

	if (!Write8051(xp_conf_port_wr, &portreg, 1)) {
		return false;
	}

	return true;
}

bool TUSBDevice::GetXilinxConfPin(unsigned char pin)
{
	unsigned char portreg;

	if (!Read8051(xp_conf_port_rd, &portreg, 1)) {
		return false;
	}

	return((portreg & pin) != 0);
}

bool TUSBDevice::WriteXilinxConfData(unsigned char *data, int size)
{
	unsigned char dummy[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

	SwapBytes(data, size);

	if (!WriteXilinx(0, data, size)) {
		return false;
	}

	WriteXilinx(0, dummy, 8);  /* eight extra clock to enable start-up */

	return true;
}

bool TUSBDevice::SetXilinxConfByte(unsigned char data)
{
	if(!Write8051(xp_conf_port_wr, &data, 1)) {
		return false;
	}

	return true;
}

unsigned char TUSBDevice::GetXilinxConfByte(void)
{
	unsigned char portreg;

	if (!Read8051(xp_conf_port_rd, &portreg, 1)) {
		return 0;
	}

	return(portreg);
}

bool TUSBDevice::XilinxAlreadyLoaded()
{
	InitXilinxConfPort();

	return GetXilinxConfPin(xp_done);
}

bool TUSBDevice::WriteXilinx(unsigned short address, unsigned char *Data, int length)
{
	if (ControllerType == FX3)
	  return FastBlockWrite(address, Data, length);

	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_XILINX;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = address;
	sur.length = length;

//	if (length <= (int)pPipe[SUR_DATA_OUT_PIPE].MaximumTransferSize) {  // does not work ... why?
	if (length <= MAX_SUR_DATA_SIZE) 
		status = SilabUsbRequest(&sur, Data);
	else 
		status = SilabUsbRequest(&sur, Data, length);

	if (status) {
		return true;
	} else {
		DebugOutLastError("TUSBDevice::WriteXilinx");
		return false;
	}
}

bool TUSBDevice::ReadXilinx(unsigned short address, unsigned char *Data, int length)
{
	if (ControllerType == FX3)
	  return FastBlockRead(address, Data, length);

	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_XILINX;
	sur.dir    = SUR_DIR_IN;
	sur.addr   = address;
	sur.length = length;

	if (length <= MAX_SUR_DATA_SIZE) 
		status = SilabUsbRequest(&sur, Data);
	else 
		status = SilabUsbRequest(&sur, Data, length);


	if (status) {
		return true;
	} else {
		DebugOutLastError("TUSBDevice::ReadXilinx");
		return false;
	}
}

bool TUSBDevice::ConfigXilinx(unsigned char *Data, unsigned short length)
{
	SILAB_USB_REQUEST sur;
	bool status;

	sur.type   = SUR_TYPE_XCONF;
	sur.dir    = SUR_DIR_OUT;
	sur.addr   = 0;
	sur.length = length;

	status = SilabUsbRequest(&sur, Data);

	if (status) {
		return true;
	} else {
		DebugOutLastError("TUSBDevice::ConfigXilinx");
		return false;
	}
}


