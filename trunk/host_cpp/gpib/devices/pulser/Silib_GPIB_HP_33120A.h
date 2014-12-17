#ifndef SILIB_GPIB_HP_33120A_H
#define SILIB_GPIB_HP_33120A_H

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

const int GPIB_ID_HP_33120A = 11;


class TGPIB_HP_33120A: public TGPIB_Device
{
public:
          TGPIB_HP_33120A    (TGPIB_Interface * If, int id = GPIB_ID_HP_33120A);

//void    DisableOutput      (void);
//void    EnableOutput       (void);
  
  void    SetAmplitude       (float volt);
  void    SetFrequency       (float freq);
  void    DefineWave         (int   npoints, float * value);
  void    Trigger            (void);

  void    DisplayText        (std::string Message);
  void    DisplayOff         (void);

private:
   bool   DeviceResponds     ();           // Test if device responds
};

#endif
