#include "stdafx.h"

#include "SILIB_GPIB_Device.h"

TGPIB_Device::TGPIB_Device (TGPIB_Interface * If, int Id)
{
	std::stringstream ss;
  MyIf   = If;
  MyId   = Id;
  isOk = false;
  ss << "Device with GPIB address " <<(MyId);
  MyName = ss.str();
  isOk = MyIf->NewDevice (MyId);

  // Edgar says: I moved the reset and clear functionality to a separate
  // function, since you might not neccessarily want to clear all settings
  // of your device just be connecting it.
  // If you do need this, to it after you created the device!
}

void TGPIB_Device::ResetAndClear()
{
  if (isOk)
  {
//    itimeout(MyId, 1000);
    Send("*RST");            // reset Device
    Send("*CLS");            // Clear Status register
  }
}

std::string TGPIB_Device::GetName()
{
  return MyName;
}

void TGPIB_Device::Send (std::string Str)    // return false if error
{
  MyIf->Send(MyId, Str);
}

std::string TGPIB_Device::Receive ()    // return false if error
{
/*  byte *data;
  char c[1000];
  int size;
  MyIf->Listen(MyId, data, size);
  return (std::string)data;            */

  // Edgar says: why the heck did somebody comment out this function?
  // It produces an unneccesary warning. I fixed at least this.
  return std::string("This function is currently not implemented (Silib_GPIB_Device.cpp).");
}

byte* TGPIB_Device::ReceiveBinary (byte *data, int size)    // return false if error
{
  MyIf->ReceiveBinary(MyId, data, size);
  return data;
}

std::string TGPIB_Device::SendAndReceive (std::string Msg)
{
  return MyIf->SendAndReceive(MyId, Msg);
}

void TGPIB_Device::ErrorMsg (std::string Msg)
{
  MyIf->ErrorMsg(Msg, MyId);
}



// OLD stuff
/*
void IEEEDevice::GetData (const char *format, char *buffer)    // returns device data
{
  iscanf(MyDevHndl, format, buffer);
}

byte IEEEDevice::GetStatus (void)    // returns device status
{
  unsigned char stat;
  ireadstb(MyDevHndl, &stat);
  return stat;
}
*/
