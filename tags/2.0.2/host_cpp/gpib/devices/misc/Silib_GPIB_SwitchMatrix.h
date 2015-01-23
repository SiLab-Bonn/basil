#ifndef SILIB_GPIB_SwitchMatrix_H
#define SILIB_GPIB_SwitchMatrix_H

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"
#include "SILIB_GPIB_DCSource.h"   // for Port definition

const int SWITCHMATRIX = 22;  // GPIB address of switch matrix

const int MAXPIN       = 12;  // Check this ??? Is it 24 ???

typedef int Pin;              // for type checking and readability


class TGPIB_SwitchMatrix: public TGPIB_Device
{
public:
   TGPIB_SwitchMatrix  (TGPIB_Interface * If, int id = SWITCHMATRIX);

   void Clear          (void);

   void DisconnectAll  (void);
   void Disconnect     (Port pt);
   void Connect        (Pin pi, Port pt);


   Port GetPort        (Pin pi);

// void Relaytest      (void);

private:
   bool DeviceResponds ();           // Test if device responds
private:
   Port PortAss [MAXPIN];
};

#endif
