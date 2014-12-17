#include <vcl.h>
#include "SILIB_GPIB_Agi_33250A.h"

#include <math.h>    // for fabs

TGPIB_Agi_33250A::TGPIB_Agi_33250A (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	MyName = "Agilent Pulser 33250A with ID = " + std::string (MyId);

	if (!DeviceResponds()) {
		Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
		MyIf->RemoveDevice(MyId);
	}

	Send("OUTPUT:LOAD 50");      // always set to 50 Ohm load
}

bool TGPIB_Agi_33250A::DeviceResponds()
{
	std::string GoodResult = "Agilent Technologies,33250A";
	std::string Result = SendAndReceive("*IDN?").SetLength (GoodResult.Length());

	return (Result == GoodResult);
}

/*
void TGPIB_HP_33120A::DisableOutput (void)
{
}

void TGPIB_HP_33120A::EnableOutput (void)
{
}
*/

void TGPIB_Agi_33250A::SetAmplitude (float volt)
{
	Send("SOURCE:VOLTAGE:OFFSET 0");
	Send("SOURCE:VOLTAGE:UNIT VPP");
	std::string Out;
	Out.sprintf("SOURCE:VOLTAGE %.6f", volt);
	Send(Out);
//	DecimalSeparator = '.';
//	Send("SOURCE:VOLTAGE " + FloatToStrF(volt, ffFixed, 6, 3));
}

void TGPIB_Agi_33250A::SetFrequency (float freq)
{
	std::string Out;
	Out.sprintf("SOURCE:FREQUENCY %.11f",freq);
	Send(Out);
//	Send("SOURCE:FREQUENCY " + std::string(freq));
}

void TGPIB_Agi_33250A::SetPeriod (float sec)
{
	std::string Out;
	Out.sprintf("PULSE:PERIOD %.11f",sec);
	Send(Out);
}

void TGPIB_Agi_33250A::SetPulseWidth (float sec)
{
	std::string Out;
	Out.sprintf("PULSE:WIDT %.11f",sec);
	Send(Out);
}

void TGPIB_Agi_33250A::SendString (std::string cmd)
{
	Send(cmd);
}

void TGPIB_Agi_33250A::DefineWave (int npoints, float * value)
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


void TGPIB_Agi_33250A::Trigger (void)
{
	Send("*TRG");
}

void TGPIB_Agi_33250A::DisplayText (std::string Msg)
{
	Send("DISPLAY:TEXT '" + Msg + "'");
//  Send("DISPLAY ON");
}

void TGPIB_Agi_33250A::DisplayOff (void)
{
	Send("DISPLAY:TEXT:CLEAR");
}



