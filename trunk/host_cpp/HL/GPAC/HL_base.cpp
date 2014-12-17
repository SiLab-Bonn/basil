#include "HL_base.h"


HL_I2CMaster::HL_I2CMaster(TL_base &TL)
{
	mTL = &TL;
}

void HL_I2CMaster::SetTLhandle(TL_base &TL)
{
	mTL = &TL;
}

HL_base::HL_base(TL_base &TL): HL_I2CMaster(TL)
{
}
