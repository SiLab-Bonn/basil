#ifndef SILIB_GPIB_Device_H
#define SILIB_GPIB_Device_H

#include "Silib_GPIB_Interfaces.h"

enum TVoltageUnit {VOLT, MILLIVOLT, MICROVOLT};
enum TCurrentUnit {AMP,  MILLIAMP,  MICROAMP, NANOAMP};

//----------------------------------------------------------------------------
// general GPIB device
//----------------------------------------------------------------------------

class TGPIB_Device
{
public:
                    TGPIB_Device   (TGPIB_Interface * If, int Id);
  std::string        GetName();
  bool              isOk; 
  void              Send           (std::string Str); // Error checked in Interface
protected:
  std::string        SendAndReceive (std::string Str); // return false if error
  std::string        Receive ();
  byte *            ReceiveBinary  (byte* data, int size);
  void							ResetAndClear(); // performs reset and clear on device

  void              ErrorMsg       (std::string Msg);

  TGPIB_Interface * MyIf;                            // My interface
  int               MyId;                            // My GPIB Id
  std::string        MyName;                          // My Name (like 'Keithley2000')
};

#endif
