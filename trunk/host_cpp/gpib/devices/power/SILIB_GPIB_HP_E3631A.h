#ifndef SILIB_GPIB_HP_E3631A_H
#define SILIB_GPIB_HP_E3631A_H

#include "SILIB_GPIB_Device.h"
#include <vcl.h>
const int HP_E3631A = 3;

enum TSupplyChannel {P6V, P25V, N25V};



class TGPIB_HP_E3631A: public TGPIB_Device
{
public:
          TGPIB_HP_E3631A (TGPIB_Interface * If, int id = HP_E3631A);

   void   PowerOn         (void);
   void   PowerOff        (void);
   bool 	Power						();

   void   SetVoltage      (TSupplyChannel Channel, float Voltage, float CurrentLimit);
   double GetCurrentSet		(TSupplyChannel Channel, TCurrentUnit Unit = AMP);
   double GetVoltageSet		(TSupplyChannel Channel, TVoltageUnit Unit = VOLT);
   double MeasureCurrent  (TSupplyChannel Channel, TCurrentUnit Unit = AMP);
   double MeasureVoltage  (TSupplyChannel Channel, TVoltageUnit Unit = VOLT);

   void   DisplayText     (std::string Message);
   void   DisplayOff      (void);

private:
   bool   DeviceResponds  ();                        // Test if device responds
   std::string ChannelToString (TSupplyChannel Channel);
};

#endif
