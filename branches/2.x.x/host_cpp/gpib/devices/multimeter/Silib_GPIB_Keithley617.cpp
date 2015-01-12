#include "SILIB_GPIB_Keithley617.h"

//------------------------------------------------------------------------------
// Keithley 617 Multimeter
//------------------------------------------------------------------------------
// To do:
// - Start a new measurement if Measure... is called, do not return old
//   reading. (Test in slow mode!)
//------------------------------------------------------------------------------

TGPIB_Keithley617::TGPIB_Keithley617 (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
  MyName   = "Keithley Multimeter Type 617 with ID = " + std::string (MyId);
  DeviceStatus = UNKNOWN617;

  if (!DeviceResponds()) {
    Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
    MyIf = NULL;
  }
  else DevicePresent = true;
}

bool TGPIB_Keithley617::DeviceResponds()
{
  std::string GoodResult = "617", Result;
    for (int i=0;i<2;i++)
        {
         std::string StatusKeith = SendAndReceive("U0X");
         Result = StatusKeith.SubString(1, 3);
        }
  return (Result == GoodResult);
}

double TGPIB_Keithley617::MeasureVoltage  (TVoltageUnit Unit)
{  std::string Result;
   double voltage;
   Result = SendAndReceive ("B0X");
   DeviceStatus = GetMode (Result);

   if (DeviceStatus != VOLTAGEMODE617)       // configure for current measurement
     {
     Send("F0X");
     DeviceStatus = VOLTAGEMODE617;
     }
   Sleep(500);

   Result = SendAndReceive ("B0X");
   voltage = GetValue (Result);
   switch (Unit) {
     case MILLIVOLT: voltage *= 1e3; break;
     case MICROVOLT: voltage *= 1e6; break;
     default:                        break;
   }
   return voltage;

   /*

   Send(":INIT:CONT OFF");                 // set to single shot
   Send(":ABORT");                         // delete old triggers and data
   Send(":INIT");                          // trigger a measurement
   std::string Res = SendAndReceive(":SENSE:DATA:FRESH?");
   sscanf(Res.c_str(), "%lf", &voltage);

   switch (Unit) {
     case MILLIVOLT: voltage *= 1e3; break;
     case MICROVOLT: voltage *= 1e6; break;
     default:                        break;
   }
   return voltage;*/
}

double TGPIB_Keithley617::MeasureCurrent (TCurrentUnit Unit)
{
   std::string Result;
   double current;
   Result = SendAndReceive ("B0X");
   DeviceStatus = GetMode (Result);

   if (DeviceStatus != CURRENTMODE617)       // configure for current measurement
     {
     Send("F1X");
     DeviceStatus = CURRENTMODE617;
     }
   Sleep(500);

   Result = SendAndReceive ("B0X");
   current = GetValue (Result);

   switch (Unit) {
     case MILLIAMP: current *= 1e3; break;
     case MICROAMP: current *= 1e6; break;
     case NANOAMP:  current *= 1e9; break;
     default:                       break;
   }

    return current;
   /*

   Send(":INIT:CONT OFF");
   Send(":ABORT");
   Send(":INIT");
   std::string Res = SendAndReceive("F1x");
//   sscanf(Res.c_str(), "%lf", &current);

   switch (Unit) {
     case MILLIAMP: current *= 1e3; break;
     case MICROAMP: current *= 1e6; break;
     case NANOAMP:  current *= 1e9; break;
     default:                       break;
   }
   return current;/**/
}

/*void TGPIB_Keithley617::SetSpeed (TDeviceSpeed Speed)
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
}   */

void TGPIB_Keithley617::DisplayText (std::string Msg)
{     /*
  const int MAXLEN = 12;
  if (Msg.Length() > MAXLEN) Msg = Msg.SubString(0,MAXLEN);

  Send(":DISPLAY:TEXT:DATA \"" + Msg + "\"");
  Send(":DISPLAY:TEXT:STATE ON");/**/

}

void TGPIB_Keithley617::DisplayOff (void)
{
/*  Send(":DISPLAY:TEXT:STATE OFF");   */
}

void   TGPIB_Keithley617::TestSend (std::string Text)
{
 Send (Text);
}

std::string   TGPIB_Keithley617::TestSendAndReceive (std::string Send)
{
 return SendAndReceive (Send);
}

TDeviceStatus617 TGPIB_Keithley617::GetMode (std::string Result)
{
/*    std::string Mode;
    Mode = Result.SubString(1,4);*/
    if (Result.SubString(1,4) == "NDCA")
            return CURRENTMODE617;
    else if (Result.SubString(1,4) == "NDCV")
            return VOLTAGEMODE617;
    else return UNKNOWN617;

}

double TGPIB_Keithley617::GetValue (std::string Result)
{

    return  Result.SubString(5, 12).ToDouble();

}
