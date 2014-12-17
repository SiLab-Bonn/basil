
#include "SILIB_GPIB_TDS.h"


TGPIB_TDS::TGPIB_TDS (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	MyName = "Tektronix Oszi with GPIB address " + std::string (MyId);

	if (!DeviceResponds())  {
		Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
		isOk = false;
		MyIf->RemoveDevice(MyId);
		return;
	}
	buffer = NULL;
	wfmData = new double[MAX_WFM_POINTS];

	Send("*PSC");
	Send("HEADER OFF");
}

TGPIB_TDS::~TGPIB_TDS ()
{
	delete[] wfmData;
}


bool TGPIB_TDS::DeviceResponds()
{
  std::string GoodResult = "TEKTRONIX,TDS";

  Send("DATA:ENCDG ASCII");
  std::string Result     = SendAndReceive("*IDN?");
  return (Result.SetLength(GoodResult.Length()) == GoodResult);
}




void TGPIB_TDS::SetTimeScale (double TimePerDiv)
{
  DecimalSeparator = '.';
  Send ("HOR:MAIN:SCALE " + FloatToStrF(TimePerDiv, ffFixed, 6, 6));
}

void TGPIB_TDS::SetScale (int chan, double VoltPerDiv)
{
  DecimalSeparator = '.';
  Send ("CH" + std::string(chan) + ":VOLT " + FloatToStrF(VoltPerDiv, ffFixed, 6, 6));
}


void TGPIB_TDS::GetResolution(int channel)
{
  char oldsep = DecimalSeparator;  // decimal separator
	DecimalSeparator = '.';     // set new decimal separator

	Send("DATA:ENCDG ASCII");
	nPoints = SendAndReceive("HOR:RECORD?").ToInt();
	xScale  = SendAndReceive("WFMPRE:CH"+std::string(channel)+":XINCR?").ToDouble();
  yScale  = SendAndReceive("WFMPRE:CH"+std::string(channel)+":YMULT?").ToDouble();
  yOff    = SendAndReceive("WFMPRE:CH"+std::string(channel)+":YOFF?").ToDouble();

  DecimalSeparator = oldsep;
}

void TGPIB_TDS::GetWaveform (int channel)
{
  std::string Res;
  std::string ValStr;

  char oldsep = DecimalSeparator;
  DecimalSeparator = '.';

  GetResolution(channel);

  // prepare data aquisition
  Send("DATA:SOURCE CH"+std::string(channel));
  Send("DATA:START 1");
  Send("DATA:STOP " + std::string(nPoints));

#undef FORMAT_ASCII
//#define FORMAT_ASCII 1

#ifdef FORMAT_ASCII
  Send("DATA:ENCDG ASCII");
  Res = SendAndReceive("CURVE?");

  for (int i=0; i<nPoints; i++)
  {
    int p = Res.Pos(',');
    if (p==0)
			ValStr = Res;
    else
      ValStr = Res.SubString(1,p-1);
    wfmData[i] = (ValStr.ToDouble() - yOff) * yScale;
    Res = Res.SubString(p+1, Res.Length()-p);
  }
#else

  byte p_offset;
	byte *buffer;
  int bufferlength;

  if ((nPoints*DATA_WIDTH) < 999)
    p_offset =  5;
  else
  if ((nPoints*DATA_WIDTH) < 9999)
    p_offset =  6;
  else
  if ((nPoints*DATA_WIDTH) < 99999)
    p_offset =  7;

  bufferlength = DATA_WIDTH*nPoints + p_offset;
  buffer       = new byte[bufferlength];
  Send("DATA:ENCDG RIBINARY;WIDTH "+std::string(DATA_WIDTH));   // RIBINARY: signed integer [-32768..32767], MSB first
                                                               // RPBINARY: unsigned integer [0..65353], MSB first

  Send("CURVE?");
  ReceiveBinary(buffer, bufferlength);
  // buffer format "#xyyy<data>LF" ,
  //                 x represents number of digits y
  //                 yyy represents number of transmitted bytes
  for (int i=0; i<nPoints; i++)
  {
    wfmData[i] = (double)((((signed char)buffer[2*i + p_offset]<<8) + buffer[2*i + 1 + p_offset]) - yOff) * yScale;
  }
  delete[] buffer;
  Send("DATA:ENCDG ASCII"); // switch back to ASCII

#endif
/*
  // scale y-values
  for (int i=0; i<nPoints; i++)
    Arr[i] = (Arr[i] - yOff) * yScale;
*/
	//restore decimal separator
	DecimalSeparator = oldsep;
}


bool TGPIB_TDS::HardCopy(std::string FileName, std::string Format)
{
  FILE *outfile;
  int bytecount;
  #define MAXBUFFER 500000

  byte *buf = new byte[MAXBUFFER];

  if((outfile = fopen(FileName.c_str(), "w+")) == NULL)
		return false;

	/*Send("DATA:ENCDG RIBINARY;WIDTH 1");
  Send("HARDCOPY ABORT");
	Send("HARDCOPY CLEARSPOOL");
	Send("HARDCOPY:COMPRESSION OFF");
  Send("HARDCOPY:PORT GPIB");
  if (Format != "LOCAL")
    Send("HARDCOPY:FORMAT " + Format);
  Send("HARDCOPY START");
                            */
	bytecount = MyIf->Listen(MyId, buf, MAXBUFFER);

  Send("BELL");

  fwrite(buf , 1, bytecount, outfile);

  fclose(outfile);
  delete[] buf;
  return true;
}

//---------------------------------------------------------------------------

void TGPIB_TDS::SetMeasurement (const int SelectedMeasurement, const int fromChannel,const int MeasureBox,
																const int toChannel, const bool forwards, const bool edge1rise, const bool edge2rise)
{


	 if (SelectedMeasurement > NUM_MEASURE-1)
		Application->MessageBox("Error", "selected Measurement does not exist!", MB_ICONWARNING);

	 if (MeasureBox > NUM_MEASUREBOXES-1)
		Application->MessageBox("Error", "selected Measurement Box does not exist!", MB_ICONWARNING);

//	:MEASUREMENT:MEAS3:TYPE AMPLITUDE;SOURCE1 CH2;SOURCE2 CH2;STATE 1;DELAY:DIRECTION FORWARDS;EDGE1 RISE;EDGE2 RISE

		std::string Out = ":MEASUREMENT:" + GetMeasurementBoxName(MeasureBox)
		+ ":TYPE "	+ GetMeasurementName(SelectedMeasurement)
		+ ";SOURCE1 CH" + fromChannel + ";SOURCE2 CH" + toChannel + ";STATE 1;DELAY:DIRECTION "
		+ (forwards ? "FORWARDS" : "BACKWARDS")
		+ ";EDGE1 " +  (edge1rise ? "RISE" : "FALL") + ";EDGE2 " +  (edge2rise ? "RISE" : "FALL");

    Send(Out);
}


//---------------------------------------------------------------------------
std::string  TGPIB_TDS::GetMeasurementName(const int m)
{
	 if (m > NUM_MEASURE-1)
		Application->MessageBox("Error", "selected Measurement does not exist!", MB_ICONWARNING);

		return AvailableMeasurements[m][0];
}

//---------------------------------------------------------------------------
std::string  TGPIB_TDS::GetMeasurementDescription(const int m)
{
	 if ((m > NUM_MEASURE-1) || (m<0) )
		Application->MessageBox("Error", "selected Measurement does not exist!", MB_ICONWARNING);

		return AvailableMeasurements[m][1];
}

//---------------------------------------------------------------------------
std::string  TGPIB_TDS::GetMeasurementBoxName(const int m)
{
	 if ((m > NUM_MEASUREBOXES-1) || (m<0))
		Application->MessageBox("Error", "selected Measurement Box does not exist!", MB_ICONWARNING);
	 return	MeasureBoxes[m];
}
//---------------------------------------------------------------------------

void  TGPIB_TDS::ClearAllMeasurements()
{

	Send("MEASUREMENT:CLEARSNAPSHOT");
	Send("MEASUREMENT:MEAS1:STATE 0");
	Send("MEASUREMENT:MEAS2:STATE 0");
	Send("MEASUREMENT:MEAS3:STATE 0");
	Send("MEASUREMENT:MEAS4:STATE 0");
}
//---------------------------------------------------------------------------
std::string	TGPIB_TDS::GetMeasurementUnits(const int MeasureBox)
{
		return SendAndReceive(":MEASUREMENT:" + GetMeasurementBoxName(MeasureBox) + ":UNITS?");
}

//---------------------------------------------------------------------------
double TGPIB_TDS::GetMeasurementValue(const int MeasureBox)
{
	// keine prüfung ob messung existiert oder aktiv ist
	//	MEASUREMENT:MEAS1:VALUE?

	std::string result = SendAndReceive(":MEASUREMENT:" + GetMeasurementBoxName(MeasureBox) + ":VALUE?");
	return result.ToDouble();

}
//---------------------------------------------------------------------------
void TGPIB_TDS::PrecisionGetMeasurementValue(const int MeasureBox, int samples,
const int msWaitTime,	double &average, double &sigma)
{

	if (msWaitTime<0)
		msWaitTime = 0;
	else if (msWaitTime>1000)
		msWaitTime = 1000;


	vector <double> v;
	double singleV;

	// discard first two measurements:
	singleV = GetMeasurementValue(MeasureBox);
	singleV = GetMeasurementValue(MeasureBox);

	// measure sample vector
	for(int i=0; i<samples; ++i)
	{
		singleV = GetMeasurementValue(MeasureBox);
		Sleep(msWaitTime);
		v.push_back(singleV);
	}

	// compute average
	double avV = 0;
	double fraction = 1. / double (samples);
	for(int i=0; i<samples; ++i)
	{
		avV += v[i] * fraction;
	}
	average = avV;

	// compute sigma
	double varianceV = 0;
	for(int i=0; i<samples; ++i)
	{
		varianceV += fraction * (avV - v[i]) * (avV - v[i]);
	}
	sigma = sqrt(varianceV);


}
//---------------------------------------------------------------------------

