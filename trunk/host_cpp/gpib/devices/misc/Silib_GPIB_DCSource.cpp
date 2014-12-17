#include "Silib_GPIB_DCSource.h"

#include <math.h>

TGPIB_DCSource::TGPIB_DCSource (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
	std::stringstream ss;
	ss << "HP DC Source with ID = " << MyId;
  MyName = ss.str();;

  if (!DeviceResponds()) {
    ErrorMsg("Device does not respond!");
    MyIf = NULL;
  }
}

bool TGPIB_DCSource::DeviceResponds()
{
  std::string GoodResult = "HP 4141B REV. 3.1";
  std::string Result = SendAndReceive("ID ;");
  return (Result == GoodResult);
//  return (true);
}



void TGPIB_DCSource::ClearAll (void)
{
  Send ("CL;");
}

void TGPIB_DCSource::ZeroOutput (void)
{
  Send  ("DZ0;");
}

void TGPIB_DCSource::SetDataFormat (DataFormat format)
{
  if (format == ASCII)
    Send ("BD0;");
  else
    Send ("BD1;");
}

void TGPIB_DCSource::SetIntegrationtime (Inttime time)
{
  switch (time) {
    case SHORT_INTEGRATION:  Send ("IT1;"); break;
    case MEDIUM_INTEGRATION: Send ("IT2;"); break;
    case LONG_INTEGRATION:   Send ("IT3;"); break;
    default: ErrorMsg("Illegal command code in SetIntegrationtime"); break;
  }
}


void TGPIB_DCSource::SetVoltage (Port pt, double voltage, double maxcurr)
{
  if (fabs(voltage) > 100) {
    ErrorMsg("Voltage too high in SetVoltage");
    return;
  }

  switch (pt) {
    case VM1: case VM2:
      ErrorMsg("Cannot set Voltage of VMs in SetVoltage");
    break;
    case SMU1: case SMU2: case SMU3: case SMU4: case VS1: case VS2:
      char ss[40];
        sprintf(ss, "DV%1d,1,%1.3E,%1.5G;", pt, voltage, maxcurr);    //20V Range
//      sprintf(ss, "DV%1d,0,%1.3E,%1.5G;", PortAss[pin], voltage, maxcurr);    //Auto-Range
        Send (std::string(ss));
    break;
    default:
      ErrorMsg("Unknown Port in SetVoltage");
    break;
  }
}

double TGPIB_DCSource::MeasureCurrent (Port pt)
{
  char ss[40];
  double value = 0;

  if ((pt<SMU1) || (pt>SMU4))
    ErrorMsg("Illegal port in MeasureCurrent");
  else {
    sprintf(ss, "TI%1d", pt);
    std::string Res = SendAndReceive (ss);
    for (int j=0; j<11; j++) ss[j]=Res.c_str()[3+j];	// copy string without first 3 characters
    ss[11]='\n';                    // terminate string
    sscanf(ss, "%f\n", & value);    // read value from string ss to double value
  }

  return value;
}


int TGPIB_DCSource::SweepVoltage (double b[600], double a[6][MAXDATA],
  Port pt1,  // Measure this channel
  Port pt2,  // sweep this channel
  double start, double stop, double step,
  int type, double imax, int whichcurve)
{
  char ss[100];
  double value;
  int i, k, j, w;

  // Voltage Sweep on PORT2

  sprintf(ss, "WV%1d,%1d,1,%1.5G,%1.3E,%1.3G,%1.5G;", pt2,
        type, start, stop, step, imax);

  // fix voltage range to 100V (third argument is 3 in command)
  // fix voltage range to 20 V:(third argument is 1 in command)

  Send (ss);

  if (pt1<=SMU4) sprintf(ss, "MC%1d,1;", pt1);
  else           sprintf(ss, "MC%1d,1;", pt1 - 3);  // Monitor Channel PT1
  Send (ss);

  std::string Res = SendAndReceive ("WS0;");

  i=3;
  k=0;  
  while (i< (int)Res.size())
  {
//    if (Res.c_str()[i-3] != 'N') OutputDCSourceInfo("Status:");
//    if (Res.c_str()[i-3] == 'T') OutputDCSourceInfo("Another channel reached compliance !!!");
// ???    if (Res.c_str()[i-3] == 'C') OutputDCSourceInfo("Measuring channel reached compliance !!!");
    for (j=0; j<11; j++) ss[j]=Res.c_str()[i+j];
    ss[11]='\n';
    sscanf(ss, "%f\n", &value);
    a[whichcurve][k]=value;
    i+=15;
    k+=1;
  }
  for (w=0; w<=(stop-start)/step+1; w++)  b[w]=start+w*step;
  return(k);
}



/******************************************************************************/
//                        Not yet included stuff...
/******************************************************************************/


/*
void TGPIB_DCSource::Set_High_Voltage (int pin, double voltage, double maxcurr)
// fix voltage range to 20V  ( range# 1 in line 108 )
// fix voltage range to 100V ( range# 3 in line 108 )
{
	char ss[40];
	Port port;

	voltage+= offset;     //         <------------ Achtung: Offset-Addition fuer Relativ-Spannungen > 100V

	if ((pin<0) || (pin>MAXPIN)) {
		OutputDCSourceInfo("Illegal pin in function DCSource_SetVoltage!");
		return;
	}

	port = PortAss[pin];

	if (fabs(voltage) > 100) {
		OutputDCSourceInfo("Voltage too high in function DCSource_SetVoltage!");
		return;
	}

	switch (port) {
		case VM1: case VM2:
		       OutputDCSourceInfo("Error in DCSource_SetVoltage: Cannot set Voltage of VMs!");
		break;
		case SMU1: case SMU2: case SMU3: case SMU4: case VS1: case VS2:
//			sprintf(ss, "DV%1d,3,%1.3E,%1.5G;", PortAss[pin], voltage, maxcurr);  //100V Range
//			sprintf(ss, "DV%1d,1,%1.3E,%1.5G;", PortAss[pin], voltage, maxcurr);    //20V Range
          		sprintf(ss, "DV%1d,0,%1.3E,%1.5G;", PortAss[pin], voltage, maxcurr);    //Auto-Range
			#ifdef DEBUG
			sprintf(dcsource_info,"Sending to DCSource: '%s'", ss);
                        OutputDCSourceInfo(dcsource_info);
			#endif
			ieee_send (DCSOURCE, ss, &status);
      errorflag |= status;
    break;
    default:
        sprintf(dcsource_info,"Error in DCSource_SetVoltage: Unknown Port %d!", port);
        OutputDCSourceInfo(dcsource_info);
    break;
  }
}

void TGPIB_DCSource::SetCurrent (int pin, double current, double maxvoltage)
// fix current range to 1nA
{
  char ss[40];
  Port port;

  if ((pin<0) || (pin>MAXPIN)) {
     OutputDCSourceInfo("Illegal pin in function DCSource_SetCurrent!");
    return;
	}

  port = PortAss[pin];

  switch (port) {
    case VM1: case VM2:case VS1: case VS2:
      OutputDCSourceInfo("Error in DCSource_SetCurrent: Cannot set Current of VMs/VSs!");
    break;
    case SMU1: case SMU2: case SMU3: case SMU4:
      sprintf(ss, "DI%1d,1,%1.3E,%1.5G;", PortAss[pin], current, maxvoltage);
      #ifdef DEBUG
        sprintf (dcsource_info,"Sending to DCSource: '%s'", ss);
        OutputDCSourceInfo(dcsource_info);
      #endif
      ieee_send (DCSOURCE, ss, &status);
      errorflag |= status;
    break;
		default:
			sprintf(dcsource_info,"Error in DCSource_SetCurrent: Unknown Port %d!", port);
                        OutputDCSourceInfo(dcsource_info);
		break;
	}
}


//-----------------------------------------------------------

//----------------------------------------------------------------------


void TGPIB_DCSource::MeasureVoltage (int pin, double *value)
{
  char ss[40], r[40];
  Port port;
  int length;

  port = PortAss[pin];
  if ((port==VS1) || (port==VS2))
      OutputDCSourceInfo("Illegal port in function DCSource_MeasureCurrent");
  else {
    if (port<=SMU4)
      sprintf(ss, "TV%1d", port);
    else
      sprintf(ss, "TV%1d", port-3);  // these are the VMs
#ifdef DEBUG
    sprintf (dcsource_info, "Sending to DCSource: '%s'\n", ss);
    OutputDCSourceInfo(dcsource_info);
#endif
    ieee_send (DCSOURCE, ss, &status);
		errorflag |= status;
		enter (r,MAXLEN,&length,DCSOURCE,&status);
#ifdef DEBUG
		sprintf (dcsource_info,"Receiving from DCSource: '%s'\n", r);
                OutputDCSourceInfo(dcsource_info);
#endif
    errorflag |= status;
    for (int j=0; j<11; j++) ss[j]=r[3+j];	// copy string without first 3 characters
    ss[11]='\n';                                // terminate string
    sscanf(ss, "%f\n", value);                 // read value from string ss to double value
  }
}





/*
//-----------------------------------------------------------
//  Sweeps Voltage at PIN2 and measures at PIN1
//-----------------------------------------------------------

//-----------------------------------------------------------
//  Sweeps Voltages at PIN2 and PIN3 and measures at PIN1
//-----------------------------------------------------------

int TGPIB_DCSource::SweepTwoVoltages (double b[600], double a[8][MAXDATA],
	int pin1, int pin2, int pin3, double start1, double stop1, double step1, double start2,
	double stop2,int type, double maxcurr1, double maxcurr2, int curve)
{
  char ss[40], r[MAXLEN];
  double value;
  int i, k, length, j, w;
  Port port;
  start1 += offset; stop1 += offset;
  start2 += offset; stop2 += offset;

  if ((pin1<0) || (pin1>MAXPIN) || (pin2<0) || (pin2>MAXPIN) || (pin3<0) || (pin3>MAXPIN) )
       OutputDCSourceInfo("Illegal terminal in function DCSource_Sweep");
  else {
     // Voltage Sweep on PIN2

     sprintf(ss, "WV%1d,%1d,1,%1.5G,%1.3E,%1.3G,%1.5G;", PortAss[pin2],
          type, start1, stop1, step1, maxcurr1);

     // fix voltage range to 100V (third argument is 3 in ieee_send-command)
     // fix voltage range to 20 V:(third argument is 1 in ieee_send-command)

#ifdef DEBUG
    sprintf (dcsource_info,"Sending to DCSource: '%s'", ss);
    OutputDCSourceInfo(dcsource_info);
#endif
    ieee_send (DCSOURCE, ss, &status);
    errorflag |= status;

    // Voltage Sweep on PIN3

    sprintf(ss, "WP%1d,1,%1.5G,%1.3E,%1.5G;", PortAss[pin3], start2,
        stop2, maxcurr2);                              // WP=2nd sweep channel

#ifdef DEBUG
    sprintf (dcsource_info,"Sending to DCSource: '%s'", ss);
    OutputDCSourceInfo(dcsource_info);
#endif
    ieee_send (DCSOURCE, ss, &status);
    errorflag |= status;
 }
    port = PortAss[pin1];
    if ((port==VS1) || (port==VS2))
        OutputDCSourceInfo("Illegal port in function DCSource_MeasureVoltage");
    else {
      if     (port<=SMU4) sprintf(ss, "MC%1d,1;", port);
      else    sprintf(ss, "MC%1d,1;", port -3);  // Monitor Channel PIN1 for measurement
    }

#ifdef DEBUG
    sprintf (dcsource_info,"Sending to DCSource: '%s'", ss);
    OutputDCSourceInfo(dcsource_info);
#endif
    ieee_send (DCSOURCE, ss, &status);
    ieee_send (DCSOURCE, "WS0;", &status);
    enter (r,MAXLEN,&length,DCSOURCE,&status);

#ifdef DEBUG
    sprintf (dcsource_info,"Receiving from DCSource: '%s'", r);
    OutputDCSourceInfo(dcsource_info);
#endif
    i=3;
    k=0;
    while (i<length)
    {
      if (r[i-3] != 'N') OutputDCSourceInfo("Status:");
      if (r[i-3] == 'T') OutputDCSourceInfo("Another channel reached compliance !!!");
      if (r[i-3] == 'C') OutputDCSourceInfo("Measuring channel reached compliance !!!");
      for (j=0; j<11; j++) ss[j]=r[i+j];
      ss[11]='\n';
      sscanf(ss, "%f\n", &value);
      a[curve][k]=value;
      i+=15;
      k+=1;
    }
    for (w=0; w<=(stop1-start1)/step1+1; w++)  b[w]=start1+w*step1;
    return(k);
}
*/




//-----------------------------------------------------------
/*    Ausblenden

void TGPIB_DCSource::SetCurrentMeasurementRange (int pin, int range)
{
	char ss[40], r[40];
	Port port;
	int length;

	port = PortAss[pin];
	if ((port<SMU1) || (port>SMU4))
		printf("Illegal port in function DCSource_MeasureCurrent\n");
	else {
		sprintf(ss, "RI%1d,%1d", port, range);
		ieee_send (DCSOURCE, ss, &status);
	}
}


//-----------------------------------------------------------

void DCSource_MeasureVoltage (int pin, double *value)
{
  char ss[40], r[40];
  Port port;
  int length;

  port = PortAss[pin];
  if ((port==VS1) || (port==VS2))
    printf("Illegal port in function DCSource_MeasureVoltage\n");
  else {
    if (port<=SMU4)
      sprintf(ss, "TV%1d", port);
    else
      sprintf(ss, "TV%1d", port-3);  // these are the VMs
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
		errorflag |= status;
    enter (r,MAXLEN,&length,DCSOURCE,&status);
#ifdef DEBUG
    printf ("Receiving from DCSource: '%s'\n", r);
#endif
    errorflag |= status;
    for (int j=0; j<11; j++) ss[j]=r[3+j];	// copy string without first 3 characters
    ss[12]='\n';                                // terminate string
    sscanf(ss, "%f\n", value);                 // read value from string ss to double value
  }
}


//-----------------------------------------------------------

int TGPIB_DCSource::SweepVds (double b[600], double a[5][MAXDATA], int pin,
 double start, double stop, double step, int type, double maxcurr, int curve)

{
  char ss[40], r[MAXLEN];
  double value;
  int i, k, length, j, w;

  if ((pin<0) || (pin>MAXPIN))
    printf("Illegal terminal in function DCSource_Sweep\n");
  else {
	       //WV = Voltage Sweep Setup
    sprintf(ss, "WV%1d,%1d,1,%1.5G,%1.3E,%1.3G,%1.5G;",
	       PortAss[pin], type, start, stop, step, maxcurr);
	      //fix voltage range to 20V (third argument is 1)
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
    errorflag |= status;
       }
	       //MC = Monitor Channel
    sprintf(ss, "MC%1d,1;", PortAss[pin]);
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
		   //WS = Sweep Start ( 0 = Sweep source data not returned )
    ieee_send (DCSOURCE, "WS0;", &status);
		enter (r,MAXLEN,&length,DCSOURCE,&status);
#ifdef DEBUG
    printf ("Receiving from DCSource: '%s'\n", r);
#endif
    i=3;
    k=0;
    while (i<length)
    {
      for (j=0; j<11; j++) ss[j]=r[i+j];  // copy one number (as string)
      ss[12]='\n';
      sscanf(ss, "%f\n", &value);
      a[curve][k]=value;
//      printf("%f\n", value);
      i+=15;
       k+=1;
    }
    for (w=0; w<=(stop-start)/step+1; w++)
    { b[w]=start+w*step;
    }
    return(k);
}


//-----------------------------------------------------------

int DCSource_SweepIs (double b[600], double a[5][MAXDATA], int pin1, int pin2,
  double start, double stop, double step, int type, double maxcurr, int curve)
{
  char ss[40], r[MAXLEN];
  double value;
  int i, k, length, j, w;

  if ((pin1<0) || (pin1>MAXPIN) || (pin2<0) || (pin2>MAXPIN))
    printf("Illegal terminal in function DCSource_Sweep\n");
  else {
    sprintf(ss, "WV%1d,%1d,3,%1.5G,%1.3E,%1.3G,%1.5G;", PortAss[pin2],
     type, start, stop, step, maxcurr);
     // fix voltage range to 100V (third argument is 3 in ieee_send-command)
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
    errorflag |= status;
       }

    sprintf(ss, "MC%1d,1;", PortAss[pin1]);
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
    ieee_send (DCSOURCE, "WS0;", &status);
    enter (r,MAXLEN,&length,DCSOURCE,&status);
#ifdef DEBUG
    printf ("Receiving from DCSource: '%s'\n", r);
#endif
    i=3;
    k=0;
    while (i<length)
    {
      if (r[i-3] != 'N') printf("Status:");
      if (r[i-3] == 'T') printf("Another channel reached compliance !!!");
      if (r[i-3] == 'C') printf("Measuring channel reached compliance !!!");
      for (j=0; j<11; j++) ss[j]=r[i+j];
      ss[11]='\n';
      sscanf(ss, "%f\n", &value);
      a[curve][k]=value;
//      printf("%.4E\n", value);
      i+=15;
      k+=1;
    }
    for (w=0; w<=(stop-start)/step+1; w++)
    { b[w]=start+w*step;
    }
    return(k);
}
*/

/*
//-----------------------------------------------------------
//  Sweeps Current at PIN2 and measures at PIN1
//-----------------------------------------------------------

int DCSource_SweepCurrent (double b[600], double a[5][MAXDATA],
	int pin1, int pin2, double start, double stop, double step,
	int type, double maxvolt, int curve)
{
  char ss[40], r[MAXLEN];
  double value;
  int i, k, length, j, w;
  Port port;

  if ((pin1<0) || (pin1>MAXPIN) || (pin2<0) || (pin2>MAXPIN))
    printf("Illegal terminal in function DCSource_Sweep\n");
  else {
     // Sweep Current on PIN2
    sprintf(ss, "WI%1d,%1d,1,%1.5G,%1.3E,%1.3G,%1.5G;", PortAss[pin2],
     type, start, stop, step, maxvolt);
     // fix voltage range to 20V (third argument is 1 in ieee_send-command)
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
    errorflag |= status;
       }

  port = PortAss[pin1];
  if ((port==VS1) || (port==VS2))
    printf("Illegal port in function DCSource_MeasureVoltage\n");
  else {
    if (port<=SMU4)
      sprintf(ss, "MC%1d,1;", port);
    else
     // Monitor Channel PIN1 for measurement
    sprintf(ss, "MC%1d,1;", port -3);
       }
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
     // Sweep Start;0=Sweep source data not returned
    ieee_send (DCSOURCE, "WS0;", &status);
    enter (r,MAXLEN,&length,DCSOURCE,&status);
#ifdef DEBUG
    printf ("Receiving from DCSource: '%s'\n", r);
#endif
    i=3;
    k=0;
    while (i<length)
    {
      if (r[i-3] != 'N') printf("Status:");
      if (r[i-3] == 'T') printf("Another channel reached compliance !!!");
      if (r[i-3] == 'C') printf("Measuring channel reached compliance !!!");
      if (r[i-3] == 'X') printf("Measuring channel is oscillating !!!");
      if (r[i-3] == 'V') printf("AD-Converter is saturated +-150V !!!");
      if (r[i-3] == 'D') printf("SMU-Shutdown !!!");
      for (j=0; j<11; j++) ss[j]=r[i+j];
      ss[11]='\n';
      sscanf(ss, "%f\n", &value);
      a[curve][k]=value;
//      printf("%.4E\n", value);
      i+=15;
      k+=1;
    }
    for (w=0; w<=(stop-start)/step+1; w++)
    { b[w]=start+w*step;
    }
    return(k);
}


//-----------------------------------------------------------

int DCSource_SweepVbs (double b[600], double a[5][MAXDATA], int pin1, int pin2,
 double start, double stop, double step, int type, double maxcurr, int curve)
// fix voltage range to 20V (third argument is 1 in ieee_send-command)
{
  char ss[40], r[MAXLEN];
  double value;
  int i, k, length, j, w;

  if ((pin1<0) || (pin1>MAXPIN) || (pin2<0) || (pin2>MAXPIN))
    printf("Illegal terminal in function DCSource_Sweep\n");
  else {
    sprintf(ss, "WV%1d,%1d,1,%1.5G,%1.3E,%1.3G,%1.5G;", PortAss[pin2], type,
     start, stop, step, maxcurr);
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
    errorflag |= status;
       }

    sprintf(ss, "MC%1d,1;", PortAss[pin1]);
#ifdef DEBUG
    printf ("Sending to DCSource: '%s'\n", ss);
#endif
    ieee_send (DCSOURCE, ss, &status);
    ieee_send (DCSOURCE, "WS0;", &status);
    enter (r,MAXLEN,&length,DCSOURCE,&status);
#ifdef DEBUG
    printf ("Receiving from DCSource: '%s'\n", r);
#endif

    i=3;
    k=0;
    while (i<length)
    {
      for (j=0; j<11; j++) ss[j]=r[i+j];  // copy one number (as string)
      ss[12]='\n';
      sscanf(ss, "%f\n", &value);
      a[curve][k]=value;                          // result[x][y]=value
//      printf("%.4E\n", value);
      i+=15;
      k+=1;
    }
    for (w=0; w<=(stop-start)/step+1; w++)
    { b[w]=start+w*step;
    }
    return(k);
}


//-----------------------------------------------------------
*/  // Ausblenden Ende

//-----------------------------------------------------------

