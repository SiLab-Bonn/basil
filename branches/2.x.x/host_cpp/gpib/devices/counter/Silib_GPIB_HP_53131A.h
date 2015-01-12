#ifndef SILIB_GPIB_HP_53131A_H
#define SILIB_GPIB_HP_53131A_H

#include "SILIB_GPIB_Interfaces.h"
#include "SILIB_GPIB_Device.h"

const int GPIB_ID_HP_53131A = 3;


class TGPIB_HP_53131A: public TGPIB_Device
{
public:
          TGPIB_HP_53131A    (TGPIB_Interface * If, int id = GPIB_ID_HP_53131A);



          
private:
   bool   DeviceResponds     ();           // Test if device responds
};

#endif
