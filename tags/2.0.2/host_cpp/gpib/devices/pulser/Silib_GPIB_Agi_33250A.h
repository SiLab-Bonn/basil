//---------------------------------------------------------------------------

#ifndef Silib_GPIB_Agi_33250AH
#define Silib_GPIB_Agi_33250AH
//---------------------------------------------------------------------------
#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

const int GPIB_ID_Agi_33250A = 2;


class TGPIB_Agi_33250A: public TGPIB_Device
{
public:
          TGPIB_Agi_33250A    (TGPIB_Interface * If, int id = GPIB_ID_Agi_33250A);

//void    DisableOutput      (void);
//void    EnableOutput       (void);

  void    SetAmplitude       (float volt);
  void    SetFrequency       (float freq);
  void    DefineWave         (int   npoints, float * value);
	void    Trigger            (void);
	void    SetPeriod          (float sec);
	void 		SetPulseWidth			 (float sec);
	void 		SendString	       (std::string cmd);

	void    DisplayText        (std::string Message);
	void    DisplayOff         (void);


private:
   bool   DeviceResponds     ();           // Test if device responds
};

#endif
