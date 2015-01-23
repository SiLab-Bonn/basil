//---------------------------------------------------------------------------

#ifndef Silib_GPIB_HP_81104AH
#define Silib_GPIB_HP_81104AH
//---------------------------------------------------------------------------
#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

const int GPIB_ID_HP_81104A = 2;

enum Modi {CONT, TRIG, GATE, EXTW};
enum TrigSource {INTERN, PLL, MAN, EXT};

class TGPIB_HP_81104A: public TGPIB_Device
{
public:
          TGPIB_HP_81104A    (TGPIB_Interface * If, int id = GPIB_ID_HP_81104A);

 void    DisableOutput      (short channel);
 void    EnableOutput       (short channel);

  void    SetAmplitude       (float volt);
  void    SetAmplitude       (short channel, float volt);

  void    SetHighVoltage     (short channel, float volt);
  void    SetLowVoltage     (short channel, float volt);

  void    SetTrigMode (Modi modus, TrigSource source);

  void    SetPulseWidth      (short channel, float width);
  void    SetPulseDelay      (short channel, float delay);

  void    SetExtInpImpedance (int ohm);
  void    SetExtInpLevel (float volt);

  void    SetOutputImpedance(short channel, int ohm);

  void    SetLeadingEdge (short channel, float sec);


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
