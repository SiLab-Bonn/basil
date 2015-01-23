#include "TL_base.h"

TL_base::TL_base(void)
{
}

TL_base::~TL_base(void)
{
}

int TL_base::ListDevices(int *devAddList)
{
	int nDevices = TL_ListDevices(devAddList);

		DBGOUT("TL_base::ListDevices(): " << nDevices << " device(s) found"<< endl);

	for (int i = 0; i < nDevices; i++)
		DBGOUT("devAdd: " << devAddList[i] << endl);

	return nDevices;
}

bool TL_base::Open(int devAdd)
{
	bool status = TL_Open(devAdd);
	if (status)
	{
	  DBGOUT("TL_base::Open(" << devAdd << ") succeeded"<< endl); 
	}
	else
	{
    DBGOUT("TL_base::Open(" << devAdd << ") failed"<< endl); 
	}

	return status;
}

bool TL_base::Close(int devAdd)
{
	bool status = TL_Close(devAdd);
	if (status)
	{
	  DBGOUT("TL_base::Close(" << devAdd << ") succeeded"<< endl); 
	}
	else
	{
    DBGOUT("TL_base::Close(" << devAdd << ") failed"<< endl); 
	}

	return status;
}

bool TL_base::Write(__int64 add, unsigned char *data, int nBytes)
{
	HL_addr *HL_addr_ptr = (HL_addr*)&add ;
	DBGOUT("TL_base::Write(...)" << endl);
	DBGOUT(" InterfaceType: "        <<             (int)mTLAdd.InterfaceType << endl);
	DBGOUT(" InterfaceAddress: 0x"   << std::hex << (int)mTLAdd.IpAddress << endl);
	DBGOUT(" LocalBusType: "         <<             (int)HL_addr_ptr->LocalBusType << endl);
	DBGOUT(" LocalDeviceAddress: 0x" << std::hex << (int)HL_addr_ptr->LocalDeviceAddress << endl);
	DBGOUT(" LocalAddress: 0x"       << std::hex << (int)HL_addr_ptr->LocalAddress << endl);	
	DBGOUT(" Data[0]: 0x"            << std::hex << (int)data[0] << endl);	
	DBGOUT(" nBytes: "               << nBytes << endl);
	
  bool status = TL_Write(add, data, nBytes);
	if (status)
	{
	  DBGOUT("succeeded"<< endl); 
	}
	else
	{	  
		DBGOUT("failed"<< endl); 
	}

	return status;
}

bool TL_base::Read(__int64 add, unsigned char *data, int nBytes)
{
	HL_addr *HL_addr_ptr = (HL_addr*)&add ;
	DBGOUT("TL_base::Read(...)" << endl);
	DBGOUT(" InterfaceType: "        <<             (int)mTLAdd.InterfaceType << endl);
	DBGOUT(" InterfaceAddress: 0x"   << std::hex << (int)mTLAdd.IpAddress << endl);
	DBGOUT(" LocalBusType: "         <<             (int)HL_addr_ptr->LocalBusType << endl);
	DBGOUT(" LocalDeviceAddress: 0x" << std::hex << (int)HL_addr_ptr->LocalDeviceAddress << endl);
	DBGOUT(" LocalAddress: 0x"       << std::hex << (int)HL_addr_ptr->LocalAddress << endl);	
	DBGOUT(" nBytes: "               << nBytes << endl);

	bool status = TL_Read(add, data, nBytes);

	DBGOUT(" Data[0]: 0x"            << std::hex << (int)data[0] << endl);	


	if (status)
	{
	  DBGOUT("succeeded"<< endl); 
	}
	else
	{	  
		DBGOUT("failed"<< endl); 
	}

	return status;
}

bool TL_base::Read(__int64 add, unsigned char *data, int nBytes, int *nBytesReceived)
{
	bool status = TL_Read(add, data, nBytes, nBytesReceived);
	if (status)
	{
	  DBGOUT("TL_base::Read(" << add << ", <data>," << nBytes << ", " << (int)(*nBytesReceived) << ") succeeded"<< endl); 
	}
	else
	{	  
		DBGOUT("TL_base::Read(" << add << ", <data>," << nBytes << ") failed"<< endl); 
	}

	return status;
}