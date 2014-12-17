#include "Silib_GPIB_SwitchMatrix.h"


TGPIB_SwitchMatrix::TGPIB_SwitchMatrix (TGPIB_Interface * If, int id) :TGPIB_Device (If, id)
{
	std::stringstream ss;
	ss << "HP Switch Matrix with ID = " << MyId;
  MyName   = ss.str();

  if (!DeviceResponds()) {
    ErrorMsg("Device does not respond!");
    MyIf = NULL;
  }
}

bool TGPIB_SwitchMatrix::DeviceResponds()
{
  std::string GoodResult = "Text";
  std::string Result = SendAndReceive("ID \n");
//  return (Result == GoodResult);
	return true;
}


void TGPIB_SwitchMatrix::Clear (void)
{
  Send ("CL");
}

void TGPIB_SwitchMatrix::DisconnectAll (void)
{
  char ss[10];
  for(int i=0; i<MAXPIN; i++) {     // use MAXPIN here ???
    sprintf(ss,"PC%1dON00 \n", i);
    Send (std::string(ss));
  }
}  


void TGPIB_SwitchMatrix::Disconnect (Port p)
{
   char ss[10];
   sprintf(ss,"PC%1dON00 \n",(int) p);
   Send (std::string(ss));
}

//   connect pin on Switch Matrix (from 1 to 12) with a port
//   of the DC source (e.g. SMU1, VM1 or GNDU)

void TGPIB_SwitchMatrix::Connect (Pin pi, Port pt)
{
  char ss[12];
  if ((pi<1) || (pi>MAXPIN) || (pt<0) || (pt>10))
  ;
  //    OutputMatrixInfo("Illegal command code in function Matrix_Connect");
  else {
    PortAss [pi] = pt;	// remember which port this pin is connected to (for later use)
    sprintf(ss, "PC%1dON%02d \n", (int) pt, 2*pi);
    Send (std::string(ss));
  }
}

Port TGPIB_SwitchMatrix::GetPort (Pin pi)
{
  if ((pi<1) || (pi>MAXPIN))
    return Port(0);
// error
  else
    return PortAss[pi];
}


/*
void TGPIB_SwitchMatrix::Matrix_Relaytest (void)
{
  char ss[10],r[MAXLEN];
  int length;

  sprintf(ss,"TS");
  ieee_send (MATRIX, ss, &status);
  errorflag |= status;
  sprintf(ss,"TR");
  ieee_send (MATRIX, ss, &status);
  enter (r,MAXLEN,&length,MATRIX,&status);
}
*/
