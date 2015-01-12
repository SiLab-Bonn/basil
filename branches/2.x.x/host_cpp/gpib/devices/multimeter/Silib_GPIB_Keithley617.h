#ifndef SILIB_GPIB_Keithley617_H
#define SILIB_GPIB_Keithley617_H

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

const int GPIB_ID_K617 = 17;

enum TDeviceStatus617 {UNKNOWN617, VOLTAGEMODE617, CURRENTMODE617};


class TGPIB_Keithley617: public TGPIB_Device
{
public:
          TGPIB_Keithley617 (TGPIB_Interface * If, int id = GPIB_ID_K617);

   double MeasureCurrent     (TCurrentUnit Unit = MILLIAMP);
   double MeasureVoltage     (TVoltageUnit Unit = VOLT);
//   void   SetSpeed           (TDeviceSpeed Speed);
//   void   SetRange           (TDeviceRange Range);

   void   DisplayText        (std::string Message);
   void   DisplayOff         (void);
   void   TestSend (std::string Text);
   std::string TestSendAndReceive (std::string Send);
   double GetValue (std::string Result);
private:
   bool   DeviceResponds     ();           // Test if device responds
   TDeviceStatus617 DeviceStatus;             // Remember setting of Multimeter
   TDeviceStatus617 GetMode ( std::string Result);

};

class EReadbackError
{
 public : EReadbackError() {};
};

#endif
