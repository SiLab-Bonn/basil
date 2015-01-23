#ifndef SILIB_GPIB_Keithley24xx_H
#define SILIB_GPIB_Keithley24xx_H

#include "Silib_GPIB_Device.h"
#include "Silib_GPIB_Interfaces.h"

const int GPIB_ID_K24xx = 10;

#ifndef KEITHLEY
#define KEITHLEY
enum TDeviceStatus {UNKNOWN, VOLTAGEMODE, CURRENTMODE};
enum TDeviceSpeed  {FAST, MEDIUM, SLOW};
enum TDeviceRange  {AUTO};
#endif // KEITHLEY

class TGPIB_Keithley24xx: public TGPIB_Device
{
public:
          TGPIB_Keithley24xx (TGPIB_Interface * If, int id = GPIB_ID_K24xx);
          ~TGPIB_Keithley24xx ();

   void   SetCurrentRange1mA (void);
	 void   SetSourceType(int mode);

   void   SetVoltage         (double voltage, double maxcurrent=0);
   void   SetCurrent         (double current, double maxvoltage=0);
   void   Measure            (double &current, double &voltage, TVoltageUnit VoltUnit = VOLT, TCurrentUnit CurrUnit = AMP);

   // void   SweepVoltage       (double Start, double Stop, int N);

   void   SwitchOff();
   void 	SwitchOn();

   void   SetSpeed           (TDeviceSpeed Speed);
   // void   SetRange           (TDeviceRange Range);

   void   DisplayText        (std::string Message);
   void   DisplayOff         (void);
   bool   DeviceResponds     ();           // Test if device responds
	 
	 void   Set4WireSense(bool on_off);

   TDeviceStatus DeviceStatus;             // Remember setting of Multimeter
};

#endif
