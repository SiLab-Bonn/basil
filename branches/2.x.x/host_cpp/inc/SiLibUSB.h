
//------------------------------------------------------------------------------
//       SiLibUSB.h
//
//       Header File for SiUSBLib.dll
//
/*!      @mainpage SILAB USB Device Application Programming Interface


The access to the SILAB USB devices is defined in the class SiUSBDevice which is implemented 
in SiLibUSB.dll. To use the SILAB USB functions the calling application has to include SiUSBLib.h 
and link to SiUSBlib.lib. The corresponding DLL (SiLibUSB(d).dll, (d) for debug version) has to by 
copied to the working directory of the application or the Windows system directory (i.e. \\system32).

To access an USB device an instance of the SiUSBDevice class has to be created. The constructor 
expects a handle to the device driver which can be retrieved with the global function GetUSBDevice().
During the runtime of the application the handling of USB plug and play events is managed by event 
driven calls to OnDeviceChange() in response to specific system messages. See example project for
implementation of event handlers (Windows only). With Linux the user will have to call
OnDeviceChange() manually to update the USB handles when a device was plugged or unplugged.

@author Hans Krüger, SILAB, Phys. Inst. Bonn, 2003-2012
@version 2.1.0 (10.10.2012)
- major changes to driver level interface to support winusb.sys
- clean-up
- changed library name from SiUSBLib to SiLibUSB
@version 2.0.3 (1.8.2010)
- changes by Sebastian Schultes, SiLAB, Phys. Inst. Bonn
- added GetUSBDeviceIndexedNoDeviceManager() to load a device without loading the TUSBDeviceManger
- added SiUSBDevice::GetIndex() to get device driver index
@version 2.0.2 (18.02.10)
- added PLL reference clock control
- corrected Read/WriteXilinx and Read/WriteExternal ambiguities in the documentation
@version 2.0.1 (08.02.10)
- added PLL clock generator control
@version 2.0
- class implementation of the USB device API
- doxygen support
*/



#ifndef USBBOARDLIB_H
#define USBBOARDLIB_H

#include <sstream>
#include <stdlib.h>

/*! @file */
#define DLL_VERSION "20"

#ifdef WIN32
  #ifdef DLL_EXPORT
    #define DECLDIR __declspec(dllexport)
  #elif USE_STATIC_LIB
    #define DECLDIR
  #else
    #define DECLDIR __declspec(dllimport)
  #endif
#endif


/*!
Initialize USB device management, need to be called before any of the DLL
functions can be accessed.
@return true if successful else false
*/
bool DECLDIR InitUSB(void);


/*!
Read the number of connected USB devices.
@return number of connected USB devices
*/
int DECLDIR GetNumberOfUSBBoards(void);


/*!
Maximum number of USB devices supported by the driver
@return number of USB devices supported by the driver (currently fixed to 8)
*/
int DECLDIR GetMaxNumberOfUSBBoards(void);


/*!  Get handle to access individual boards. Called once at startup
and in response to USB plug and play events.

@param Id board ID as programmed in EEPROM, (int)
if ommitted function returns next available board
@param DevClass additional number stored in the EEPROM
@return handle to board with given ID (void *), or NULL pointer if
given ID is not available or no board is connected
*/
void DECLDIR * GetUSBDevice(int Id, int DevClass = -1);

/*! Alternative way to get handle to access individual boards.

@param index as listed within the driver (int)
@return handle to board with given ID (void *), or NULL pointer
given ID is not available or no board connected
*/
void DECLDIR * GetUSBDeviceIndexed(int index);

/*! Alternative way to get handle to access individual boards without using the DeviceManager

@param index as listed within the driver (int)
@return handle to board with given index (void *), or NULL pointer
given index is not available or no board connected
*/
void DECLDIR * GetUSBDeviceIndexedNoDeviceManager(int index);

/*!  Read board information

@param index as listed within the driver (int)
@return device info string
*/
std::stringstream DECLDIR * GetDevInfoString(int index);


//! Implementation of the USB device application programming interface
class DECLDIR SiUSBDevice
{
public:
	/*! Class constructor
	@param dev pointer to USB device handle as returned from GetUSBDevice(...)
	*/
	SiUSBDevice(void * dev);
	/*! Standard destructor
	*/
	~SiUSBDevice();
	//@{
	//!	@name Device handle maintenance
	//! update internal USB device pointer
	//!@param dev USB device handle as returned from GetUSBDevice(...)
	void SetDeviceHandle(void * dev);

	//! Checks existance of valid USB device handle
	//!	@return true if valid handle found, otherwise false
	bool HandlePresent(void);
	//@}

	//@{
	//!	@name Device identification
	//! Write device ID to EEPROM
	//!@param id new device ID
	//!@return true if succeeded otherwise false
	bool WriteIDToEEPROM(int id);

	/*! Write device name to EEPROM
	@param name new device name (max 20 char)
	@return true if succeeded otherwise false
	*/
	bool WriteNameToEEPROM(const char * name);

	/*! Write device class to EEPROM
	@param dc new device class
	@return true if succeeded otherwise false
	*/
	bool WriteDeviceClassToEEPROM(unsigned char dc);

	//! Read device ID (user programmable, stored in EEPROM)
	//! @return device ID
	int GetId(void);

	//! Read device driver index 
	//! @return device driver index
	int GetIndex(void);

	//! Read device name (user programmable, stored in EEPROM)
	//! @return device name
	const char * GetName(void);

	//! Read device class (user programmable, stored in EEPROM)
	//! @return device class
	int GetClass(void);
  
	//! Re-read user programmable information (Id, class, and name) which is stored in EEPROM
	//! @return true if access to user information was successful, else false (access to device with no firmware)
	bool GetUserInformation(void);

	//! Read µC firmware version
	//! @return firmware version
	int GetFWVersion(void);

	//! Read USB endpoint description
	//! @return pointer to a string with endpoint information
	const char * GetEndpointInfo(void);

	//! Read vendor ID
	//! @return vendor ID
	int GetVendorId(void);

	//! Read device ID
	//! @return device ID
	int GetDeviceId(void);
	//@}

	//@{
	//!@name FPGA and µC firmware
	//! Load new firmware into the µC (volatile)
	//! @param FileName name of the firmware file (*.bix)
	//! @return true if succeeded otherwise false
	bool LoadFirmwareFromFile(const char * FileName);

	//! Flash new µC firmware into the EEPROM
	//! @param FileName name of the firmware file (*.bix)
	//! @return true if succeeded otherwise false
	bool LoadHexFileToEeprom(const char * FileName);

	//! Configure FPGA
	//! @param fileName name of the bitstream file (*.bit)
	//! @return true if succeeded otherwise false
	bool DownloadXilinx(const char * fileName);
	//@}

	//@{
	//!@name FPGA access

	//! Write access to the FPGA. This access mode is using the 16 bit address and 8 bit data bus of the
	//! USB µC (full speed interface). This is the prefered mode for accessing single register locations or small
	//! FIFO buffers. The address is not incremented during the access (FIFO mode)
	//! @param address 16 bit address (not being incremented for length >1)
	//! @param Data pointer to array of bytes to transfer
	//! @param length number of bytes to transfer
	//! @return true if succeeded otherwise false
	bool WriteXilinx(unsigned short address, unsigned char * Data, int length = 1);

	//! Read access to the FPGA. This access mode is using the 16 bit address and 8 bit data bus of the
	//! USB µC (full speed interface). This is the prefered mode for accessing single register locations or small
	//! FIFO buffers. The address is not incremented during the access (FIFO mode)
	//! @param address 16 bit address (not being incremented for length >1)
	//! @param Data pointer to array of bytes to transfer
	//! @param length number of bytes to transfer
	//! @return true if succeeded otherwise false
	bool ReadXilinx(unsigned short address, unsigned char * Data, int length = 1);

	//! Write access to the FPGA. This access mode is using the 16 bit address and 8 bit data bus of the
	//! USB µC (full speed interface). This is the prefered mode for accessing single register locations or small
	//! memory buffers.
	//! @param address 16 bit address
	//! @param Data pointer to array of bytes to transfer
	//! @param length number of bytes to transfer
	//! @return true if succeeded otherwise false
	bool WriteExternal(unsigned short address, unsigned char * Data, int length);

	//! Read access to the FPGA. This access mode is using the 16 bit address and 8 bit data bus of the
	//! USB µC (full speed interface). This is the prefered mode for accessing single register locations or small
	//! memory buffers.
	//! @param address 16 bit address
	//! @param Data pointer to array of bytes to transfer
	//! @param length number of bytes to transfer
	//! @return true if succeeded otherwise false
	bool ReadExternal(unsigned short address, unsigned char * Data, int length);

	//! Fast write access to the FPGA to transfer large blocks of data. This access mode is using the 8 bit fast data bus of the
	//! USB µC (high speed interface) without an address bus. The base address of the memory location must be writen
	//! to the address registers within the high speed interface before the function is called. During the access
	//! the address register is automatically incremented.
	//! @param Data pointer to array of bytes to transfer
	//! @param length number of bytes to transfer
	//! @return true if succeeded otherwise false
	bool WriteBlock(unsigned char * Data, int length);
	bool WriteBlock(long long address, unsigned char * Data, int length); // + address overload

	//! Fast read access to the FPGA to transfer large blocks of data. This access mode is using the 8 bit fast data bus of the
	//! USB µC (high speed interface) without an address bus. The base address of the memory location must be writen
	//! to the address registers within the high speed interface before the function is called. During the access
	//! the address register is automatically incremented.
	//! @param Data pointer to array of bytes to transfer
	//! @param length number of bytes to transfer
	//! @return true if succeeded otherwise false
	bool ReadBlock(unsigned char * Data, int length);
	bool ReadBlock(long long address, unsigned char * Data, int length); // + address overload

	//! Write to a dedicated endpoint which will trigger an interrupt in the USB µC. Useful to control the execution of
	//! loops (i.e. execute stop command) within dedicated µC firmware code
	//! @param flags four byte of data, application specific
	//! @return true if succeeded otherwise false
	bool WriteRegister(unsigned char * Data);

	//! Read from a dedicated endpoint which will trigger an interrupt in the USB µC. Useful to control the execution of
	//! loops (i.e. read back loop index) within dedicated µC firmware code
	//! @return int (four byte of data), application specific
	bool ReadRegister(unsigned char * Data);
	//@}

	//@{
	//!@name I2C bus
	//! Check the state of the ACK flag in the I2C master, advanced usage only
	//! @return vaule of the ACK flag
	bool I2CAck(void);

	//! Write access to I2C device (volatile)
	//! @param SlaveAdd 8 bit address field: 7 bit  slave deviceaddress + R/_W bit (must be set to 0 for write)
	//! @param data pointer to array of data bytes to write (including device specific register address)
	//! @param length number of bytes to write
	//! @return true if succeeded otherwise false
	bool WriteI2C(unsigned char SlaveAdd, unsigned char * data, unsigned short length);

	//! Write access to I2C device, similar to WriteI2C() with additional waitstate to accomplish EEPROM programming cycle
	//! @param SlaveAdd 8 bit address field: 7 bit  slave deviceaddress + R/_W bit (must be set to 0 for write)
	//! @param data pointer to array of data bytes to write (including device specific register address)
	//! @param length number of bytes to write
	//! @return true if succeeded otherwise false
	bool WriteI2Cnv(unsigned char SlaveAdd, unsigned char * data, unsigned short length);

	//! Read access to I2C device
	//! @param SlaveAdd 8 bit address field: 7 bit  slave deviceaddress + R/_W bit (must be set to 1 for read)
	//! @param data pointer to array of data bytes to write (including device specific register address)
	//! @param length number of bytes to write
	//! @return true if succeeded otherwise false
	bool ReadI2C(unsigned char SlaveAdd, unsigned char * data, unsigned short length);
	//@}

	//@{
	//!@name SPI bus
	//! Initialization of a dedicated µC port to support SPI bus transfers (only supported with special hardware).
	//! Needs to be called once before other SPI functions can be used.
	void InitSPI(void);

	//! Write access to SPI device
	//! @param add slave address, as decoded by external decoder
	//! @param Data pointer to array of data bytes to be transfered
	//! @param length number of bytes to write
	//! @return true if succeeded otherwise false
	bool WriteSPI(int add, unsigned char * Data, unsigned short length);

	//! Read access to SPI device
	//! @param add slave address, as decoded by external decoder
	//! @param Data pointer to array of data bytes to be transfered
	//! @param length number of bytes to read
	//! @return true if succeeded otherwise false
	bool ReadSPI(int add, unsigned char * Data, unsigned short length);

	//! Special read access to SPI ADC (historical, not implemented in standard µC firmware)
	//! @param address slave address, as decoded by external decoder
	//! @param Data pointer to array of 4 data bytes with the ADC data (2 channels x two bytes)
	//! @return true if succeeded otherwise false
	bool ReadAdcSPI(unsigned char address, unsigned char * Data); // leagacy only
	//@}

	//@{
	//! @name Serial bus (UART)
	//! Write access to serial interface, only supported with special hardware and µC firmware
	//! @param Data pointer to array of bytes
	//! @length number of bytes to write
	//! @return true if succeeded otherwise false
	bool WriteSerial(unsigned char * Data, unsigned short length);

	//! Read access to serial interface, only supported with special hardware and µC firmware
	//! @param Data pointer to array of bytes
	//! @length number of bytes to read
	//! @return true if succeeded otherwise false
	bool ReadSerial(unsigned char * Data, unsigned short length);
	//@}

	//@{
	//!	@name Access to internal µC registers
	//! Write access to user defined µC register (µC firmware specific)
	//! @param Data pointer to byte array with data to write
	//! @param length number of bytes  to write (default 1)
	//! @return true if succeeded otherwise false
	bool WriteCommand(unsigned char * Data, unsigned short length = 1);

	//! Write access to internal µC registers
	//! @param address register address
	//! @param Data pointer to byte array with data to write
	//! @param length number of bytes  to write (default 1)
	//! @return true if succeeded otherwise false
	bool Write8051(unsigned short address, unsigned char * Data, unsigned short length = 1);

	//! Read access to internal µC registers
	//! @param address register address
	//! @param Data pointer to byte array with data to write
	//! @param length number of bytes  to write (default 1)
	//! @return true if succeeded otherwise false
	bool Read8051(unsigned short address, unsigned char * Data, unsigned short length = 1);

	//! Write access to internal µC registers (bit wise)
	//! @param address register address
	//! @param mask selection of bit to write
	//! @param set new value of masked bit
	//! @return true if succeeded otherwise false
	bool SetBit8051(unsigned short address, unsigned char mask, bool set);

	//! Read access to internal µC registers (bit wise)
	//! @param address register address
	//! @param mask selection of bit to read
	//! @param get value of masked bit
	//! @return true if succeeded otherwise false
	bool GetBit8051(unsigned short address, unsigned char mask, bool & get);
	//@}

	//@{
	//! @name EEPROM access

	//!Write access to EEPROM - do not overwrite µC firmware which is stored in the EEPROM!
	//!@param address memory location within the EEPROM (2 byte)
	//!@param Data pointer to data arrary
	//!@param Length number of bytes to write
	//!@return true if succeeded otherwise false
	bool WriteEEPROM(unsigned short address, unsigned char * Data, unsigned short Length);

	//!Read access to EEPROM
	//!@param address memory location within the EEPROM (2 byte)
	//!@param Data pointer to data arrary
	//!@param Length number of bytes to read
	//!@return true if succeeded otherwise false
	bool ReadEEPROM(unsigned short address, unsigned char * Data, unsigned short Length);
	//@}

	//@{
	//! @name Legacy functions
	//! FIFO access - only supported with special hardware (i.e. USB 1.1 board)
	//! @param Data pointer to read buffer
	//! @param Length maximum number of bytes to read
	//! @return number of bytes which have been read (<= Length)
	//bool WriteFIFO     (unsigned char *Data, unsigned short Length);
	unsigned short ReadFIFO(unsigned char * Data, int Length);
	bool WriteLatch(unsigned char * Data);
	bool ReadADC(unsigned char address, int * Data);
	bool WriteFPGA(unsigned short address, unsigned char * Data, int length = 1);
	bool ReadFPGA(unsigned short address, unsigned char * Data, int length = 1);
	//@}

protected:
	//! handle to instance of the USB device within the driver
	void *dev;
};




// Message-Handling
#ifdef WIN32 // using MS Visual C++
//! Call this function in response to a USB plug and play event. In Windows this call should be executed within the 
//! application message handler (see example program). The function will refresh the list of USB devices in the SiUSBlib.dll
//! and a successive call to GetUSBDevice() will return a valid handle in case a new board has been plugged in or NULL if
//! no board is available or the given board ID has not been found.
//! @return true if the USB device list has changed and the pointers to the devices must be updated or false if the list has not changed
//! and no pointer update is required.
DECLDIR bool OnDeviceChange(void);
#endif

#endif

