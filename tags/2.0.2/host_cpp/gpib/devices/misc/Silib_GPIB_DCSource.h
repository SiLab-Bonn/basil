#ifndef SILIB_GPIB_DCSource_H
#define SILIB_GPIB_DCSource_H

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

typedef enum { ASCII, BINARY } DataFormat;
typedef enum { SHORT_INTEGRATION, MEDIUM_INTEGRATION, LONG_INTEGRATION} Inttime;

typedef enum { SMU1 = 1, SMU2 = 2, SMU3 = 3, SMU4 = 4,
               VS1  = 5, VS2  = 6, VM1  = 8, VM2  = 9 } Port;

	    // GNDU on Port 10 of SMU HP4141B cannot be connected
	    // to the Switchmatrix HP4085M !!! so sorry!

const int DCSOURCE = 23;

#define MAXLEN      10000    // of string to receive data
#define MAXDATA     1021	    // number of data points in one sweep

#define ILOW		1E-6
#define IMEDIUM	1E-3
#define IHIGH		1E-1

#define VLOW		10
#define VMEDIUM	20
#define VHIGH		40

#define LIN	     1
#define LOG         2


class TGPIB_DCSource: public TGPIB_Device
{
public:
       TGPIB_DCSource     (TGPIB_Interface * If, int id = DCSOURCE);

void   ClearAll           (void);
void   ZeroOutput         (void);
void   SetDataFormat      (DataFormat);
void   SetIntegrationtime (Inttime);

void   SetVoltage         (Port pt, double voltage, double maxcurr);
double MeasureCurrent     (Port pt);

int    SweepVoltage       (double b[600], double a[6][MAXDATA], Port pt1, Port pt2, double start, double stop, double step, int type, double maxcurr, int curve);

//void  SetCurrent         (Port pt, double current, double maxvoltage);
//void  SetCurrentMeasurementRange (Port pt, int range);
//void  Set_High_Voltage   (int pin, double voltage, double maxcurr);
//double MeasureVoltage     (Port pt);
//int   SweepVds         (double b[600], double a[5][MAXDATA], int pin, double start, double stop, double step, int type, double maxcurr, int curve);
//int   SweepVbs         (double b[600], double a[5][MAXDATA], int pin1, int pin2, double start, double stop, double step, int type, double maxcurr, int curve);
//int   SweepIs          (double b[600], double a[5][MAXDATA], int pin1, int pin2, double start, double stop, double step, int type, double maxcurr, int curve);
//int   SweepTwoVoltages (double b[600], double a[8][MAXDATA], int pin1, int pin2, int pin3, double start1, double stop1, double step1, double start2,double stop2,int type, double maxcurr1, double maxcurr2, int curve);
//int   SweepCurrent     (double b[600], double a[5][MAXDATA], int pin1, int pin2, double start, double stop, double step, int type, double maxcurr, int curve);

private:
   bool   DeviceResponds     ();           // Test if device responds
};

#endif
