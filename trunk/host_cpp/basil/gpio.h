#pragma once
#include "HL_base.h"

class gpio :public HL_base
{
public:
	gpio(TL_base &TL);
	~gpio(void);
};

