//------------------------------------------------------------------------------
//       USBDevice.h
//
//       SILAB, Phys. Inst Bonn, HK
//
//  USB devices associated to slbusb.sys device driver
//
//  History:
//  03.10.01	modifiedadded init functions (StartDriver, StopDriver)
//				for TUSBDeviceManager
//  31.08.01	added latch and adc access for mqube tracker
//  06.11.03	some changes for the Class Explorer View
//  01.08.10	modifications for running serveral applications without
//				each loading TUSBDeviceManager (added GetIndex(), changed
//				StartDriver and StopDriver to public functions)
//------------------------------------------------------------------------------

#ifndef USBDeviceH
#define USBDeviceH 1

#ifdef WIN32
  #include <windows.h>
  #include "winusb.h"
#endif

#include "myutils.h"
#include "SURConstants.h"
#include "SiXilinxChip.h"

#ifdef WIN32
	static CRITICAL_SECTION CriticalSection;
	#define INIT_MUTEX     InitializeCriticalSectionAndSpinCount(&CriticalSection, 0x00000400)
	#define FREE_MUTEX     DeleteCriticalSection(&CriticalSection)
	#define GET_MUTEX      EnterCriticalSection(&CriticalSection)
	#define RELEASE_MUTEX  LeaveCriticalSection(&CriticalSection)
#elif LINUX
#endif

#define MSB(word) (unsigned char)(((unsigned short)word >> 8) & 0xff)
#define LSB(word) (unsigned char)((unsigned short)word & 0xff)

typedef enum {FX, FX2, FX3};

#define MAX_PIPES                  32
#define MAX_CONTROL_PACKET_SIZE    64
#define MAX_SUR_DATA_SIZE          0xffff

// vendor specific requests
#define VR_ANCHOR_DLD   0xa0 // handled by core
#define VR_EEPROM       0xa2 // loads (uploads) EEPROM
#define	VR_RAM          0xa3 // loads (uploads) external ram
#define	VR_UPLOAD       0xc0 // correspondes to REQUEST_DIR_IN
#define VR_DOWNLOAD     0x40 // correspondes to REQUEST_DIR_OUT
#define VR_SETI2CADDR   0xa4
#define VR_GETI2C_TYPE  0xa5 // 8 or 16 unsigned char address
#define VR_GET_CHIP_REV 0xa6 // Rev A, B = 0, Rev C = 2 // NOTE: New TNG Rev
#define VR_TEST_MEM     0xa7 // runs mem test and returns result
#define VR_RENUM        0xa8 // renum
#define VR_PREPARE_RAM  0xaa // prepare RAM bulk access

// parameter for vendor specific requests to endpoint 0
#define REQUEST_DIR_OUT     0
#define REQUEST_DIR_IN      1
#define REQUEST_TYPE_STD    0
#define REQUEST_TYPE_CLS    1
#define REQUEST_TYPE_VDR    2
#define REQUEST_RCP_DEV     0
#define REQUEST_RCP_INT     1
#define REQUEST_RCP_EP      2

//-----------------------------------------------------------------------------
// Addresses in Cypress chip
//-----------------------------------------------------------------------------
#define bmBIT0			0x01
#define bmBIT1			0x02
#define bmBIT2			0x04
#define bmBIT3			0x08
#define bmBIT4			0x10
#define bmBIT5			0x20
#define bmBIT6			0x40
#define bmBIT7			0x80

#define CPUCS_REG     0x7F92
#define CPUCS_REG_FX	0xE600
#define PORTACFG		0x7F93	// selects between port I/O (0) or spec. func (1)
#define PORTBCFG		0x7F94
#define PORTCCFG		0x7F95
#define OUTA			0x7F96	// output register
#define OUTB			0x7F97
#define OUTC			0x7F98
#define PINSA			0x7F99	// input line
#define PINSB			0x7F9A
#define PINSC			0x7F9B
#define OEA				0x7F9C	// active high output enable
#define OEB				0x7F9D
#define OEC				0x7F9E
#define SCON1     0xC0
#define I2CS			0x7FA5  // I2C bus status register
#define I2CS_NACK		0x02	// I2C Status: I2C error; No Acknowledge
#define I2CS_FX			0xE678  // I2C bus status register
#define EEPROM_SIZE	8096

//--- FX2 port register
#define PORTACFG_FX		0xE670
#define IOA_FX			  0x80
#define OEA_FX			  0xB2

// some declarations for EEPROM programming
#define MAX_INTEL_HEX_RECORD_LENGTH 16
typedef struct _INTEL_HEX_RECORD
{
   unsigned char  Length;
   unsigned short   Address;
   unsigned char  Type;
   unsigned char  Data[MAX_INTEL_HEX_RECORD_LENGTH];
} INTEL_HEX_RECORD, *PINTEL_HEX_RECORD;

struct HEX_RECORDS {
	struct   HEX_RECORDS   *next;
        int      line_nr;
	INTEL_HEX_RECORD      HexRecord;
};
//------------------------------------------------------------------------------
//  TI2CMaster
//  virtual base class
//  write and read I2C functions are implemented in derived class (TUSBDevice)
//------------------------------------------------------------------------------
class TI2CMaster
{
public:
	TI2CMaster(){};
	virtual bool I2CAck() = 0;
	virtual bool ReadI2C(unsigned char SlaveAdd, unsigned char *Data, unsigned short Length) = 0;
	virtual bool WriteI2C(unsigned char SlaveAdd, unsigned char *Data, unsigned short Length) = 0;
	virtual bool WriteI2Cnv(unsigned char SlaveAdd, unsigned char *Data, unsigned short Length) = 0;
};

//------------------------------------------------------------------------------
//  TSPIMaster
//  virtual base class
//  write and read SPI functions are implemented in derived class (TUSBDevice)
//------------------------------------------------------------------------------
class TSPIMaster  // generic SPI controller
{
public:
	TSPIMaster(){};
	virtual void InitSPI() = 0;
	virtual bool WriteSPI(int add, unsigned char *Data, unsigned short length) = 0;
	virtual bool ReadSPI(int add, unsigned char *Data, unsigned short length) = 0;
};

//------------------------------------------------------------------------------
//  TUSBDevice
//  THE main class
//------------------------------------------------------------------------------
class TUSBDevice: TI2CMaster, TSPIMaster, public TXilinxChip
{
	friend class TUSBDeviceManager;        // members einschrnken ?

public:
	TUSBDevice(int index);
	~TUSBDevice();
	void Init();

	bool StartDriver();                               // open device driver
	bool StopDriver();                               // close device driver
	bool DeviceAvailable(void);  // check if device is available (connected)

	// identification values
	int GetId(){return Id;};
	int GetIndex(){return DeviceDriverIndex;};
	const char* GetName(){return Name.c_str();};
	int GetClass(){return DeviceClass;};
	int GetFWVersion(){return FwVer;};
	int GetVendorId(){ return (int)VendorId;};
	int GetDeviceId(){ return (int)DeviceId;};
	const char* GetEndpointInfo(){return PipeInfoString.c_str();};
	bool GetUserInformation();

	int DeviceDriverIndex;                         // device list index 
	unsigned short VendorId;
	unsigned short ProductId;
	unsigned short DeviceId;

	int ControllerType;

	// access EEPROM programmable device parameters
	bool ReadIDFromEEPROM();
	bool WriteIDToEEPROM(int id);
	bool ReadNameFromEEPROM();
	bool WriteNameToEEPROM(const char* name);
	bool ReadDeviceClassFromEEPROM();
	bool WriteDeviceClassToEEPROM(unsigned char dc);
	bool ReadFirmwareVersion();


	// access 8051 internal registers
	bool Write8051(unsigned short address, unsigned char *Data, unsigned short length = 1);
	bool Read8051(unsigned short address, unsigned char *Data, unsigned short length = 1);
	bool SetBit8051(unsigned short address, unsigned char  mask, bool   set);
	bool GetBit8051(unsigned short address, unsigned char  mask, bool & get);

	// FPGA configuration
	bool InitXilinxConfPort();
	bool SetXilinxConfPin(unsigned char pin, unsigned char data);
	bool GetXilinxConfPin(unsigned char pin);
	bool SetXilinxConfByte(unsigned char data);
	unsigned char GetXilinxConfByte(void);
	bool WriteXilinxConfData(unsigned char *data, int size);
	bool XilinxAlreadyLoaded();

	// FPGA access
	bool WriteXilinx(unsigned short address, unsigned char *Data, int length = 1);
	bool ReadXilinx(unsigned short address, unsigned char *Data, int length = 1);
	bool ConfigXilinx(unsigned char *Data, unsigned short length);

	// UART
	bool WriteSerial(unsigned char *Data, unsigned short length);
	bool ReadSerial(unsigned char *Data, unsigned short length);

	// generic access to external data bus
	bool WriteExternal(unsigned short address, unsigned char *Data, int length);
	bool ReadExternal(unsigned short address, unsigned char *Data, int length);

	// access to fast data bus
	bool FastBlockWrite(unsigned char *data, int length);
	bool FastBlockRead(unsigned char *data, int length);  
	// access to fast data bus + address (overload)
	bool FastBlockWrite(long long address, unsigned char *data, int length);
	bool FastBlockRead(long long address, unsigned char *data, int length);

	// FIFO access (application specific)
	//bool WriteFIFO(unsigned char *Data, unsigned short Length);
	unsigned short ReadFIFO(unsigned char *Data, int Length);
	//unsigned short ReadFIFO2(unsigned char *Data, unsigned short Length);

	// EEPROM access
	bool WriteEEPROM(unsigned short address, unsigned char *Data, unsigned short Length);
	bool ReadEEPROM(unsigned short address, unsigned char *Data, unsigned short Length);

	// generic I2C access
	bool I2CAck();
	bool WriteI2C(unsigned char SlaveAdd, unsigned char *data, unsigned short length);
	bool WriteI2Cnv(unsigned char SlaveAdd, unsigned char *data, unsigned short length);
	bool ReadI2C(unsigned char SlaveAdd, unsigned char *data, unsigned short length);

	// SPI access (application specific)
	void InitSPI();
	bool WriteSPI(int add, unsigned char *Data, unsigned short length);
	bool ReadSPI(int add, unsigned char *Data, unsigned short length);
	bool ReadAdcSPI(unsigned char address, unsigned char *Data);

	// legacy functions
	bool WriteLatch(unsigned char *Data);
	bool WriteCommand(unsigned char *Data, unsigned short length = 1); // used for uCScan
	bool ReadADC(unsigned char address, int *Data);

	// direct access to dedicated endpoints
	bool WriteRegister(unsigned char * Data);
	bool ReadRegister(unsigned char * Data);

	// firmware download
	bool LoadFirmwareFromFile(std::string FileName); // download firmware
	bool LoadHexFileToEeprom(std::string FileName);
	// bool ReadFirmwareVersion(unsigned char *Data);

	// driver low level functions
	bool FlushPipe(int nEndPoint); // dicards pipe data
	bool ResetPipe(int nEndPoint); // resets specific pipe
	bool AbortPipe(int nEndPoint); // quit pending pipe transfers

private:
	bool WriteDataRecordToEeprom(INTEL_HEX_RECORD HexRecordStruct, unsigned short Address);

	/* low level access to USB device */
	bool WriteBulkEndpoint(int nEndPoint, unsigned char *outData, int outPacketSize);
	bool ReadBulkEndpoint(int nEndPoint, unsigned char *inData, int inPacketSize, int *nBytesRead);
	bool FastByteWrite(unsigned char *data);
	bool FastByteRead(unsigned char *data);

	void Hold8051();
	void Run8051();

	bool GetRevision(unsigned char *rev);
	bool SilabUsbRequest(PSILAB_USB_REQUEST pslb, unsigned char* data);
	bool SilabUsbRequest(PSILAB_USB_REQUEST pslb, unsigned char* data, int len);
	bool VendorRequest(WINUSB_SETUP_PACKET MyRequest, unsigned char *data);
	bool GetDeviceInformation(); // get device, configuration and endpoint information
	bool WinUsb_GetDeviceInformation(); // get some information
	bool LibUsb_GetDeviceInformation(); // get some information

	HANDLE USBDeviceHandle; // 'Treibergriff'
	WINUSB_INTERFACE_HANDLE  WinUSBInterfaceHandle; 

	int  Id;
	int  FwVer;
	std::string   Name; //!< name specifying the type of device (i.e. service)
	unsigned char DeviceClass;
	bool started; // driver started
	bool configured; // firmware active

	USB_DEVICE_DESCRIPTOR        DeviceDescriptor; // accessable pointer to descriptor information
	USB_CONFIGURATION_DESCRIPTOR ConfigurationDescriptor; 
	USB_INTERFACE_DESCRIPTOR     InterfaceDescriptor;
	USB_STRING_DESCRIPTOR        StringDescriptor;
	WINUSB_PIPE_INFORMATION      PipeInformation;

	int iPipes;
	USBD_PIPE_INFORMATION pPipe[MAX_PIPES]; // pipe information structure

	std::string PipeInfoString;   // pipe info output buffer
	std::string DevicePathName;   // for winusb.sys
	std::string FirmwareFilename;

	int sur_control_pipe;
	int sur_data_out_pipe;
	int sur_data_in_pipe;
	int eeprom_user_data_offset;
	int eeprom_mfg_addr;
	int eeprom_name_addr;
	int eeprom_id_addr;
	int eeprom_liac_addr;

	unsigned short xp_conf_port_cfg;
	unsigned short xp_conf_port_oe;
	unsigned short xp_conf_port_rd;
	unsigned short xp_conf_port_wr;
	unsigned short cpu_cs_reg;
};
#endif

