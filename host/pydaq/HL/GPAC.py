from HL.HardwareLayer import HardwareLayer
from BitVector import BitVector


class GPAC(HardwareLayer):

    #DACS
    DAC7578_1_ADD = 0x90  # slave addresses
    DAC7578_2_ADD = 0x94
    DAC7578_3_ADD = 0x98
    DAC7578_CMD_UPDATE_CH = 0x30  # load DAC register (n -> [2:0]) and update DAC

    # GPIO extension (PCA9554)
    PCA9554_ADD = 0x40    # generic slave address
    PCA9554_CFG = 0x03    # configuration register: 1->input (default), 0->output
    PCA9554_OUT = 0x01    # output port register
    PCA9554_IN = 0x00    # input port register

    POWER_GPIO_ADD = PCA9554_ADD | 0x02
    POWER_GPIO_CFG = 0xf0  # LSB -> ON, MSB-> OC (over current read back)

    ADCMUX_GPIO_ADD = PCA9554_ADD
    ADCMUX_GPIO_CFG = 0x00  # all outputs

    #I2C BUS MUX
    PCA9540B_ADD = 0xE0  # slave address
    PCA9540B_SEL_CH0 = 0x04  # select channel 0
    PCA9540B_SEL_CH1 = 0x05  # select channel 1
    PCA9540B_SEL_NONE = 0x00  # de-select channels

    I2CBUS_ADC = PCA9540B_SEL_CH1
    I2CBUS_DAC = PCA9540B_SEL_CH0
    I2CBUS_DEFAULT = PCA9540B_SEL_NONE

    #ADC
    MAX11644_ADD = 0x6C  # slave address
    # setup register
    MAX11644_SETUP = 0x80  # defines setup register access
    MAX11644_EXT_REF = 0x20  # select external reference (2.048V)
    MAX11644_INT_REF = 0x50  # select internal reference (4.096V)
    MAX11644_EXT_CLK = 0x08  # select external clock (SCL)
    # configuration register
    MAX11644_SCAN_SINGLE = 0x60  # convertGet selected channel only
    MAX11644_SCAN_SINGLE8 = 0x20  # convert selected channel 8 times
    MAX11644_SCAN = 0x00  # convert channel 0 - CS0 (default)
    MAX11644_CS0 = 0x02  # set scan range to channel 1
    MAX11644_SGL = 0x01  # sets single-ended mode conversion

    ADC_CONF = MAX11644_SCAN | MAX11644_SGL | MAX11644_CS0  # single-ended inputs, conversion of both channels in a scan

    CURRENT_LIMIT_DAC_CH = 0
    CURRENT_LIMIT_DAC_SLAVE_ADD = DAC7578_1_ADD

    _cal = {'PWR0': {
                      'DACV': {'offset': 2815.0, 'gain': -0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 20},
                    },
            'PWR1': {
                      'DACV': {'offset': 2821.0, 'gain': -0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 20},
                    },
            'PWR2': {
                      'DACV': {'offset': 2831.0, 'gain': -0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 20},
                    },
            'PWR3': {
                      'DACV': {'offset': 2831.0, 'gain': -0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 20},
                    },

            'ISRC0': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'ISRC1': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'ISRC2': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'ISRC3': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'ISRC4': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'ISRC5': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'ISRC6': {
                      'DACI': {'offset': -1024, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },

            'VSRC0': {
                      'DACV': {'offset': 0, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },
            'VSRC1': {
                      'DACV': {'offset': 0, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },
            'VSRC2': {
                      'DACV': {'offset': 0, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },
            'VSRC3': {
                      'DACV': {'offset': 0, 'gain': 0.5},
                      'ADCV': {'offset': 0, 'gain': 2},
                      'ADCI': {'offset': 0, 'gain': 2},
                    },
            'VREF': {
                      'ADCV': {'mux_ch': 0, 'adc_ch': 0},
                    },
            'AUX0': {
                      'ADCV': {'mux_ch': 9, 'adc_ch': 0},
                    },
            'INJ0': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 6},
                    },
            'INJ1': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 7},
                    },
            }

    _map = {'PWR0': {
                      'DACV': {'addr': DAC7578_1_ADD, 'channel': 1},
                      'ADCV': {'mux_ch': 16, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 16, 'adc_ch': 1},
                      'GPIOEN': {'bit': 0},
                      'GPIOOC': {'bit': 4},
                    },
            'PWR1': {
                      'DACV': {'addr': DAC7578_1_ADD, 'channel': 2},
                      'ADCV': {'mux_ch': 17, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 17, 'adc_ch': 1},
                      'GPIOEN': {'bit': 1},
                      'GPIOOC': {'bit': 5},
                    },
            'PWR2': {
                      'DACV': {'addr': DAC7578_1_ADD, 'channel': 3},
                      'ADCV': {'mux_ch': 18, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 18, 'adc_ch': 1},
                      'GPIOEN': {'bit': 2},
                      'GPIOOC': {'bit': 6},
                    },
            'PWR3': {
                      'DACV': {'addr': DAC7578_1_ADD, 'channel': 4},
                      'ADCV': {'mux_ch': 19, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 19, 'adc_ch': 1},
                      'GPIOEN': {'bit': 3},
                      'GPIOOC': {'bit': 7},
                    },
            'ISRC0': {
                      'DACI': {'addr': DAC7578_1_ADD, 'channel': 5},
                      'ADCV': {'mux_ch': 20, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 20, 'adc_ch': 1},
                    },
            'ISRC1': {
                      'DACI': {'addr': DAC7578_1_ADD, 'channel': 6},
                      'ADCV': {'mux_ch': 21, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 21, 'adc_ch': 1},
                    },
            'ISRC2': {
                      'DACI': {'addr': DAC7578_1_ADD, 'channel': 7},
                      'ADCV': {'mux_ch': 21, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 22, 'adc_ch': 1},
                    },
            'ISRC3': {
                      'DACI': {'addr': DAC7578_1_ADD, 'channel': 8},
                      'ADCV': {'mux_ch': 23, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 23, 'adc_ch': 1},
                    },
            'ISRC4': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 1},
                      'ADCV': {'mux_ch': 24, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 24, 'adc_ch': 1},
                    },
            'ISRC5': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 2},
                      'ADCV': {'mux_ch': 25, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 25, 'adc_ch': 1},
                    },

            'ISRC6': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 3},
                      'ADCV': {'mux_ch': 26, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 26, 'adc_ch': 1},
                    },
            'ISRC7': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 4},
                      'ADCV': {'mux_ch': 26, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 26, 'adc_ch': 1},
                    },
            'ISRC8': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 5},
                      'ADCV': {'mux_ch': 26, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 26, 'adc_ch': 1},
                    },
            'ISRC9': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 6},
                      'ADCV': {'mux_ch': 26, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 26, 'adc_ch': 1},
                    },
            'ISRC10': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 7},
                      'ADCV': {'mux_ch': 26, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 26, 'adc_ch': 1},
                    },
            'ISRC11': {
                      'DACI': {'addr': DAC7578_2_ADD, 'channel': 8},
                      'ADCV': {'mux_ch': 26, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 26, 'adc_ch': 1},
                    },
            'VSRC0': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 1},
                      'ADCV': {'mux_ch': 15, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 15, 'adc_ch': 1},
                    },

            'VSRC1': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 2},
                      'ADCV': {'mux_ch': 14, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 14, 'adc_ch': 1},
                    },

            'VSRC2': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 3},
                      'ADCV': {'mux_ch': 13, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 13, 'adc_ch': 1},
                    },

            'VSRC3': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 4},
                      'ADCV': {'mux_ch': 12, 'adc_ch': 0},
                      'ADCI': {'mux_ch': 12, 'adc_ch': 1},
                    },
            'VREF': {
                      'ADCV': {'mux_ch': 0, 'adc_ch': 0},
                    },
            'AUX0': {
                      'ADCV': {'mux_ch': 9, 'adc_ch': 0},
                    },
            'INJ0': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 6},
                    },
            'INJ1': {
                      'DACV': {'addr': DAC7578_3_ADD, 'channel': 7},
                    },
            }

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        #PWR GPIO
        self.SetI2CMux(self.I2CBUS_DAC)
        self._intf.write(self._base_addr + self.POWER_GPIO_ADD, (self.PCA9554_CFG, self.POWER_GPIO_CFG))
        self._intf.write(self._base_addr + self.POWER_GPIO_ADD, (self.PCA9554_OUT, 0x00))

        #ADC GPIO
        self.SetI2CMux(self.I2CBUS_ADC)
        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_CFG, 0x00))
        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_OUT, 0x00))

        #ADC
        adc_setup = self.MAX11644_EXT_REF | self.MAX11644_SETUP
        self._intf.write(self._base_addr + self.MAX11644_ADD, [adc_setup])

        self.SetI2CMux(self.I2CBUS_DEFAULT)

    def SetVoltage(self, channel, value, unit='mV'):

        DACOffset = self._cal[channel]['DACV']['offset']
        DACGain = self._cal[channel]['DACV']['gain']

        DACval = 0
        if unit == 'raw':
            DACval = value
        elif unit == 'V':
            DACval = (int)((value * 1000 - DACOffset) / DACGain)
        elif unit == 'mV':
            DACval = (int)((value - DACOffset) / DACGain)
        else:
            raise TypeError("Invalid unit type.")

        karg = self._map[channel]['DACV']
        #print 'DACval', DACval
        karg['value'] = (2 ** 12 - 1) if DACval > (2 ** 12) else DACval
        karg['value'] = 0 if DACval < 0 else DACval
        self.SetDACValue(**karg)

    def GetVoltage(self, channel, unit='mV'):

        karg = self._map[channel]['ADCV']
        raw = self.GetADCValue(**karg)

        #VADCOffset = 0
        #VADCGain = 2

        VADCOffset = self._cal[channel]['ADCV']['offset']
        VADCGain = self._cal[channel]['ADCV']['gain']

        #DACOffset = self._cal[channel]['ADCV']['offset']
        #DACGain = self._cal[channel]['ADCV']['gain']

        mV = (float)((raw - VADCOffset) / VADCGain)

        if unit == 'raw':
            return raw
        elif unit == 'V':
            return mV / 1000
        elif unit == 'mV':
            return mV
        else:
            raise TypeError("Invalid unit type.")

    def GetCurrent(self, channel, unit='mA'):

        karg = self._map[channel]['ADCI']
        raw = self.GetADCValue(**karg)

        #IADCOffset =    0.0;
        #IADCGain   =   20.0;

        IADCOffset = self._cal[channel]['ADCI']['offset']
        IADCGain = self._cal[channel]['ADCI']['gain']

        uA = 0

        if('SRC' in channel):
            rawV = self.GetVoltage(channel, unit='raw')
            uA = (float)((raw - rawV - IADCOffset) / IADCGain)
        else:
            uA = (float)((raw - IADCOffset) / IADCGain)

        if unit == 'raw':
            return raw
        elif unit == 'A':
            return uA / 1000000
        elif unit == 'mA':
            return uA / 1000
        elif unit == 'uA':
            return uA
        else:
            raise TypeError("Invalid unit type.")

    def Enable(self, channel, value):
        karg = self._map[channel]['GPIOEN']
        karg['value'] = value
        self.SetPowerGPIO(**karg)

    def GetOverCurrent(self, channel):
        return False if (self.GetPowerGPIO() & (0x01 << self._map[channel]['GPIOOC']['bit'])) else True

    def SetCurrentLimit(self, channel, value, unit='mA'):

        #TODO: add units / calibration
        CURRENT_LIMIT_GAIN = 20
        raw = value * CURRENT_LIMIT_GAIN

        self.SetDACValue(self.CURRENT_LIMIT_DAC_SLAVE_ADD, self.CURRENT_LIMIT_DAC_CH, raw)

    def SetCurrent(self, channel, value, unit='mA'):

        #DACOffset  = -1024.0;
        #DACGain    = 0.5;

        DACOffset = self._cal[channel]['DACI']['offset']
        DACGain = self._cal[channel]['DACI']['gain']

        DACval = 0
        if unit == 'raw':
            DACval = value
        elif unit == 'mA':
            DACval = (int)((value * 1000 - DACOffset) / DACGain)
        elif unit == 'uA':
            DACval = (int)((value - DACOffset) / DACGain)
        else:
            raise TypeError("Invalid unit type.")

        karg = self._map[channel]['DACI']
        karg['value'] = DACval
        self.SetDACValue(**karg)

    def SetI2CMux(self, bus_sel):
        self._intf.write(self._base_addr + self.PCA9540B_ADD, [bus_sel])

    def GetI2CMux(self):
        return self._intf.read(self._base_addr + self.PCA9540B_ADD | 1, 1)[0]

    def SetDACValue(self, addr, channel, value):
        self.SetI2CMux(self.I2CBUS_DAC)

        A = value >> 4 & 0xff
        B = value << 4 & 0xff

        data = (self.DAC7578_CMD_UPDATE_CH | channel, A, B)
        self._intf.write(self._base_addr + addr, data)

        self.SetI2CMux(self.I2CBUS_DEFAULT)

    def GetADCValue(self, mux_ch, adc_ch):
        self.SetI2CMux(self.I2CBUS_ADC)

        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_OUT, mux_ch))

        confByte = self.MAX11644_SCAN | self.MAX11644_SGL | self.MAX11644_CS0  # single-ended inputs,  both channels in a scan
        self._intf.write(self._base_addr + self.MAX11644_ADD, [confByte])

        rawData = self._intf.read(self._base_addr + self.MAX11644_ADD | 1, 4)
        raw_ch0 = ((0x0f & rawData[0]) * 256) + rawData[1]
        raw_ch1 = ((0x0f & rawData[2]) * 256) + rawData[3]

        self.SetI2CMux(self.I2CBUS_DEFAULT)

        return raw_ch0 if adc_ch == 0 else raw_ch1

    def SetPowerGPIO(self, bit, value):
        self.SetI2CMux(self.I2CBUS_DAC)

        gpio = BitVector(size=8, intVal=self.GetPowerGPIO())
        gpio[7 - bit] = value
        self._intf.write(self._base_addr + self.POWER_GPIO_ADD, (self.PCA9554_OUT, gpio.intValue()))

        self.SetI2CMux(self.I2CBUS_DEFAULT)

    def GetPowerGPIO(self):
        i2cbus = self.GetI2CMux()
        self.SetI2CMux(self.I2CBUS_DAC)

        self._intf.write(self._base_addr + self.POWER_GPIO_ADD, [self.PCA9554_IN])
        ret = self._intf.read(self._base_addr + self.POWER_GPIO_ADD | 1, 1)[0]
        self.SetI2CMux(i2cbus)
        return ret
