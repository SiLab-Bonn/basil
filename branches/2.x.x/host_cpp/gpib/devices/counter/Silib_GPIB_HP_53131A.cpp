#include <vcl.h>
#include "SILIB_GPIB_HP_53131A.h"

#include <math.h>    // for fabs

TGPIB_HP_53131A::TGPIB_HP_53131A (TGPIB_Interface * If, int id): TGPIB_Device (If, id)
{
  MyName = "HP Counter 53131A with ID = " + std::string (MyId);

  if (!DeviceResponds()) {
    Application->MessageBox(MyName.c_str(), "Device does not respond!", MB_ICONWARNING);
    MyIf->RemoveDevice(MyId);
  }


}

bool TGPIB_HP_53131A::DeviceResponds()
{
  std::string GoodResult = "HEWLETT-PACKARD,53131A";
  std::string Result = SendAndReceive("*IDN?").SetLength (GoodResult.Length());

  return (Result == GoodResult);
}

