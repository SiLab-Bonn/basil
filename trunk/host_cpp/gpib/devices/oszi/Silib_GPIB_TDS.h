#ifndef SILIB_GPIB_TDS_H
#define SILIB_GPIB_TDS_H

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"
#include <vector.h>
#include <vcl.h>
#include <stdio.h>


// z.B. TDS3034 (kleines tragbares FarbOszi)

#define MAX_WFM_POINTS 10000
#define DATA_WIDTH 2

class TGPIB_TDS: public TGPIB_Device
{
public:
					TGPIB_TDS          (TGPIB_Interface * If, int id);
					~TGPIB_TDS          ();

	 void   SetTimeScale       (double TimePerDiv);
	 void   SetScale           (int channel, double VoltPerDiv);
	 void   HardCopy           (int i);
	 void   GetResolution      (int channel);
	 void   GetWaveform        (int channel);
	 bool   HardCopy(std::string FileName, std::string);
	 void   ClearAllMeasurements ();

void				SetMeasurement (const int SelectedMeasurement, const int fromChannel,const int MeasureBox,
														const int toChannel = 1, const bool forwards = true, const bool edge1rise=true,
														const bool edge2rise=true);
double			GetMeasurementValue(const int MeasureBox);
std::string	GetMeasurementUnits(const int MeasureBox);
void  			PrecisionGetMeasurementValue(const int MeasureBox, const int samples,
													 int msWaitTime,	double &average, double &sigma);


std::string  GetMeasurementName(const int m);
std::string  GetMeasurementDescription(const int m);
std::string  GetMeasurementBoxName(const int m);

	 static const int NUM_MEASURE = 25;
	 static const int NUM_MEASUREBOXES = 5;


	 double *buffer;
	 double *wfmData;
	 double xScale;
	 double yScale;
	 double yOff;
	 int    nPoints;


private:
	 bool   DeviceResponds     ();           // Test if device responds
	 static const std::string AvailableMeasurements[NUM_MEASURE][2];
	 static const std::string MeasureBoxes[NUM_MEASUREBOXES];
	 };



const std::string TGPIB_TDS::AvailableMeasurements[NUM_MEASURE][2] = {
					{"AMPLITUDE", "is the high value minus the low value."},
					{"AREA", "is the area between the curve and ground over the active waveform the high value minus the low value. TDS3AAM only."},
					{"BURST", "is the time from the first MidRef crossing to the last MidRef crossing."},
					{"CAREA", "(cycle area) is the area between the curve and ground over one cycle. TDS3AAM only."},
					{"CMEAN", "is the arithmetic mean over one cycle."},
					{"CRMS", "is the true Root Mean Square voltage over one cycle."},
					{"DELAY", "is the delay from one waveform's edge event to another."},
					{"FALL", "is the time that it takes for the falling edge of a pulse to fall from a HighRef value to a LowRef value of its final value."},
					{"FREQUENCY", "is the reciprocal of the period measured in hertz."},
					{"HIGH", "is the 100% reference level."},
					{"LOW", "is the 0% reference level."},
					{"MAXIMUM", "is the highest amplitude (voltage)."},
					{"MEAN", "for general purpose measurements, is the arithmetic mean over the entire waveform. For histogram measurements, it is the average of all acquired points within or on the histogram box."},
					{"MINIMUM", "is the lowest amplitude (voltage)."},
					{"NDUTY", "is the ratio of the negative pulse width to the signal period expressed as a percentage."},
					{"NOVERSHOOT", "is the negative overshoot."},
					{"NWIDTH", "is the distance (time) between MidRef (usually 50%) amplitude points of a negative pulse."},
					{"PDUTY", "is the ratio of the positive pulse width to the signal period expressed as a percentage."},
					{"PERIOD", "is the time, in seconds, it takes for one complete signal cycle to happen."},
					{"PHASE", "is the phase difference from the selected waveform to the designated waveform."},
					{"PK2PK", "is the absolute difference between the maximum and minimum amplitude. It can be used with both general purpose and histogram measurements."},
					{"POVERSHOOT", "is the positive overshoot."},
					{"PWIDTH", "is the distance (time) between MidRef (usually 50%) amplitude points of a positive pulse."},
					{"RISE", "is the time that it takes for the leading edge of a pulse to rise from a low reference value to a high reference value of its final value."},
					{"RMS", "is the true Root Mean Square voltage."}
};

/*

achtung:
delay-messung zwischen midref1 und midref2 !

:MEASUREMENT:REFLEVEL:METHOD PERCENT
:MEASUREMENT:REFLEVEL:PERCENT:MID 50;MID2 50

*/


const std::string TGPIB_TDS::MeasureBoxes[NUM_MEASUREBOXES] = {"MEAS1", "MEAS2", "MEAS3", "MEAS4", "IMMED"};




#endif
