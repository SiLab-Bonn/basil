//---------------------------------------------------------------------------
// precompiled headers - for faster comilation
#ifdef USE_GLOBALS
	#include "Globals.h"
#else
	#ifdef USE_INVISIBLE_GLOBALS
		#include <Globals.h>
		// globals.h has to be included in Include search path (project options)
		// for this to work, doesn't show overcrowded class explorer
	#endif
#endif
#pragma hdrstop

#include "SILIB_GPIB_HP_81104A.h"

#include <math.h>    // for fabs

TGPIB_HP_81104A::TGPIB_HP_81104A (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	MyName = "Hewlett Packard Pulser 81104A with ID = " + std::string (MyId);

	if (!DeviceResponds())
  {
  	isOk = false;
		MyIf->RemoveDevice(MyId);
	}

	//Send("OUTPUT:LOAD 50");      // always set to 50 Ohm load
      
}

bool TGPIB_HP_81104A::DeviceResponds()
{
	std::string GoodResult = "HEWLETT-PACKARD,HP8110";
	std::string Result = SendAndReceive("*IDN?").SetLength (GoodResult.Length());

	return (Result == GoodResult);
}


void TGPIB_HP_81104A::SetAmplitude (float volt)
{
	Send("SOURCE:VOLTAGE:OFFSET 0");
	std::string Out;
	Out.sprintf("SOURCE:VOLTAGE %.6f V", volt);
	Send(Out);
}

void TGPIB_HP_81104A::SetFrequency (float freq)
{
	std::string Out;
	Out.sprintf("SOURCE:FREQUENCY %.11f",freq);
	Send(Out);
//	Send("SOURCE:FREQUENCY " + std::string(freq));
}

void TGPIB_HP_81104A::SetPeriod (float sec)
{
	std::string Out;
	Out.sprintf("PULSE:PERIOD %.11f",sec);
	Send(Out);
}

void TGPIB_HP_81104A::SetPulseWidth (float sec)
{
	std::string Out;
	Out.sprintf("PULSE:WIDT %.11f",sec);
	Send(Out);
}

void TGPIB_HP_81104A::SendString (std::string cmd)
{
	Send(cmd);
}

void TGPIB_HP_81104A::DefineWave (int npoints, float * value)
{
	std::string ValString = "";

	for (int i=0; i<npoints; i++) {
		float val = value[i];
		if (fabs(val) > 1.0) {
			ErrorMsg("DefineWave: Amplitude out of range");
			return;
		}
		ValString += "," + FloatToStrF(val, ffFixed, 7, 4);
	}

	Send("DATA VOLATILE" + ValString);          // Download the waveform

	Send("SOURCE:BM:NCYCLES 1");                // select single burst mode
	Send("SOURCE:BM:PHASE 0");
	Send("SOURCE:BM:STATE ON");

	Send("SOURCE:FUNCTION:USER VOLATILE");      // set user to the waveform in volatile RAM
	Send("SOURCE:FUNCTION:SHAPE USER");         // use the user waveform

	Send("TRIGGER:SOURCE BUS");                 // We trigger through GPIB
}


void TGPIB_HP_81104A::Trigger (void)
{
	Send("*TRG");
}

void TGPIB_HP_81104A::DisplayText (std::string Msg)
{
	Send("DISPLAY:TEXT '" + Msg + "'");
//  Send("DISPLAY ON");
}

void TGPIB_HP_81104A::DisplayOff (void)
{
	Send(":DISP OFF");
}


void    TGPIB_HP_81104A::SetAmplitude (short channel, float volt)
{

	Send("SOURCE:VOLTAGE:OFFSET 0");
	std::string Out;
	Out.sprintf("SOURCE:VOLTAGE%d %.6f V",channel, volt);
	Send(Out);

}


void    TGPIB_HP_81104A::EnableOutput (short channel)
{
if (channel <3&&channel>0)
   {
   std::string Out;
   Out.sprintf("OUTP%d on", channel);
   Send(Out);
   }
}

void    TGPIB_HP_81104A::DisableOutput (short channel)
{
if (channel <3&&channel>0)
   {
   std::string Out;
   Out.sprintf("OUTP%d off", channel);
   Send(Out);
   }
}


void    TGPIB_HP_81104A::SetHighVoltage     (short channel, float volt)
{
std::string Out;
Out.sprintf("VOLT%d:HIGH %.6f V", channel, volt);
Send(Out);

}


void    TGPIB_HP_81104A::SetLowVoltage     (short channel, float volt)
{
std::string Out;
Out.sprintf("VOLT%d:LOW %.6f V", channel, volt);
Send(Out);
}


// SetMode ist noch unvollständig!!!
// Bisher nur CONT, INTERN und TRIG, EXTERN getestet!

void    TGPIB_HP_81104A::SetTrigMode (Modi modus, TrigSource source)
{
 std::string Out;


 switch (modus)
 {
  case CONT:
       Out.sprintf(":ARM:SOUR IMM");
       Send(Out);
       break;
  case TRIG:
       Out.sprintf(":ARM:SOUR EXT");
       Send(Out);
       Out.sprintf(":ARM:SENS EDGE");
       Send(Out);
       break;
  case GATE:
       Out.sprintf(":ARM:SOUR EXT");
       Send(Out);
       Out.sprintf(":ARM:SENS LEV");
       Send(Out);
       break;
  case EXTW:
       Out.sprintf(":ARM:EWIDT ON");
       Send(Out);
       return;
 }


 switch (source)     //Achtung hier noch Baustelle!!!
 {
  case PLL:
    if (modus!=CONT)
    Out.sprintf(":ARM:SOUR INT2");
    else
    Out.sprintf(":TRIG:SOUR INT2");
    Send(Out);
    break;
  case MAN:
    Out.sprintf(":ARM:SOUR MAN");
    Send(Out);
    break;
  case INTERN:
    Out.sprintf(":TRIG:SOUR IMM");
    Send(Out);
    break;
  default:
  break;
 }


}


void    TGPIB_HP_81104A::SetPulseWidth (short channel, float width)
{
std::string Out;
Out.sprintf(":PULS:WIDT%d %.9f S", channel, width);
Send(Out);
}


void    TGPIB_HP_81104A::SetPulseDelay (short channel, float delay)
{
std::string Out;
Out.sprintf(":PULS:DEL%d %.11f S", channel, delay);
Send(Out);

}

void    TGPIB_HP_81104A::SetExtInpImpedance (int ohm)
{
std::string Out;
Out.sprintf(":ARM:IMP %d OHM", ohm);
Send(Out);

}



void    TGPIB_HP_81104A::SetExtInpLevel (float volt)
{
std::string Out;
Out.sprintf(":ARM:LEV %.6f V", volt);
Send(Out);

}

void    TGPIB_HP_81104A::SetOutputImpedance(short channel, int ohm)
{
std::string Out;
Out.sprintf(":OUTP%d:IMP %d OHM", channel, ohm);
Send(Out);

}


void    TGPIB_HP_81104A::SetLeadingEdge (short channel, float sec)
{
std::string Out;
Out.sprintf(":PULS:TRAN%d:LEAD %.12f S", channel, sec);
Send(Out);
}
