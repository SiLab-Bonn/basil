//---------------------------------------------------------------------------
// precompiled headers - for faster comilation
#ifdef USE_GLOBALS
	#include "Globals.h"
#else
	#ifdef USE_INVISIBLE_GLOBALS
		#include <Globals.h>
		// globals.h has to be included in Include search path (project options)
		// for this to work, doesn't show overcrowded class explorer
	#endif
#endif
#pragma hdrstop

#include "SILIB_GPIB_HP_E3631A.h"

// #include <stdio.h>

//------------------------------------------------------------------------------
// HP_E3631A triple Power supply
//------------------------------------------------------------------------------
TGPIB_HP_E3631A::TGPIB_HP_E3631A (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
  MyName = "HP Triple Power Supply Type HP_E3631A with ID = " + std::string (MyId);

  if (!DeviceResponds()) {
    Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
    MyIf = NULL;
  }
}
//------------------------------------------------------------------------------
std::string TGPIB_HP_E3631A::ChannelToString (TSupplyChannel Channel)
{
  std::string str;
  switch (Channel) {
    case P6V : str = "P6V";  break;
    case P25V: str = "P25V"; break;
    case N25V: str = "N25V"; break;
  }
  return str;
}
//------------------------------------------------------------------------------
void TGPIB_HP_E3631A::DisplayText(std::string Message)
{
  Send("DISPLAY:TEXT:DATA "+ Message);
  Send("DISPLAY ON");
}
//------------------------------------------------------------------------------
void TGPIB_HP_E3631A::DisplayOff(void)
{
  Send(":DISPLAY:TEXT:CLEAR");
  Send(":DISPLAY OFF");
}
//------------------------------------------------------------------------------
void TGPIB_HP_E3631A::PowerOn (void)
{
  Send(":OUTPUT ON");
}
//------------------------------------------------------------------------------
void TGPIB_HP_E3631A::PowerOff(void)
{
  Send(":OUTPUT OFF");
}
//------------------------------------------------------------------------------
bool TGPIB_HP_E3631A::DeviceResponds()
{
  std::string GoodResult = "HEWLETT-PACKARD,E3631A";
  std::string Result = SendAndReceive("*IDN?").SetLength (GoodResult.Length());
  return (Result == GoodResult);
}
//------------------------------------------------------------------------------
void TGPIB_HP_E3631A::SetVoltage (TSupplyChannel Channel, float Voltage, float CurrentLimit)
{
  DecimalSeparator = '.';
  std::string cmd = "APPL " + ChannelToString(Channel) + ", "
                           + FloatToStrF(Voltage, ffFixed, 7,3) + ", "
                           + FloatToStrF(CurrentLimit, ffFixed, 7,3);
  Send (cmd.c_str());
}
//------------------------------------------------------------------------------
double TGPIB_HP_E3631A::MeasureCurrent (TSupplyChannel Channel, TCurrentUnit Unit)
{
  double current;

  std::string cmd = ":MEASURE:CURRENT:DC? " + ChannelToString(Channel);
  bool DS;
  DS = (DecimalSeparator == ','); // check for proper conversion separator

  if(DS) // change
  	DecimalSeparator = '.';
  current = SendAndReceive(cmd.c_str()).ToDouble(); // convert
  if(DS) // restore
  	DecimalSeparator = ',';

  switch (Unit) {
   case MILLIAMP: current *= 1e3; break;
   case MICROAMP: current *= 1e6; break;
   case NANOAMP:  current *= 1e9; break;
   default:                       break;
  }

  return current;
}
//------------------------------------------------------------------------------
double TGPIB_HP_E3631A::MeasureVoltage (TSupplyChannel Channel, TVoltageUnit Unit)
{
  double voltage;

  std::string cmd = ":MEASURE:VOLTAGE:DC? " + ChannelToString(Channel);
  bool DS;
  DS = (DecimalSeparator == ','); // check for proper conversion separator

  if(DS) // change
  	DecimalSeparator = '.';
  voltage = SendAndReceive(cmd.c_str()).ToDouble(); // convert
  if(DS) // restore
  	DecimalSeparator = ',';

  switch (Unit) {
   case MILLIVOLT: voltage *= 1e3; break;
   case MICROVOLT: voltage *= 1e6; break;
   default:                       break;
  }

  return voltage;
}
//------------------------------------------------------------------------------
double TGPIB_HP_E3631A::GetVoltageSet (TSupplyChannel Channel, TVoltageUnit Unit)
{
  double voltage;

  std::string cmd = "INST:SEL "+ ChannelToString(Channel) + ";:VOLTAGE? ";
  bool DS;
  DS = (DecimalSeparator == ','); // check for proper conversion separator

  if(DS) // change
  	DecimalSeparator = '.';
  voltage = SendAndReceive(cmd.c_str()).ToDouble(); // convert
  if(DS) // restore
  	DecimalSeparator = ',';

  switch (Unit) {
   case MILLIVOLT: voltage *= 1e3; break;
   case MICROVOLT: voltage *= 1e6; break;
   default:                       break;
  }

  return voltage;
}
//------------------------------------------------------------------------------
double TGPIB_HP_E3631A::GetCurrentSet (TSupplyChannel Channel, TCurrentUnit Unit)
{
  double current;

  std::string cmd = "INST:SEL "+ ChannelToString(Channel) + ";:CURRENT? ";
  bool DS;
  DS = (DecimalSeparator == ','); // check for proper conversion separator

  if(DS) // change
  	DecimalSeparator = '.';
  current = SendAndReceive(cmd.c_str()).ToDouble(); // convert
  if(DS) // restore
  	DecimalSeparator = ',';

  switch (Unit) {
   case MILLIAMP: current *= 1e3; break;
   case MICROAMP: current *= 1e6; break;
   case NANOAMP:  current *= 1e9; break;
   default:                       break;
  }

  return current;
}
//------------------------------------------------------------------------------
bool TGPIB_HP_E3631A::Power()
{
	std::string cmd = "OUTPUT?";
	cmd = SendAndReceive(cmd);
  return cmd =="1";
}
//------------------------------------------------------------------------------


