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

#include "SILIB_GPIB_Keithley24xx.h"

//------------------------------------------------------------------------------
// Keithley 24xx SMU
//------------------------------------------------------------------------------
// To do:
//------------------------------------------------------------------------------

TGPIB_Keithley24xx::TGPIB_Keithley24xx (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	std::stringstream ss;
	ss << "Keithley Sourcemeter Type 24xx with ID = " << (int)MyId;
  MyName   = ss.str();
  Send("*RST");
  if (!DeviceResponds()) {
		isOk = false;
    MyIf = NULL;
    return;
  }

// Initilize Source and set to 0V, 0.1mA limit
	Send(":SOUR:FUNC:MODE VOLT");
	DeviceStatus = VOLTAGEMODE;
	Send(":SOUR:VOLT:MODE FIXED");
	Send(":SOUR:VOLT:RANG:AUTO ON");
	Send(":SOUR:VOLT:LEV:IMM 0");
	Send(":SENSE:CURR:PROT 0.0001");

// Measure only current and voltage
  Send(":SENS:FUNC:CONC ON");
  Send(":SENS:FUNC:OFF:ALL");
  Send(":SENS:FUNC:ON  'VOLT:DC','CURR:DC'");
  Send(":SENS:AVER:STAT OFF");

// Only Output voltage and current
  Send(":FORM:DATA ASCII");
  Send(":FORM:ELEM VOLT,CURR");

// Switch off beeper
	Send(":SYST:BEEP:STAT OFF");

// Output on
//  Send(":OUTP ON");

}
//---------------------------------------------------------------------------
TGPIB_Keithley24xx::~TGPIB_Keithley24xx()
{
	if (isOk)
    SwitchOff();

	 std::locale usa_locale("American_USA.1252");  // decimal separator style
}
//---------------------------------------------------------------------------
bool TGPIB_Keithley24xx::DeviceResponds()
{
	std::string GoodResult = "KEITHLEY INSTRUMENTS INC.,MODEL 24";
	std::string Result = SendAndReceive("*IDN?");
	Result = Result.substr(0, GoodResult.size());
	return (Result == GoodResult);
}

void TGPIB_Keithley24xx::SetSourceType(int mode)
{
	if (mode == VOLTAGEMODE)
	{
		DeviceStatus = VOLTAGEMODE;
		Send(":SOUR:FUNC:MODE VOLT");    // voltagemode
		Send(":SOUR:VOLT:MODE FIXED");   // DC output
		Send(":SOUR:VOLT:RANG:AUTO ON"); // auto ranging
		Send(":SOUR:VOLT:LEVEL:IMM 0");	 // output level
	}
	if (mode == CURRENTMODE)
	{
		DeviceStatus = CURRENTMODE;
		Send(":SOUR:FUNC:MODE CURR");
		Send(":SOUR:CURR:MODE FIXED");
		Send(":SOUR:CURR:RANG:AUTO ON");
		Send(":SOUR:CURR:LEVEL:IMM 0");		
	}
}

void TGPIB_Keithley24xx::Set4WireSense(bool on_off)
{
	if (on_off)
		Send(":SYST:RSEN ON");
	else
		Send(":SYST:RSEN OFF");
}


//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::SetVoltage (double voltage, double maxcurrent)
{
 std::stringstream ss;


// char DS = DecimalSeparator;
// DecimalSeparator = '.';
 if (DeviceStatus != VOLTAGEMODE) 
 {
	 return;
/*
		Send(":SOUR:FUNC:MODE VOLT");
		DeviceStatus = VOLTAGEMODE;
		Send(":SOUR:VOLT:MODE FIXED");
*/
 }
	if (maxcurrent!=0) 
	{
		ss.str("");
		ss << ":SENSE:CURR:PROT " << maxcurrent;
		Send(ss.str());
	}
	Send(":SOUR:VOLT:RANG:AUTO ON");
	ss.str("");
	ss << ":SOUR:VOLT:LEV:IMM:AMPL " << voltage;
	Send(ss.str());
//	Send(":OUTP ON");
//	DecimalSeparator = DS;
}
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::SetCurrent (double current, double maxvoltage)
{// current given in AMPERE!
//	char temp = DecimalSeparator;
//	DecimalSeparator = '.';
  std::stringstream ss;

	if (DeviceStatus != CURRENTMODE) 
	{
		return;
/*
		Send(":SOUR:FUNC:MODE CURR");
		DeviceStatus = CURRENTMODE;
		Send(":SOUR:CURR:MODE FIXED");
		Send(":SOUR:VOLT:LEVEL:IMM 0");
		Send(":SOUR:CURR:RANG:AUTO ON");
*/
	}
	if (maxvoltage!=0)
	{
		ss.str("");
		ss << ":SENSE:VOLT:PROT " << maxvoltage;
		Send(ss.str());
	}
	Send(":SOUR:CURR:RANG:AUTO ON");
	ss.str("");
	ss << ":SOUR:CURR:LEV:IMM:AMPL " << current;
	Send(ss.str());
//	Send(":OUTP ON");
//  DecimalSeparator = temp;
}
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::Measure(double &current, double &voltage, TVoltageUnit VoltUnit, TCurrentUnit CurrUnit)
{
  std::string Res = SendAndReceive(":READ?");

  if (Res != "Error" && Res != "") {
    voltage = atof(Res.substr(0,13).c_str());
    current = atof(Res.substr(14,13).c_str());    
  };

  switch (CurrUnit) {
    case AMP:                      break;
    case MILLIAMP: current *= 1e3; break;
    case MICROAMP: current *= 1e6; break;
    case NANOAMP:  current *= 1e9; break;
    default:                       break;
  }

  switch (VoltUnit) {
    case VOLT:                      break;
    case MILLIVOLT: voltage *= 1e3; break;
    case MICROVOLT: voltage *= 1e6; break;
    default:                        break;
  }
}
//---------------------------------------------------------------------------
/*
void TGPIB_Keithley24xx::SweepVoltage (double * Volt, double * Curr, double Start, double Stop, int N)
{

  Send("*RST");
  Send(":SOUR:FUNC:MODE VOLT");
  Send(":SOUR:VOLT:MODE FIXED");
  Send(":SOUR:VOLT:RANG 2.0");
  Send(":SENSE:CURR:PROT 0.001");

  Send(":SENS:FUNC:Conc Off");
  Send(":SENS:FUNC 'Curr:DC'");
  Send(":FORM:ELEM Curr");

  Send(":SOUR:VOLT:LEVEL:IMM " + std::string(Start));
  Send(":OUTP ON");

  double step = (N==1) ? 0 : (Stop-Start) / (double) (N-1);
  for (int i=0; i<N; i++) {
    double v = Start + i * step;
    Send(":SOUR:VOLT:LEVEL:IMM " + std::string(v));
    std::string Res = SendAndReceive(":READ?");
    Volt[i] = v;
    Curr[i] = Res.ToDouble();
  }
  Send(":OUTP OFF");
}
*/
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::SetSpeed (TDeviceSpeed Speed)
{
  switch (Speed) {
    case FAST:
      Send (":SENSE:VOLTAGE:NPLC 0.1");
      Send (":SENSE:CURRENT:NPLC 0.1");
    break;
    case MEDIUM:
      Send (":SENSE:VOLTAGE:NPLC 1");
      Send (":SENSE:CURRENT:NPLC 1");
    break;
    case SLOW:
      Send (":SENSE:VOLTAGE:NPLC 10");
      Send (":SENSE:CURRENT:NPLC 10");
    break;
    default: break;
  }
}
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::DisplayText (std::string Msg)
{
  const int MAXLEN = 12;
  if (Msg.length() > MAXLEN) Msg = Msg.substr(0,MAXLEN);

  Send(":DISPLAY:TEXT:DATA \"" + Msg + "\"");
  Send(":DISPLAY:TEXT:STATE ON");

}
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::DisplayOff (void)
{
  Send(":DISPLAY:TEXT:STATE OFF");
}
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::SwitchOff (void)
{
  Send(":OUTP OFF");
}
//---------------------------------------------------------------------------
void TGPIB_Keithley24xx::SwitchOn (void)
{
  Send(":OUTP ON");
}
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------
//---------------------------------------------------------------------------

