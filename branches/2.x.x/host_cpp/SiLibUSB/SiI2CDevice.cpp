#include "SiI2CDevice.h"

//---------------------------------------------------------------------------
//   class TI2CDevice
//
//   generic I2C access
//
//---------------------------------------------------------------------------
//

TI2CDevice::TI2CDevice(TI2CMaster *Master)
{
	I2CMaster = Master;
}


//---------------------------------------------------------------------------
//   class TI2Eeprom
//
//   I2C EEPROM
//
//---------------------------------------------------------------------------
//
// EEPROM slave address unsigned char:   | 1 | 0 | 1 | 0 | A2| A1| A0|R/~W|
//
// Access depends on the EEPROM address space (single or double unsigned char):
//    single unsigned char addressing:   |S|slave add|A|  add   |A|  data |A|P|
//    double unsigned char addressing:   |S|slave add|A|high add|A|low add| data |A|P|
//
//---------------------------------------------------------------------------


TI2CEeprom::TI2CEeprom(unsigned char DevAdd, bool isDoubleByteAdd, TI2CMaster *Master):
TI2CDevice(Master)
{
	SlaveAdd = (unsigned char)(I2C_DEV_TYPE_EEPROM | (0x0e & (DevAdd << 1)));

	isDoubleByte = isDoubleByteAdd;
	if (isDoubleByte)
		AddLength = 2;
	else
		AddLength = 1;
}

bool
TI2CEeprom::WriteByte(unsigned short Add, unsigned char *Data)
{
	unsigned char AddData[3];
	unsigned char i = 0;

	if (isDoubleByte)
		AddData[i++] = MSB (Add);
	AddData[i++] = LSB (Add);
	AddData[i++] = *Data;
	return (I2CMaster->WriteI2Cnv(SlaveAdd , AddData, AddLength+1));
}

bool
TI2CEeprom::ReadByte(unsigned short Add, unsigned char *Data)
{
	unsigned char AddData[2];
	unsigned char i = 0;

	if (isDoubleByte)
		AddData[i++] = MSB (Add);
	AddData[i++] = LSB (Add);
	return(I2CMaster->WriteI2C(SlaveAdd, AddData, AddLength) &
		I2CMaster->ReadI2C(SlaveAdd | 0x01, Data, 1));
}

//---------------------------------------------------------------------------
//   class TI2Pot
//
//   I2C Digital Potentiometer  (Xicor X9582)
//
//---------------------------------------------------------------------------
//
// DigPot slave address unsigned char:   | 0 | 1 | 0 | 1 | A3| A2| A1| A0|
//
//    two unsigned char write instruction:     |S|slave add|A|  instr |A|P|
//    three unsigned char write instruction:   |S|slave add|A|  instr |A| data |A|P|
//
//    instruction unsigned char:         | I3| I2| I1| I0| R1| R0| P1| P0|
//                                Instruction     RegId    PotId
//
//---------------------------------------------------------------------------
// to do:   implement read access

TI2CPot::TI2CPot(unsigned char DevAdd, TI2CMaster *Master):
TI2CDevice(Master)
{
	SlaveAdd = (unsigned char)(I2C_DEV_TYPE_POT | (0x0f & DevAdd));

	if(I2CMaster != NULL)
	{
		GlobalXFRReg2Whiper(0);
		isOk = I2CMaster->I2CAck();
	}
	isOk = false;
}

TI2CPot::~TI2CPot()
{
	if (isOk)
		GlobalXFRWhiper2Reg(0);
}

bool
TI2CPot::SetWhiper(unsigned char PotId, unsigned char *Data)
{
	unsigned char InstrData[2];

	InstrData[0] = (unsigned char) (X9582_INSTR_SETWHIPER | (0x0f & PotId));
	InstrData[1] = *Data;
	return (I2CMaster->WriteI2C(SlaveAdd, InstrData, 2));
}

bool
TI2CPot::SetRegister(unsigned char PotId, unsigned char RegId, unsigned char *Data)
{
	unsigned char InstrData[2];

	InstrData[0] = (unsigned char) (X9582_INSTR_SETREGISTER | (0x0f & PotId) | (0xf0 & (RegId << 4)));
	InstrData[1] = *Data;
	return (I2CMaster->WriteI2Cnv(SlaveAdd, InstrData, 2));
}

bool
TI2CPot::XFRReg2Whiper(unsigned char PotId, unsigned char RegId)
{
	unsigned char InstrData;

	InstrData = (unsigned char) (X9582_INSTR_XFRR2W | (0x0f & PotId) | (0xf0 & (RegId << 4)));
	return (I2CMaster->WriteI2C(SlaveAdd, &InstrData, 1));
}

bool
TI2CPot::XFRWhiper2Reg(unsigned char PotId, unsigned char RegId)
{
	unsigned char InstrData;

	InstrData = (unsigned char) (X9582_INSTR_XFRW2R | (0x0f & PotId) | (0xf0 & (RegId << 4)));
	return (I2CMaster->WriteI2Cnv(SlaveAdd, &InstrData, 1));
}

bool
TI2CPot::GlobalXFRReg2Whiper(unsigned char RegId)
{
	unsigned char InstrData;

	InstrData = (unsigned char) (X9582_INSTR_GXFRR2W | (0xf0 & (RegId << 4)));
	return (I2CMaster->WriteI2C(SlaveAdd, &InstrData, 1));
}

bool
TI2CPot::GlobalXFRWhiper2Reg(unsigned char RegId)
{
	unsigned char InstrData;

	InstrData = (unsigned char) (X9582_INSTR_GXFRW2R | (0xf0 & (RegId << 4)));
	return (I2CMaster->WriteI2Cnv(SlaveAdd, &InstrData, 1));
}

//---------------------------------------------------------------------------
//   class TI2Adc
//
//   I2C ADC (MAX 127/128)
//
//---------------------------------------------------------------------------
//
//   ADC slave address unsigned char:    | 0 | 1 | 0 | 1 | A2| A1| A0|R/~W|
//
//    write control unsigned char:       |S|slave add|A| control |A|P|
//        read ADC value:       |S|slave add|A|high unsigned char|A|low nipple 0000|A|P|
//
//          control unsigned char:       | 1|SEL2|SEL1|SEL0| RNG| BIP| PD1| PD0|
//                                ^       ch#      range pol  power down
//                            start conv.
//
//                               RNG BIP
//   unipolar half input range:   0   0     0 - 5  (0 - Vref/2)   MAX127 (Max128)
//   unipolar full input range:   1   0     0 - 10 (0 - Vref)     MAX127 (Max128)
//    bipolar half input range:   0   1     +- 5   (+- Vref/2)    MAX127 (Max128)
//    bipolar full input range:   1   1     +- 10  (+- Vref)      MAX127 (Max128)
//---------------------------------------------------------------------------
// to do:   implement power down mode

TI2CAdc::TI2CAdc(unsigned char DevAdd, bool IsFullInputRange, bool IsBipolar, TI2CMaster * Master):
TI2CDevice(Master)
{
	SlaveAdd = (unsigned char)(I2C_DEV_TYPE_ADC | (0x0e & DevAdd));

	SetRangeAndPolarity(IsFullInputRange, IsBipolar);

	if (IsFullInputRange)
		Gain = 10000.0 / 4095.0;
	else
		Gain = 5000.0 / 4095.0;

	Offset = 0;
}

bool
TI2CAdc::GetVoltage(unsigned char ChId, double *Val)
{
	unsigned char Data[2];
	bool status = false;
	unsigned char Instr = (unsigned char) (MAX127_CTRL_START | (ChId << 4) | ControlByte);

	status |= I2CMaster->WriteI2C(SlaveAdd, &Instr, 1);     // select channel and start conversion
	status |= I2CMaster->ReadI2C(SlaveAdd | 0x01, Data, 2); // read data bytes
	*Val = Gain * (((Data[0] << 8) + (0xF0 & Data[1])) >> 4) + Offset;
	//  *Val = ((Data[0] << 8) + (0xF0 & Data[1])) >> 4;

	return (status);
}

void
TI2CAdc::SetGain(double sGain)
{
	Gain = sGain;
}

void
TI2CAdc::SetOffset(double sOffset)
{
	Offset = sOffset;
}

double
TI2CAdc::GetGain()
{
	return (Gain);
}

double
TI2CAdc::GetOffset()
{
	return (Offset);
}

void
TI2CAdc::SetRangeAndPolarity(bool IsFullInputRange, bool IsBipolar)
{
	ControlByte = 0;
	if (IsFullInputRange)
		ControlByte |= MAX127_CTRL_RNG;
	if (IsBipolar)
		ControlByte |= MAX127_CTRL_BIPOL;
}

TI2CClockGen::TI2CClockGen(TI2CMaster * Master, double mfref): TI2CDevice(Master)
{
	SlaveAdd = 0x69 << 1;
	fref = mfref;
	// dummy read/write to check presence of device
	SetRegister(CG_ADD_CHG_PB, GetRegister(CG_ADD_CHG_PB));
	isOk = I2CMaster->I2CAck();
	/*  if(!isOk)
	ShowMessage("Clock Generator not available!");
	*/

	SetRegister(CG_ADD_CLKOE, CG_CLK5_EN | CG_LCLK1_EN);  // enable CLK 5 and LCLK1 clock output
	SetRegister(CG_ADD_INPDRV, 0x28);       // set input drive for external clock
	SetRegister(CG_ADD_INPCAP, 0x00);       // no input cap. for xtal osc.

}

bool
TI2CClockGen::SetRefClockFrequency(double f)
{
	fref = f;
	return true;
}

bool
TI2CClockGen::CalculatePLLParameters(double f)
{
	p_total   = 0;
	q_total   = 0;
	p_0       = 0;

	div1SRC = 0;
	div2SRC = 0;

	double q_d_f;


	//                fout = fref * (p_total / q_total) * (1 / div)
	//
	//                p_total = 2 * ((p_counter + 4) + p_0)     [16..1023]
	//                q_total = q_counter + 2                   [2..129]
	//                div = [2,(3),4..127]
	//
	//    constraints:
	//
	//    f_ref * p_total / q_total = [100..400] MHz
	//    f_ref / q_total > 0.25 MHz


	fout = f;


	for (q_counter = 0; q_counter < 128; q_counter++)
	{
		q_total = q_counter + 2;
		if ((fref / q_total) < 0.25)  // PLL constraint
			break;
		for (div = 2; div < 128; div ++)
		{
			q_d_f = q_total * div * fout;
			if (IS_INTEGER(q_d_f) && (q_d_f > (15 * fref)))  // = f0 * p
			{
				if((int)q_d_f % (int)fref == 0)     // p,q and d found, check constraints on p
				{
					p_total = (int)q_d_f / (int)fref;

					while (p_total <= 16)      // counter constraint
					{   // inc p_total and div
						p_total *= 2;
						div *= 2;
						if (div > 127)
							break;
						if (p_total > 1023)   // counter constraint
							break;
					}
					if (((fref * p_total / q_total) < 100) || ((fref * p_total / q_total) > 400))  // PLL constraint
						break;

					// set p counter register
					((p_total % 2) == 0) ? p_0 = 0 : p_0 = 1;
					p_counter = ((p_total - p_0)/2) - 4;

					// set pots divider register, divider bank 1 only implemented yet
					if(div == 2)
					{
						clk1SRC = 0x02;
						div1N   = 4;
					}
					else
						if (div == 3)
						{
							clk1SRC = 0x03;
							div1N   = 6;
						}
						else
						{
							clk1SRC = 0x01;
							div1N   = div;
						}


						if (p_total <= 44)
							chg_pump = 0;
						else
							if (p_total <= 479)
								chg_pump = 1;
							else
								if (p_total <= 639)
									chg_pump = 2;
								else
									if (p_total <= 799)
										chg_pump = 3;
									else
										if (p_total <= 1023)
											chg_pump = 4;

						return true;
				}
			}
		}
	}


	return false;
}

void
TI2CClockGen::UpdatePLLRegisters()
{
	unsigned char temp;

	temp = (div1SRC << 7) | div1N;  // post divider 1
	WriteByte(CG_ADD_DIV1, &temp);

	div2N = 8;  // not used default
	temp = (div2SRC << 7) | div2N;  // post divider 2 (not used yet)
	WriteByte(CG_ADD_DIV2, &temp);

	temp = 0xc0 | ((0x07 & chg_pump) << 2) | ((0x0300 & p_counter) >> 8);    // charge pump & p counter
	WriteByte(CG_ADD_CHG_PB, &temp);

	temp = (unsigned char)(0xff & p_counter);
	WriteByte(CG_ADD_PB, &temp);   // p counter

	temp = ((0x01 & p_0) << 7) | (0x07f & q_counter);
	WriteByte(CG_ADD_PO_Q, &temp);   // p_0 and q counter

	temp = (clk1SRC << 5);
	WriteByte(CG_ADD_XS1, &temp);  // clock source LCLK 1

	temp = (clk1SRC << 1);
	WriteByte(CG_ADD_XS2, &temp);  // clock source CLK 5

	temp = 0x3f;
	WriteByte(CG_ADD_XS3, &temp);  // clock source CLK 6

}

bool
TI2CClockGen::SetFrequency(double f)
{
	if (!CalculatePLLParameters(f))
	{
		last_status = false;
		return false;
	}

	UpdatePLLRegisters();

	last_status = true;
	return true;
}

bool
TI2CClockGen::SetRegister(unsigned char add, unsigned char data)
{
	return WriteByte(add, &data);
}

unsigned char
TI2CClockGen::GetRegister(unsigned char add)
{
	unsigned char data;
	ReadByte(add, &data);
	return data;
}

bool
TI2CClockGen::ReadByte(unsigned char add, unsigned char *data)
{
	I2CMaster->WriteI2C(SlaveAdd, &add, 1);
	return I2CMaster->ReadI2C(SlaveAdd | 0x01, data, 1);
}

bool
TI2CClockGen::WriteByte(unsigned char add, unsigned char *data)
{
	unsigned char payload[2];

	payload[0] = add;
	payload[1] = *data;

	return I2CMaster->WriteI2C(SlaveAdd, payload, 2);
}
