//---------------------------------------------------------------------------
#ifndef Silib_GPIB_Agi_81130AH
#define Silib_GPIB_Agi_81130AH
//---------------------------------------------------------------------------
#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"
#include "Bitstream.h"
#include <stdlib.h> 	// for _lrand
#include <math.h>
#include <vector.h>

const int GPIB_ID_Agi_81130A = 4;
const int Agi_81130A_Sleep = 1000;

class TGPIB_Agi_81130A: public TGPIB_Device
{
public:
          TGPIB_Agi_81130A    (TGPIB_Interface * If, int id = GPIB_ID_Agi_81130A);

//void    DisableOutput      (void);
//void    EnableOutput       (void);

	void PrepareBitstreamMode();
  bool UseBitstream(Bitstream *UseThis);

  bool EquidistantSpacings(unsigned int highDur,
  	unsigned int period1,
    unsigned int period2 = 0);

  bool EquidistantRate(unsigned int highDur,
  	unsigned int &rate);

  bool PoissonMonoChromatic(unsigned int highDur,
  	unsigned int lowDur,
  	unsigned int rate);

  bool PoissonPolyChromatic(unsigned int lowDur,
  	int rate = -1);

  bool RandomizeSignal();

	// spectrum vectors for PoissonPolyChromatic:
  vector <int> highDuration; // set externally
  vector <int> partialRate;

  void SetOutputVoltage (float VHi, float VLo = 0);
  void SingleLineOutput (float VHi, float VLo = 0);
  void DualLineOutput (float VHi, float VLo = 0);
  void OutputOff();

  void    SetFrequency       (float freq);
	void    Trigger            (void);
	void    SetPeriod          (float sec);
	void 		SetPulseWidth			 (float sec);
	void 		SendString	       (std::string cmd);

	void    DisplayText        (std::string Message);
	void    DisplayOff         (void);
	void    DisplayOn          (void);

  double timebase; // [ns]
  bool	RandomizeOnFrameFlag; // used externally

  Bitstream pattern;

private:
   bool   DeviceResponds     ();           // Test if device responds

   unsigned int LastHighDur;
   unsigned int LastLowDur;
   int LastRate;
   int LastSignalType;

};


#endif
