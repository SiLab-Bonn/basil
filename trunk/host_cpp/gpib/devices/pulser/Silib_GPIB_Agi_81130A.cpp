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

#include "Silib_GPIB_Agi_81130A.h"

//---------------------------------------------------------------------------

#pragma package(smart_init)


TGPIB_Agi_81130A::TGPIB_Agi_81130A (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	MyName = "Agilent Pulser 81130A with ID = " + std::string (MyId);

	if (!DeviceResponds())
  {
		Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
		MyIf->RemoveDevice(MyId);
	}
  //itimeout(If->MyDevHndl[id], 2000);         // some commands take really long!

  timebase = 1; // default value: timebase = 1 ns
  RandomizeOnFrameFlag = false;

  LastHighDur = 0;
  LastLowDur = 0;
  LastRate = 0;
  LastSignalType = -1;

	pattern.Clear();
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::DeviceResponds()
{
	std::string GoodResult = "HEWLETT-PACKARD,HP81130A,DE41A01441,REV 01.11.00";
	std::string Result = SendAndReceive("*IDN?").SetLength (GoodResult.Length());

	return (Result == GoodResult);
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::PrepareBitstreamMode ()
{ // configures pulses for 1Gbps pulse stream output


	Send("CHANnel:MATH DIGital"); // enables channel addition
	Send("DIGital:PATTern ON"); // enables digital pattern mode
  Send("DIGital:PATTern:SEGMent2:LENGth 0");// delete segment 2
  Send("DIGital:PATTern:SEGMent3:LENGth 0");// delete segment 3
  Send("DIGital:PATTern:SEGMent4:LENGth 0");// delete segment 4
	Send("DIGital:PATTern:SEGMent1:LENGth 65504");// default: maximum length
  Send("DIGital:SIGNal1:FORMat RZ"); // return to zero pulse mode on chan. 1
  Send("DIGital:SIGNal2:FORMat RZ"); // return to zero pulse mode on chan. 2
	Send("TRIGger:SOURce INT"); // select internal oscillator
  Send("PHASe1 0");	// phase delay channel 1
  Send("PHASe2 180");// phase delay channel 2
  Send("PULSe:DELay1:HOLD PRAT"); // constant phase delay
  Send("PULSe:DELay2:HOLD PRAT"); // constant phase delay
  Send("PULSe:DCYC1 50PCT"); // 50% duty cycle channel 1
  Send("PULSE:HOLD1 DCYC"); // use duty cycle
  Send("PULSe:DCYC2 50PCT"); // 50% duty cycle channel 2
  Send("PULSE:HOLD2 DCYC"); // use duty cycle
  Send("FREQuency 500MHz"); // set base frequency
  Send("HOLD VOLT");// set output voltage
/*
  Send("VOLTage1:HIGH 2500MV");
  Send("VOLTage1:LOW 0V");
  Send("OUTPut1 ON"); // turn on channel 1 output (others remain off)
*/
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::UseBitstream(Bitstream *UseThis)
{// transfers given bitstream to the device pattern memory

	if(UseThis == NULL)
  	return false;

  int bitCount = UseThis->NrBits();

  // boundary check:
  if((bitCount<=0) || (bitCount>131008))
  	return false;

  // check if bitCount is multiple of 64:
  int tooMany = bitCount % 64;
  if(tooMany>0)// enlarge bitstream
  {
   	int newCount = 64*((bitCount/64)+1);
    UseThis->Resize(newCount, false); // without clear!
	  // update:
		bitCount = UseThis->NrBits();
  }
  // pattern length for pulser is half the bit count (x2 channels)
  int patternLength = bitCount/2;


  //prepare string for transmission:
  std::string Out;
  Out = "DIGital:PATTern:SEGment1:DATA #";

  // add length of the lenght of the data
  if(patternLength<100)
  	Out += "2";
  else if(patternLength<1000)
  	Out += "3";
  else if(patternLength<10000)
  	Out += "4";
  else
  	Out += "5";

  Out += std::string(patternLength); // Out now reads something like:
  // DIGital:PATTern:SEGment1:DATA #565504

  // add pattern data:
  for (int i=0; i<bitCount; i+=2)
  {
  	int val=0;
		if(UseThis->Get(i))
    	val = 1;
		if(UseThis->Get(i+1))
    	val += 2;
    Out += std::string(val);
  }
  // done. Submit data:
  Send(Out);

  // safety: wait some time.
//  Sleep(Agi_81130A_Sleep);
	return DeviceResponds();

//  return true;
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::PoissonMonoChromatic(unsigned int highDur,
  	unsigned int lowDur, unsigned int rate)
{// computes a monochromatic, Poisson-distributed signal. highDur and lowDur
// durations are given in timebase units (i.e. [ns]). rate is given in Hz.

	if(rate == 0)
  	return false;

	double duration = 131008; // max duration: 131 us
	double tau = 1.E9 /(timebase *  double (rate)); // tau in timebase units

  unsigned int time = 0; // time measured in timebase units
  unsigned int length = duration * timebase;

  if (length>131008)
  	return false;

  if(length < (highDur + lowDur))
  	return false;

	double normFactor = 1./double(LRAND_MAX+1); // normalization factor for _lrand


  pattern.Resize(length); // max length pattern
  pattern.Set(false); // all zero

  while (time < (length-(highDur+lowDur)))
  {
  	// insert pulse at current time marker
    for(unsigned int i=0; i<highDur; ++i)
    	pattern.Set(time+i, true);

    // compute random interval:
    double dt = 0;
    double r;
    while(dt<(highDur + lowDur))// too short, skip those
    {
			r = double(_lrand()+1) * normFactor; // r € 0}..1}
			dt = -log(r) * tau; // dt in timebase units, dt is positive.
    }
   	time += (unsigned int) floor(dt+0.5); // add rounded value of dt
/*
		double r = double(_lrand()+1) * normFactor; // r € 0}..1}
		double dt = -log(r) * tau; // dt in timebase units, dt is positive.

    if (dt<(highDur + lowDur)) // too short, can't do that.
    	time += highDur + lowDur;
    else
*/
  }// done.

 	// remeber these signal setting:
   LastHighDur = highDur;
   LastLowDur = lowDur;
   LastRate = rate;
   LastSignalType = 1; // 1 is poisson monochromatic

  // transmit:
 	return UseBitstream(&pattern);
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::PoissonPolyChromatic(unsigned int lowDur,
	int rate)
{// computes a polychromatic, Poisson-distributed signal based on the flux
// spectrum given in the highDuration and partialRate vectors. The total rate
// can be normalized by using a rate > 0. rate is given in Hz, lowDur in
// timebase units [ns]

	// check requirements: ----------------------------------------------------
  unsigned int size = highDuration.size();
  if ((partialRate.size() != size) || (size<1) || (rate == 0))
  	return false;

 	double sum = 0;

  // normalize flux, if desired: --------------------------------------------
  if(rate != -1)// -1 means: Keep defined fluxes!
  {
  	// compute sum
    for (unsigned int i=0; i<size; ++i)
    	sum += partialRate[i];

    if(sum <= 0)
    	return false;

    // normalize
    double scaleFactor = double(rate) / sum;
    for (unsigned int i=0; i<size; ++i)
    	partialRate[i] *= scaleFactor;
  }

  // prepare lookup table ---------------------------------------------------
  vector <double> fraction;

 	// compute sum ( yes, again. Might be != rate despite normalization (ints!))
  for (unsigned int i=0; i<size; ++i)
  	sum += partialRate[i];
  if(sum <= 0)
  	return false;

  double rateSoFar = 0;
  for (unsigned int i=0; i<size; ++i)
  {
  	rateSoFar += partialRate[i];
		fraction.push_back(rateSoFar / sum);
  }
  // now: fraction contains partitions of 1 correspeonding to individual rates.

  // compute pattern --------------------------------------------------------
	double duration = 131008; // max duration: 131 us
	double tau = 1.E9 /(timebase *  double (sum)); // tau in timebase units

  unsigned int time = 0; // time measured in timebase units
  unsigned int length = duration * timebase;

  if (length>131008)
  	return false;

  if(length < lowDur)
  	return false;

	double normFactor = 1./double(LRAND_MAX+1); // normalization factor for _lrand

  pattern.Resize(length); // max length pattern
  pattern.Set(false); // all zero

  while (time < length)
  {
  	// choose random energy:
		double r = double(_lrand()) * normFactor; // r € {0..1}
    // find corresponding index (=Energy):
    unsigned int E;
    for(E=0; E<size; ++E)
    	if(r<=fraction[E]) // this is it!
      	break;

  	// insert pulse at current time marker
    unsigned int tEnd = time + highDuration[E];
    if(tEnd > length)
    	tEnd = length;
    for(unsigned int i=time; i<tEnd; ++i)
    	pattern.Set(i, true);

    // compute random interval:
    double dt = 0;
    while(dt<(highDuration[E] + lowDur))// too short, skip those
    {
			r = double(_lrand()+1) * normFactor; // r € 0}..1}
			dt = -log(r) * tau; // dt in timebase units, dt is positive.
    }
   	time += (unsigned int) floor(dt+0.5); // add rounded value of dt
//    if (dt<(highDuration[E] + lowDur)) // too short, can't do that.
//    	time += highDuration[E] + lowDur;
//    else
  }// done.

 	// remeber these signal setting:
  LastHighDur = 0;
  LastLowDur = lowDur;
  LastRate = rate;
  LastSignalType = 2; // 2 is poisson polychromatic

  // transmit:
 	return UseBitstream(&pattern);
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::EquidistantSpacings(unsigned int highDur,
	unsigned int period1,	unsigned int period2)
{// computes a monochromatic signal. Pulses are either equidistant (period2 =0)
// or pair-wise equidistant (spacing: period1, period2, period1, period2,...).
// durations are given in timebase units (i.e. [ns]). rate is given in Hz.

	double duration = 131008; // max duration: 131 us

  unsigned int time = 0; // time measured in timebase units
  unsigned int length = duration * timebase;

  if (length>131008)
  	return false;

  if(highDur>period1)
  	return false;

  if((highDur>period2) && (period2 > 0))
  	return false;

  pattern.Resize(length); // max length pattern
  pattern.Set(false); // all zero

  while (time<length)
  {
  	if(time+highDur < length)
    {
		  // add first pulse:
		  for(unsigned int i=0; i<highDur; ++i)
  			pattern.Set(time+i, true);
      time += period1;
    }
    else
    	time = length;

  	if(time+highDur < length)
    {
		  if(period2>0)// add second pulse
      {
	  		for(unsigned int i=0; i<highDur; ++i)
		  		pattern.Set(time+i, true);
        time += period2;
      }
    }
    else
    	time = length;
  }
 	// remeber these signal setting:
   LastHighDur = 0;
   LastLowDur = 0;
   LastRate = 0;
   LastSignalType = 0; // 0 is equidistant

  // transmit:
 	return UseBitstream(&pattern);
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::EquidistantRate(unsigned int highDur, unsigned int &rate)
{// computes a monochromatic, equidistant signal of given pulse rate.
// highduration is given in timebase units (i.e. [ns]). rate is given in Hz.

	if((rate == 0) || (highDur == 0))
  	return false;

	double duration = 131008; // max duration: 131 us

  unsigned int time = 0; // time measured in timebase units
  unsigned int length = duration * timebase;

  if (length>131008)
  	return false;

	double period = 1.E9 / double(rate); // max duration: 131 us
  period = floor(period + 0.5); // round
  rate = 1.E9 / period; // return actual rate


  if ((length>131008) || (length < highDur))
  	return false;

  if(highDur>period)
  	return false;

  pattern.Resize(length); // max length pattern
  pattern.Set(false); // all zero

  while(time<(length-highDur))
	{// add pulse:
	  for(unsigned int i=0; i<highDur; ++i)
  		pattern.Set(time + i, true);
    time += period;
  }

 	// remeber these signal setting:
   LastHighDur = 0;
   LastLowDur = 0;
   LastRate = 0;
   LastSignalType = 0; // 0 is equidistant

  // transmit:
 	return UseBitstream(&pattern);
}
//---------------------------------------------------------------------------
bool TGPIB_Agi_81130A::RandomizeSignal()
{
  if(LastSignalType == 1)
  	return PoissonMonoChromatic(LastHighDur, LastLowDur, LastRate);
  if(LastSignalType == 2)
  	return PoissonPolyChromatic(LastHighDur, LastRate);

	return false; // no random signal was set!
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::SetOutputVoltage (float VHi, float VLo)
{
  Send("HOLD VOLT");// set output voltage
	std::string Out;
	Out.sprintf("VOLTage1:HIGH %.6f", VHi);
	Send(Out);
	Out.sprintf("VOLTage2:HIGH %.6f", VHi);
	Send(Out);
	Out.sprintf("VOLTage1:LOW %.6f", VLo);
	Send(Out);
	Out.sprintf("VOLTage2:LOW %.6f", VLo);
	Send(Out);
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::SingleLineOutput(float VHi, float VLo)
{
	SetOutputVoltage(VHi, VLo);

  Send("OUTPut1 ON");
  Send("OUTPut1:COMPlement OFF");
  Send("OUTPut2 OFF");
  Send("OUTPut2:COMPlement OFF");
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::DualLineOutput(float VHi, float VLo)
{
	SetOutputVoltage(VHi, VLo);

  Send("OUTPut1 ON");
  Send("OUTPut1:COMPlement ON");
  Send("OUTPut2 OFF");
  Send("OUTPut2:COMPlement OFF");
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::OutputOff()
{
  Send("OUTPut1 OFF");
  Send("OUTPut1:COMPlement OFF");
  Send("OUTPut2 OFF");
  Send("OUTPut2:COMPlement OFF");
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::SetFrequency (float freq)
{
	std::string Out;
	Out.sprintf("FREQUENCY %.11f",freq);
	Send(Out);
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::SetPeriod (float sec)
{
	std::string Out;
	Out.sprintf("PULSE:PERIOD %.11f",sec);
	Send(Out);
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::SetPulseWidth (float sec)
{
	std::string Out;
	Out.sprintf("PULSE:WIDT %.11f",sec);
	Send(Out);
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::SendString (std::string cmd)
{
	Send(cmd);
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::Trigger (void)
{
	Send("*TRG");
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::DisplayText (std::string Msg)
{
	Send("DISPLAY:TEXT '" + Msg + "'");
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::DisplayOff (void)
{
	Send("DISPlay OFF"); // increases programming speed
}
//---------------------------------------------------------------------------
void TGPIB_Agi_81130A::DisplayOn (void)
{
	Send("DISPlay ON");
}
//---------------------------------------------------------------------------


