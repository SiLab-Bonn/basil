#pragma once

#include <sstream>

#include <stdlib.h>
#ifdef WIN32
  #include <windows.h>
#endif

#ifdef WIN32
  #ifdef DLL_EXPORT
    #define DECLDIR __declspec(dllexport)
  #elif USE_STATIC_LIB
    #define DECLDIR
  #else
    #define DECLDIR __declspec(dllimport)
  #endif
#endif

using namespace std;

#ifdef DEBUG
#define DBGOUT(s)            \
{                             \
   std::ostringstream os;    \
   os << s;                   \
   OutputDebugString( os.str().c_str() );  \
} 
#else
#define DBGOUT(...) ((void)0)
#endif


// TRANSFER LAYER address space mapping, 8 bytes (64 bit): 
//
//              MSB                                                     LSB
// add byte: |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   |
//    tcp    |  int. |not u'd|         IP address            |     port      |   
//    usb    |  int. |not u'd|   vendor ID   |  product ID   | class | index |   
//    
//

enum InterfaceTypeEnum {IF_USB, IF_TCPIP, IF_GPIB, IF_DEBUG};

#pragma pack(push) // store current allignment parameter
#pragma pack(1) // make sure the union is corectly packed on byte boundaries

typedef union _TL_addr  // transfer layer address
{
	__int64 raw;
	struct 
	{
		unsigned char  InterfaceType;
		unsigned char  not_used_1;
		unsigned int   IpAddress;
		unsigned short PortNumber;
	};
	struct 
	{
		unsigned char  InterfaceType;
		unsigned char  not_used_2;
		unsigned short VendorID;
		unsigned short ProductID;
		unsigned char  Class;
		unsigned char  Index;
	};
 // TL_addr_fields field;
} TL_addr;

// HARDWARE LAYER address space mapping, 8 bytes (64 bit): 
//
//              MSB                                                     LSB
// add byte: |   7   |   6   |   5   |   4   |   3   |   2   |   1   |   0   |
//           |  n.u. |b.type | b.add.|dev add|         local address         |   
//    
//
//   bus type: I2C, SPI, FPGA (µC bus)
//   bus address: I2C bus , SPI, FPGA (µC bus)
//   device address: devic slave address (I2C or SPI)
//   local address: address within the device (memory location or register)

enum BusTypeEnum {BT_FPGA, BT_FPGA_BLOCK, BT_I2C, BT_SPI};

typedef union _HL_addr  // hardware layer (local) address
{
	__int64 raw;
	struct 
	{
		unsigned char not_used_0;
		unsigned char LocalBusType;
		unsigned char LocalBusAddress;
		unsigned char LocalDeviceAddress;
		unsigned int  LocalAddress;
	};
 // LO_addr_fields field;
} HL_addr;


#pragma pack(pop) // restore  allignment parameter

#define I2C_SLAVE_ADD_READ_BIT 0x01  // hack: do it more fail safe


class DECLDIR TL_base
{
public:
	TL_base(void);
	~TL_base(void);

	// API of the transport layer, commonly used operations already implemented in the base class
	int  ListDevices(int *devAddList);
	bool Open(int devAdd);
	bool Close(int devAdd);
	bool Write(__int64 add, unsigned char *data, int nBytes);
	bool Read( __int64 add, unsigned char *data, int nBytes);
	bool Read(__int64 add, unsigned char *data, int nBytes, int *nBytesReceived);  
	TL_addr mTLAdd;
	
protected:
	// device specific implementation of the transportation layer
	virtual int  TL_ListDevices(int *devAddList) = 0;
	virtual bool TL_Open(int devAdd) = 0;
	virtual bool TL_Close(int devAdd) = 0;
	virtual bool TL_Write(__int64 add, unsigned char *data, int nBytes) = 0;
	virtual bool TL_Read( __int64 add, unsigned char *data, int nBytes) = 0;
	virtual bool TL_Read( __int64 add, unsigned char *data, int nBytes, int *nBytesReceived) = 0;  

	int devsFound;
	int *devAddList;
};

