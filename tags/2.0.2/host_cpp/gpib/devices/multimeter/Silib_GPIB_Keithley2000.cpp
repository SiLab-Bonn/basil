#include <sstream>
#include <stdlib.h>

#include "SILIB_GPIB_Keithley2000.h"

//------------------------------------------------------------------------------
// Keithley 2000 Multimeter
//------------------------------------------------------------------------------
// To do:
// - Start a new measurement if Measure... is called, do not return old
//   reading. (Test in slow mode!)
//------------------------------------------------------------------------------

TGPIB_Keithley2000::TGPIB_Keithley2000 (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	std::stringstream ss;

	ss << "Keithley Multimeter Type 2000 with ID = " << (int)MyId;

  MyName   = ss.str() ;
  DeviceStatus = UNKNOWN;

  if (!DeviceResponds()) {
    ErrorMsg("Device does not respond!");
    MyIf = NULL;
  }
}

bool TGPIB_Keithley2000::DeviceResponds()
{
  std::string GoodResult = "KEITHLEY INSTRUMENTS INC.,MODEL 2000";
  std::string Result = SendAndReceive("*IDN?");
  return (Result == GoodResult);
}

double TGPIB_Keithley2000::MeasureVoltage  (TVoltageUnit Unit)
{
   double voltage;

   if (DeviceStatus != VOLTAGEMODE) {      // configure for voltage measurement
     Send(":SENSE:FUNC 'VOLT:DC'");
     DeviceStatus = VOLTAGEMODE;           // flag new status
   }

/* This seems to do something strange to the instrument
   Send(":INIT:CONT OFF");                 // set to single shot
   Send(":ABORT");                         // delete old triggers and data
   Send(":INIT");                          // trigger a measurement
*/
   std::string Res = SendAndReceive(":SENSE:DATA:FRESH?");
   sscanf(Res.c_str(), "%lf", &voltage);

   switch (Unit) {
     case MILLIVOLT: voltage *= 1e3; break;
     case MICROVOLT: voltage *= 1e6; break;
     default:                        break;
   }
   return voltage;
}

double TGPIB_Keithley2000::MeasureCurrent (TCurrentUnit Unit)
{
   double current;

   if (DeviceStatus != CURRENTMODE) {      // configure for current measurement
     Send(":SENSE:FUNC 'CURR:DC'");
     DeviceStatus = CURRENTMODE;
   }

/* This seems to do something strange to the instrument
   Send(":INIT:CONT OFF");                 // set to single shot
   Send(":ABORT");                         // delete old triggers and data
   Send(":INIT");                          // trigger a measurement
*/
   std::string Res = SendAndReceive(":SENSE:DATA:FRESH?");
   sscanf(Res.c_str(), "%lf", &current);

   switch (Unit) {
     case MILLIAMP: current *= 1e3; break;
     case MICROAMP: current *= 1e6; break;
     case NANOAMP:  current *= 1e9; break;
     default:                       break;
   }
   return current;
}

void TGPIB_Keithley2000::SetSpeed (TDeviceSpeed Speed)
{
  switch (Speed) {
    case FAST:
      Send (":SENSE:VOLTAGE:NPLC 0.1");
      Send (":SENSE:CURRENT:NPLC 0.1");
    break;
    case MEDIUM:
      Send (":SENSE:VOLTAGE:NPLC 1");
      Send (":SENSE:CURRENT:NPLC 1");
    break;
    case SLOW:
      Send (":SENSE:VOLTAGE:NPLC 10");
      Send (":SENSE:CURRENT:NPLC 10");
    break;
    default: break;
  }
}

void TGPIB_Keithley2000::DisplayText (std::string Msg)
{
  const int MAXLEN = 12;
  if (Msg.size() > MAXLEN) Msg = Msg.substr(0,MAXLEN);

  Send(":DISPLAY:TEXT:DATA \"" + Msg + "\"");
  Send(":DISPLAY:TEXT:STATE ON");

}

void TGPIB_Keithley2000::DisplayOff (void)
{
  Send(":DISPLAY:TEXT:STATE OFF");
}

