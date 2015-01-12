#ifndef SILIB_GPIB_Keithley2000_H
#define SILIB_GPIB_Keithley2000_H

#include <stdio.h>
#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

const int GPIB_ID_K2000 = 16;

#ifndef KEITHLEY
#define KEITHLEY
enum TDeviceStatus {UNKNOWN, VOLTAGEMODE, CURRENTMODE};
enum TDeviceSpeed  {FAST, MEDIUM, SLOW};
enum TDeviceRange  {AUTO};
#endif // KEITHLEY


class TGPIB_Keithley2000: public TGPIB_Device
{
public:
          TGPIB_Keithley2000 (TGPIB_Interface * If, int id = GPIB_ID_K2000);

   double MeasureCurrent     (TCurrentUnit Unit = MILLIAMP);
   double MeasureVoltage     (TVoltageUnit Unit = VOLT);
   void   SetSpeed           (TDeviceSpeed Speed);
   void   SetRange           (TDeviceRange Range);

   void   DisplayText        (std::string Message);
   void   DisplayOff         (void);

private:
   bool   DeviceResponds     ();           // Test if device responds
   TDeviceStatus DeviceStatus;             // Remember setting of Multimeter
};

#endif
