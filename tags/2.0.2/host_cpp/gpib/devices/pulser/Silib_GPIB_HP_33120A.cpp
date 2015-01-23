#include <vcl.h>
#include "SILIB_GPIB_HP_33120A.h"

#include <math.h>    // for fabs

TGPIB_HP_33120A::TGPIB_HP_33120A (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
  MyName = "HP Pulser 33120A with ID = " + std::string (MyId);

  if (!DeviceResponds()) {
    Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
    MyIf->RemoveDevice(MyId);
  }

  Send("OUTPUT:LOAD 50");      // always set to 50 Ohm load
}

bool TGPIB_HP_33120A::DeviceResponds()
{
  std::string GoodResult = "HEWLETT-PACKARD,33120A";
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
  
void TGPIB_HP_33120A::SetAmplitude (float volt)
{
  Send("SOURCE:VOLTAGE:OFFSET 0");
  Send("SOURCE:VOLTAGE:UNIT VPP");
  DecimalSeparator = '.';
  Send("SOURCE:VOLTAGE " + FloatToStrF(volt, ffFixed, 6, 3));
}

void TGPIB_HP_33120A::SetFrequency (float freq)
{
  Send("SOURCE:FREQUENCY " + std::string(freq));
}

void TGPIB_HP_33120A::DefineWave (int npoints, float * value)
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


void TGPIB_HP_33120A::Trigger (void)
{
  Send("*TRG");
}

void TGPIB_HP_33120A::DisplayText (std::string Msg)
{
  Send("DISPLAY:TEXT '" + Msg + "'");
//  Send("DISPLAY ON");
}

void TGPIB_HP_33120A::DisplayOff (void)
{
  Send("DISPLAY:TEXT:CLEAR");
}


/*

// This is old stuff for the 'bigger' pulsers HP8110A and HP8116A

void Pulser::Enable() {
  ClearBuf();
  if(ID==HP8116A) sprintf(buf, "D0");
  if(ID==HP8110A) sprintf(buf, ":OUTP1 ON");
  sendcom();
}

void Pulser::Disable() {
  if(ID==HP8116A) sprintf(buf, "D1");
  if(ID==HP8110A) sprintf(buf, ":OUTP1 OFF");
  sendcom();
}

void Pulser::SetBurstMode(int anzahl)
{
  burstlength=anzahl;
  Disable();
  SetFreq(5000); //50kHz
  if(ID==HP8116A)
  {
    sprintf(buf, "BUR %u #", anzahl);
    sendcom();
    sprintf(buf,"M8, CT0, T1, H0, W4, C0, LO, A0");
    sendcom();
  }
  if(ID==HP8110A)
  {
    sprintf(buf,":PULS:DCYC1 50PCT");
    sendcom();
    sprintf(buf,":VOLT:LOW 0V");
    sendcom();
    sprintf(buf,":ARM:SOUR MAN");        // trigger: Manual Button (kann man über IEEE schicken)
    sendcom();
    sprintf(buf,":TRIG:COUN %d",anzahl); // anzahl pulse
    sendcom();
    sprintf(buf,":TRIG:SOUR INT");       // interner oszillator als zaehler
    sendcom();
    sprintf(buf,":DIG:PATT OFF");        // einfache pulse, keine Muster (ginge auch)
    sendcom();
  }
  Enable();
}

void Pulser::Burst() {
  int status;
  if(ID==HP8110A)
  {
   transmit("MTA LISTEN 10 GTL DATA ':SYST:KEY 16' END",&status);
   delay(150);
  }
}

void Pulser::SetFreq(double Hz) {
  long width = 100/Hz*1000000; // 10% der Periode in ns
  if(ID==HP8110A) sprintf(buf, ":FREQ %f",Hz); // 10% ist standard ...
  if(ID==HP8116A) sprintf(buf, "FRQ %.2f HZ, WID %d NS", Hz, width);
  sendcom();
}

void Pulser::SetHILevel(double V) {
  if(ID==HP8116A) sprintf(buf, "HIL %f V, LOL 0 V", V);
  if(ID==HP8110A) sprintf(buf, ":VOLT:HIGH %fV",V);
  sendcom();
}


// Von MArkus:



void Pulser::Reset()
{
  if(ID==PulserCard) return;
  if(ID==HP8110A)
  {
    sendcom("MTA LISTEN 10 DATA '*RST' END");
    sendcom("MTA LISTEN 10 DATA '*CLS' END");
    sendcom("MTA LISTEN 10 DATA '*ESE 0' END");
    sendcom("MTA LISTEN 10 DATA '*SRE 0' END");
  }
}

void Pulser::SetSRQ()
{
   sendcom("MTA LISTEN 10 DATA '*CLS' END '*ESE 1' END '*SRE 32' END");
   Sleep(100);
}

void Pulser::Status()
{
  int i;
  sendcom("MTA LISTEN 10 DATA '*STB?' END");
  sprintf(buf,"STB:%s",getdata()); print(buf);
  sendcom("MTA LISTEN 10 DATA '*ESE?' END");
  sprintf(buf,"ESE:%s",getdata()); print(buf);
  sendcom("MTA LISTEN 10 DATA '*OPC?' END");
  sprintf(buf,"OPC:%s",getdata()); print(buf);
  sendcom("MTA LISTEN 10 DATA '*SRE?' END");
  sprintf(buf,"SRE:%s",getdata()); print(buf);
}


void Pulser::SetBurstMode(int anzahl, double offset)  //Noch zu ueberlegen!
{
  burstlength=anzahl;
  Anzahl=anzahl;
  if(offset==0.0)offsetmode=false;
  else offsetmode=true;
  Disable();     //Wofuer ist das?
//  SetFreq(5000); //50kHz
  if(ID==HP8116A)
  {
    sprintf(buf, "BUR %u #", anzahl);
//    commando();
    sprintf(buf,"M8, CT0, T1, H0, W4, C0, LO, A0");
  //  commando();
  }
  if(ID==HP8110A)
  {
    waitcom(":PULS:DCYC1 50PCT");
    sprintf(command,":HOLD VOLT"); waitcom(command);
    if(offset==0.0) sprintf(command,":VOLT:LOW 0V");
    else sprintf(command,":VOLT:OFFS %fV",offset);
    waitcom(command);
    sprintf(command,":ARM:SOUR MAN");        // trigger: Manual Button (kann man über IEEE schicken)
    waitcom(command);
    sprintf(command,":TRIG:COUN %d",anzahl); // anzahl pulse
    waitcom(command);
    sprintf(command,":TRIG:SOUR INT");       // interner oszillator als zaehler
    waitcom(command);
    sprintf(command,":DIG:PATT OFF");        // einfache pulse, keine Muster (ginge auch)
    waitcom(command);
   }
}

void Pulser::Burst()
{
  int status,i;
  if(ID==HP8110A)
  {
// identisch mit waitcom
     sendcom("MTA LISTEN 10 DATA '*CLS' END");
     sendcom("DATA '*OPC?' END");   getdata();
     //     sprintf(buf,"OPC-Result %s.", getdata()); print(buf);

     // hier manuell, da zusätzliches GTL (go to local) nötig
     sendcom("MTA LISTEN 10 GTL DATA ':SYST:KEY 16' END");

     // zusätzlich: erst REN und dann das OPC kommando!
     sendcom("MTA LISTEN 10 REN DATA '*OPC' END");

     // srq bit pollen
     waitpoll("MTA LISTEN 10 GTL DATA ':SYST:KEY 16' END"); // nur pollen ...
  }
  if(ID==PulserCard)
  {
     if (Hz2>500) Hz2=50000;
     for(i=0;i<Anzahl;i++)
     {
       PULSER->DigOut(1);
       Sleep( 1000/(Hz2*2) );
       PULSER->DigOut(0);
       Sleep( 1000/(Hz2*2) );
     }
  }
}

void Pulser::SetFreq(double Hz)    //Bei der PulserCard wird hier nur die Frequenz Zahl (in Hz)gesetzt!
 {
  long width = (long) 100.0/Hz*1000000.0; // 10% der Periode in ns
  if(ID==HP8110A) { sprintf(command, ":FREQ %f",Hz);     waitcom(command); }            // 10% ist standard ...
//  if(ID==HP8116A) { sprintf(buf, "FRQ %.2f HZ, WID %d NS", Hz, width); commando(); }
//  if(ID==PulserCard) Frequenz=Hz;
  Frequenz=Hz;
}
                                       // nur bei HP 8110A: Amplitude+Offset möglich, wenn vorher Offset eingestellt
void Pulser::SetOffset(double offset)  // Erst Burst-Mode, dann Offset einstellen!
{
   offsetmode=true;
   sprintf(command,":VOLT:OFF %fV",offset);
    waitcom(command);
}

void Pulser::SetHILevel(double V)      // Setzt bei der PulserCard den LowLevel auf 0V!!!
{
//  if(ID==HP8116A) {sprintf(buf, "HIL %f V, LOL 0 V", V); commando();}
  if(ID==HP8110A)
  {
    if(!offsetmode) sprintf(command, ":VOLT:HIGH %fV",V);
    else sprintf(command,":VOLT:AMPL %fV",V);
    waitcom(command);
  }
  if(ID==PulserCard)
  {
     PULSER->SetHighLevel(V*1000.0);
     PULSER->SetLowLevel(0);
  }
}

void Pulser::Calibrate() {
  if(!ID==PulserCard) return;
  PULSER->Calibrate();
}

long Pulser::BurstTime() {       // ms
  return((long)(1000.0*(double)Anzahl/(double)(Frequenz)));
}

// Noch mehr Pulser Kram für die schnellen Pulser

bool UsePulser = false;  // flags if this pulser is used or internal strobe mode
bool VideoSwitcher = false;
int PulserType = 0;      // HP 150MHz Pulser (0) or arbitrary waveform generator (1)
static int last_burstlen = 0;
int Amp1, DeltaT;

void Pulser_Init(int AType)
{
  int status, length;
  char cmd[80];

  PulserType = AType;
  ieee_send(PULSER,"*rst",&status);
  ieee_send(PULSER,"*cls",&status);

// later: compare with expected name

  ieee_send(PULSER,"*idn?",&status);
  memset( cmd, 0, 80 );
  enter (cmd, 80, &length, PULSER, &status);
  cprintf("Status=%d, length=%d, Instrument id:%s", status, length, cmd);

  if(!PulserType) {
    ieee_send(PULSER,":DISPLAY OFF",&status);
    ieee_send(PULSER,":PULSE:TRANSITION:TRAILING:AUTO OFF",&status);
    ieee_send(PULSER,":PULSE:TRANSITION:LEADING  200NS",&status);
    ieee_send(PULSER,":PULSE:TRANSITION:TRAILING 10NS",&status);

    sprintf(cmd, ":PULSE:PERIOD %dUS", PULSER_PERIOD);
    ieee_send(PULSER,cmd,&status);
    sprintf(cmd, ":PULSE:WIDTH  %dUS", PULSER_WIDTH);
    ieee_send(PULSER,cmd,&status);

    ieee_send(PULSER,":HOLD CURRENT",&status);			// switch to current mode
    ieee_send(PULSER,":CURRENT:LIMIT:HIGH  200MA",&status);
    ieee_send(PULSER,":CURRENT:LIMIT:LOW  0MA",&status);

    ieee_send(PULSER,":HOLD VOLTAGE",&status);			// switch to voltage mode
    ieee_send(PULSER,":VOLTAGE:LIMIT:LOW  0MV",&status);
    ieee_send(PULSER,":VOLTAGE:LIMIT:HIGH 10000MV",&status);
    ieee_send(PULSER,":VOLTAGE:LIMIT:STATE ON",&status);

    ieee_send(PULSER,":VOLTAGE:LEVEL:LOW     0MV",&status);
    ieee_send(PULSER,":VOLTAGE:LEVEL:HIGH 2000MV",&status);

    ieee_send(PULSER,":OUTPUT:IMPEDANCE:INTERNAL 50OHM",&status);
    ieee_send(PULSER,":OUTPUT:IMPEDANCE:EXTERNAL 50OHM",&status);
//  ieee_send(PULSER,":OUTP1:POL INV", &status);
    ieee_send(PULSER,":OUTPUT:STATE ON",&status);

    ieee_send(PULSER,":ARM:SOURCE MAN",&status);
    ieee_send(PULSER,":ARM:SENSE EDGE",&status);
    ieee_send(PULSER,":ARM:LEVEL 100MV", &status);
    ieee_send(PULSER,":TRIGGER:COUNT 1000",&status);
    ieee_send(PULSER,":TRIGGER:SOURCE INT",&status);
    ieee_send(PULSER,"DIGITAL:PATTERN OFF",&status);
    ieee_send(PULSER,":SOURCE:PULSE:DELAY1 12ns", &status);

//  ieee_send(PULSER,":SOURCE:PULSE:TRAN1:LEAD 10ns",&status);
    ieee_send(PULSER,":DISPLAY ON",&status);
  }
  else {    //commands for arbitrary waveform generator
    ieee_send(PULSER,":SOURCE:FUNCTION:SHAPE SQUARE",&status);
    ieee_send(PULSER,":SOURCE:FREQ 10000",&status);
    ieee_send(PULSER,":BM:STATE ON",&status);
    ieee_send(PULSER,":TRIGGER:SOURCE BUS",&status);
    ieee_send(PULSER,":DISPLAY:TEXT 'PIRATE TEST'",&status);
  }
  UsePulser = true;
}

void Pulser_SetBurstLength (const int BurstLen)
{
  char s[80];
  int status;

  if (!PulserType)
    sprintf (s, ":TRIGGER:COUNT %ld", BurstLen);
  else
    sprintf (s, ":BM:NCYCLES %ld",BurstLen);
  last_burstlen = BurstLen;
  ieee_send(PULSER,s,&status);
  if (status!=0)
    cprintf("Pulser_SetBurstLength: Status=%d", status);
}

void Pulser_Trigger (void)
{
  int status, del;

  ieee_send (PULSER, "*TRG", &status);
  if (status!=0)
    cprintf("Pulser_Trigger: Status=%d", status);
  if(!PulserType)
    del = (int) ((double) last_burstlen * PULSER_PERIOD * 0.001 + 100);
  else
    del = (int) ((double) last_burstlen * 0.1 + 100);
  Sleep (del);
//  Sleep(1000);
}

void Pulser_SetVoltage (const int mv)
{
  char str[80];
  char pattern[16000];
  char dummy[16000];
  int status,i;
  float amp, offset;
  int stepheight, steplength, step;

  if (!PulserType) {
    sprintf(str, ":VOLTAGE:LEVEL:HIGH %ldMV", mv);
    ieee_send(PULSER,str,&status);
  }
  else {// hier kommt jetzt der double-pulse-stuff hin
    amp = ((float)(Amp1)+(float)(mv))/1000;
    if(amp>5.0)
      amp = 5.0;
    stepheight = (int)((2 * (float)(mv)/(1000*amp) - 1)*2047);
    if(stepheight>2047)
      stepheight = 2047;
    //cprintf("amp = %3.3f, stepheight = %d, DeltaT = %d",amp,stepheight, DeltaT);
    //Achtung! Jetzt wird's richtig fies!
    sprintf(pattern,"");
    sprintf(dummy,"");
    sprintf(pattern, ":DATA:DAC VOLATILE, -2047");

    //steplength = DeltaT*frequency*Patternlength
    steplength = (int)((1e-9*(double)(10000 * 2000))*DeltaT);
    step = -2047;
    for(i=1;i<1000-steplength/2;i++)          {
      strcpy(dummy,pattern);
      if (step>2047)
        step = 2047;
      sprintf(pattern, "%s,%d",dummy,step);
      //if(i==10)
        //cprintf(pattern);
      step += 20;
    }
    for(i=1000-steplength/2;i<1000-steplength/2+steplength;i++) {
      strcpy(dummy,pattern);
      sprintf(pattern, "%s,%d",dummy,stepheight);
    }
    for(i=i;i<2000;i++) {
      strcpy(dummy,pattern);
      sprintf(pattern, "%s,-2047",dummy);
    }

    ieee_send(PULSER,pattern,&status);
    if (status!=0)
      cprintf("Status=%d", status);
    ieee_send(PULSER,":FUNC:USER VOLATILE",&status);
    ieee_send(PULSER,":FUNC:SHAPE USER",&status);
    sprintf(str,":SOURCE:VOLTAGE %3.3f",amp);
    ieee_send(PULSER,str,&status);
    offset = amp/2;
    sprintf(str, ":SOURCE:VOLTAGE:OFFSET %3.3f",offset);
    ieee_send(PULSER,str,&status);
  }
  Sleep (300);
}


void LA_CaptureWafeform (void)
{
  int status, maxlen = 4000, len;
  unsigned char buffer[4000];
  char str[255];
  FILE *f;

  memset (buffer, 0, 4000);
  sprintf (str, ":WAV:FORM BYTE");
  ieee_send (MDOSCI, str, &status);
  cprintf ("%s %d", str, status);
  sprintf (str, ":WAV:POINTS NORMAL,4000");
  ieee_send (MDOSCI, str, &status);
  cprintf ("%s %d", str, status);
  sprintf (str, ":ACQ:TYPE NORMAL");
  ieee_send (MDOSCI, str, &status);
  cprintf ("%s %d", str, status);
  sprintf (str, ":WAV:SOURCE POD1");
  ieee_send (MDOSCI, str, &status);
  cprintf ("%s %d", str, status);
  sprintf (str, ":DIG POD1");
  ieee_send (MDOSCI, str, &status);
  cprintf ("%s %d", str, status);
  sprintf (str, ":WAV:PREAMBLE?");
  ieee_send (MDOSCI, str, &status);
  cprintf ("%s %d", str, status);
  enter (buffer, 80, &len, MDOSCI, &status);
  cprintf ("%s len = %d %d", buffer, len, status);

//  sprintf (str, ":WAV:DATA?");
//  ieee_send (MDOSCI, str, &status);
//  cprintf ("%s %d", str, status);
//  Sleep (10);
//  sprintf (str, "MLA TALK %d", MDOSCI);
//  transmit (str, &status);
//  cprintf ("%s %d", str, status);
//  rarray (header, 8, &len, &status);
//  cprintf ("%s Header[0] = %d, Header[1] = %d, len = %d status = %d", str, header[0], header[1], len, status);
//  rarray (buffer, maxlen, &len, &status);
//  cprintf ("%s len = %d status = %d", str, len, status);
  f = fopen ("c:\\temp\\test.dat", "w+");
  if (f) {
    fwrite (buffer, 1, maxlen, f);
    fclose (f);
  }
}

void PulserSetFreq(const int Freq)
{
     int status;
     char cmd[80];

     sprintf(cmd,":SOURCE:FREQ %d", Freq);
     ieee_send(PULSER,cmd,&status);
}

void PulserSetFreqMHz(const int Freq)
{
     int status;
     char cmd[80];

     sprintf(cmd,":SOURCE:FREQ %dMHz", Freq);
     ieee_send(PULSER,cmd,&status);
}


void Pulser_Init_ToT()
{
     int status;

     ieee_send(PULSER,":ARM:SOUR EXT",&status);
     ieee_send(PULSER,":TRIG:SOUR EXT",&status);
     ieee_send(PULSER,":TRIG:COUN 1",&status);
     ieee_send(PULSER,":OUTP:POL INV",&status);
}



*/
