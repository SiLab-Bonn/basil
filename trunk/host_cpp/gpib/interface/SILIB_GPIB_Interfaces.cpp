#include "stdafx.h"
#include "SILIB_GPIB_Interfaces.h"

//----------------------------------------------------------------------------
//
//                         SILIB_GPIB_Interfaces.cpp
//
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
// General interface (parent class)
//----------------------------------------------------------------------------

TGPIB_Interface::TGPIB_Interface ()
{
  for (int id=0; id<MAXDEVICE; id++)
    DeviceExists[id] = false;
}

void TGPIB_Interface::RemoveDevice (int id)
{
  DeviceExists[id] = false;
}

void TGPIB_Interface::SendDebugTo (std::string text)
{
  DBGOUT_GPIB(text.c_str());
}

void TGPIB_Interface::Send (int id, std::string  Msg)
{
	std::stringstream ss; 
	ss << "Send to  " << id << ": " << Msg << std::endl;
	DBGOUT_GPIB(ss.str().c_str());

  if (DeviceExists[id]) {
    IFSend (id, Msg);
  } else {
    DBGOUT_GPIB("Device does not exist");
  }
}

byte * TGPIB_Interface::ReceiveBinary (int id, byte *Data, int size)
{
	std::stringstream ss; 
	ss << "Receiving bibary data from device " << id << "..." << std::endl;
	DBGOUT_GPIB(ss.str().c_str());

  if (DeviceExists[id])
  {
    IFReceiveBinary (id, Data, size);
  }
  else
  {
    DBGOUT_GPIB("Device does not exist");
  }
  return Data;
}

int TGPIB_Interface::Listen(int id, byte *buffer, int size)
{
  int nBytes;
	std::stringstream ss; 
	ss << "Listening to device " << id << " ..." << std::endl;
	DBGOUT_GPIB(ss.str().c_str());

  if (DeviceExists[id])
  {
    nBytes = IFListen (id, buffer, size);
  }
  else
  {
    DBGOUT_GPIB("Device does not exist");
    return 0;
  }
  return nBytes;
}

std::string  TGPIB_Interface::SendAndReceive (int id, std::string  Msg)
{
  std::string  Result = "";

  if (DeviceExists[id]) 
	{
    Result = IFSendAndReceive(id, Msg);
    if (DebugOut != NULL) 
		{
	    std::stringstream ss; 
			ss << "Send to  " << id << ": " << Msg << std::endl
				<< "Rec from " << id << ": " << Result << std::endl;
	    DBGOUT_GPIB(ss.str().c_str());
    }
  } 
	else 
	{
    ErrorMsg("Device does not exist", id);
  }
  return Result;
}

int TGPIB_Interface::SearchDevices (std::string *DevList)
{
  return IFSearchDevices(DevList);
}

int	TGPIB_Interface::GetNumberOfDevices()
{
	return numDev;
}

void	TGPIB_Interface::ClearDevice(int id)
{
	ibclr(MyDevHndl[id]);
}

void TGPIB_Interface::ErrorMsg (std::string  Msg, int id)
{
  std::stringstream ss; 
	ss << "Device "<< id << ", Error: " << Msg << std::endl;
	DBGOUT_GPIB(ss.str().c_str());
}

//----------------------------------------------------------------------------
// HP PCI interface
//----------------------------------------------------------------------------
#ifndef GPIB_Interface_USB
void SICLCALLBACK ErrorHandler (INST DevHndl, int error)
{
  char tbuffer[500];

  sprintf(tbuffer, "Device id=%d, error = %d:%s", DevHndl, error, igeterrstr(error));
  Application->MessageBox("GPIB_Interface::ErrorHandler", tbuffer, MB_ICONWARNING);
}

TGPIB_Interface_HP::TGPIB_Interface_HP (TStrings * ErrorMsg): TGPIB_Interface (ErrorMsg)
{
  ionerror(ErrorHandler);              // install error handler
//  itimeout(10, 1000);         // some commands take really long!
}

TGPIB_Interface_HP::~TGPIB_Interface_HP(void)
{
  for (int id=0; id<MAXDEVICE; id++) {
    if (DeviceExists[id])
      iclose(MyDevHndl[id]);
  }
}

bool TGPIB_Interface_HP::NewDevice (int id)
{
//
// änderung Manuel: hpib0 durch gpib0 ersetzt für neue Agilent-Treiber IO-Toolbox 14
//


	char tbuffer[10];
  sprintf(tbuffer, "gpib0,%d", id);    // open device connected to interface "hpib0"
  MyDevHndl[id] = iopen(tbuffer);      //  with Device Id "id"

                                     // ??? Check if it worked !!!
  if (MyDevHndl[id] != 0) DeviceExists[id] = true;
  else DeviceExists[id] = false;
  
  return DeviceExists[id];
}

void TGPIB_Interface_HP::IFSend (int id, std::string  Msg)
{
  iprintf(MyDevHndl[id], "%s\n", Msg.c_str());
}

byte * TGPIB_Interface_HP::IFReceiveBinary (int id, byte *Data, int size)
{
// not implemented yet !!!

//  iscanf(MyDevHndl,"%t\n", Data);
/*
  ibrd (MyDevHndl[id], Data, size);
  if (ibsta & ERR)
  {
    ErrorMsg("Unable to read data from device " + std::string(id));
  }
  return Data;
*/
  return Data;
}

int TGPIB_Interface_HP::IFListen (int id, byte *buffer, int size)
{
unsigned long bufsize;
int reason;
unsigned long actualcnt;

 iread (MyDevHndl[id], buffer, size, &reason, &actualcnt);


  return actualcnt;
}

byte TGPIB_Interface_HP::IFSearchDevices (TStrings *DevList)
{
	return 0;
}

std::string  TGPIB_Interface_HP::IFSendAndReceive (int id, std::string Msg)
{
	std::string  Result;
	char readbuffer[5000] = "";
	/* Set the I/O timeout value for this session to
	2 seconds */
	itimeout(MyDevHndl[id], 2000);
  
  ipromptf(MyDevHndl[id], "%s\n", "%t", Msg.c_str(),  readbuffer);
  Result = std::string(readbuffer);
  Result = TrimRight(Result);         //removes control-character at the end ( /n)
  return Result;    // errors are handled with error handler
}
#endif
//----------------------------------------------------------------------------
//  KEITHLEY USB interface
//----------------------------------------------------------------------------

#ifdef GPIB_Interface_USB

TGPIB_Interface_USB::TGPIB_Interface_USB(): TGPIB_Interface ()
{
}

TGPIB_Interface_USB::~TGPIB_Interface_USB(void)
{
}

bool TGPIB_Interface_USB::NewDevice (int id)
{
  MyDevHndl[id] = ibdev(0, id, 0, T1s, 1, 0);      // last: EOTMODE, EOSMODE
	if (ibsta & ERR)
  {
    ErrorMsg("Unable to open device driver, ID ", id);
    return false;
  }
  else
  {
    DeviceExists[id] = true;
		ibstop(MyDevHndl[id]);
    return true;
  }
}

void TGPIB_Interface_USB::IFSend (int id, std::string  Msg)
{
	ibwrt (MyDevHndl[id], (void *)Msg.c_str(), Msg.size());
  if (ibsta & ERR)
    ErrorMsg("IFSend", id);
}

byte * TGPIB_Interface_USB::IFReceiveBinary (int id, byte *Data, int size)
{

  ibrd (MyDevHndl[id], Data, size);
  if (ibsta & ERR)
  {
    ErrorMsg("Unable to read data from device ID ", id);
  }
  return Data;
}

int TGPIB_Interface_USB::IFListen (int id, byte *buffer, int size)
{
  ReceiveSetup (0, id);
  if (ibsta & ERR)
  {
		ErrorMsg("Unable prepare listen mode. ERROR " , ibsta);
    return 0;
  }
  RcvRespMsg (0, buffer, size, STOPend);
  if (ibsta & ERR)
  {
    ErrorMsg("Unable to listen to device " , id);
    return 0;
  }
  SendIFC (0);
  return ibcntl;
}


std::string  TGPIB_Interface_USB::IFSendAndReceive (int id, std::string  Msg)
{
//	Msg.append("\n");
//	ibclr(MyDevHndl[id]);
  ibwrt (MyDevHndl[id], (void *)Msg.c_str(), Msg.size());

  const int ARRAYSIZE = 5000;
  char      ValueStr[ARRAYSIZE + 1];

  ibrd (MyDevHndl[id], ValueStr, ARRAYSIZE);
  if (ibsta & ERR)
  {
    ErrorMsg("Unable to read data from device ", id);
		return std::string("");
  }
  ValueStr[ibcntl - 1] = '\0';

  return std::string (ValueStr);
}

int TGPIB_Interface_USB::IFSearchDevices (std::string  *DevList)
{
  #define MAX_DEV_ADD   31
  Addr4882_t addlist[MAX_DEV_ADD];
  Addr4882_t resultlist[MAX_DEV_ADD];
  int tmpDev;
  std::stringstream ss; 

  const int ARRAYSIZE = 5000;
  char      ValueStr[ARRAYSIZE + 1];


  for (int i = 0; i < MAX_DEV_ADD - 1; i++)
    addlist[i] = i + 1;

  addlist[MAX_DEV_ADD - 1] = NOADDR;  // terminate list

  // reset interface
  SendIFC(0);
  // scan GPIB bus for listeners
  FindLstn(0, addlist, resultlist, MAX_DEV_ADD - 1);

  numDev = ibcntl;

  //
  for (int i = 0; i < numDev; i++)
  {
    tmpDev = ibdev(0, resultlist[i], 0, T1s, 1, 0);
    // default command
		ibclr(tmpDev);
    ibwrt(tmpDev, "*IDN?", 5);
    ibrd (tmpDev, ValueStr, ARRAYSIZE);
    if (ibcntl > 1)
		{
			ValueStr[ibcntl - 1] = '\0';
			ss << "ADD " << resultlist[i] << ": " << ValueStr;
			DevList[i] = ss.str().c_str();      
			NewDevice(resultlist[i]);

		}
/*	
		// older HP DC Source and Switch Matrix syntax
    ibclr(tmpDev);
    ibwrt(tmpDev, "ID ;", 4);
    ibrd (tmpDev, ValueStr, ARRAYSIZE);
    if (ibcntl > 1)
		{
			ValueStr[ibcntl - 1] = '\0';
			ss << "ADD " << resultlist[i] << ": " << ValueStr;
			DevList[i] = ss.str().c_str();      
		}

    ibclr(tmpDev);
    ibwrt(tmpDev, "ID \n", 4);
    ibrd (tmpDev, ValueStr, ARRAYSIZE);
    if (ibcntl > 1)
		{
			ValueStr[ibcntl - 1] = '\0';
			ss << "ADD " << resultlist[i] << ": " << ValueStr;
			DevList[i] = ss.str().c_str();      
		}

	*/
    if (ibsta & ERR)
			ErrorMsg("Unable to read data from device " ,i);
	
 }

  return ibcntl;
}


#endif // GPIB_Interface_USB


//----------------------------------------------------------------------------
//
//  KEITHLEY PCI interface
//
//----------------------------------------------------------------------------

/*
TGPIB_Interface_KEITHLEY::TGPIB_Interface_KEITHLEY(void)
{
  ieee488_initialize (21,0);        // make PC a controller at address 21
}

void TGPIB_Interface_KEITHLEY::IFSend    (int id, std::string Msg)
{
}

std::string  TGPIB_Interface_KEITHLEY::IFSendAndReceive (int id, std::string  Msg)
{
  return "Mist";
}
*/

//   ieee488_initialize (21,0);      // make PC a controller at address 21
//  BB_delay(100);                  // wait until ready
//      ieee488_send(DeviceId, str, 0xFFFF, &status);
/*
     if (status == 0) {
       return true;                          // sucess -> no error
     } else {
       ErrorMsg(ERR_FATAL, DeviceName.c_str(), "Bad status returned");
       return false;
     }
   } else {                                  // Device does not exist
     return false;                           //  -> return error
   }

*/
