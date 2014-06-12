#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 261                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-06 15:16:45 #$:
#

from basil.HL.HardwareLayer import HardwareLayer
from BitVector import BitVector


class FEI4AdapterCard(HardwareLayer):
    '''FEI4AdapterCard interface
    '''

    #DACS
    MAX_520_ADD = 0x58

    #ADC
    MAX_1239_ADD = 0x6a

    SCAN_OFF = 0x60
    SCAN_ON = 0x00
    SINGLE_ENDED = 0x01

    #From USBPixI4DCS.cpp - STDSupplyChannel::STDSupplyChannel
    #CalData.VsetOffset  = 1.558;
	#CalData.VsetGain    = -0.00193;
	#CalData.VmeasOffset = 0.0;
	#CalData.VmeasGain   = 1638.4;
	#CalData.ImeasOffset = 0;
	#CalData.ImeasGain   = 3296.45;
	#CalData.IqOffset = 6;
	#CalData.IqVgain = 6;
    
    
    _cal = {'VDDA1': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0, 'gain': 1638.4;},
                      'ADCI': {'offset': 0, 'gain': 1638.4;},
                    },
            'VDDA2': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0, 'gain': 1638.4;},
                      'ADCI': {'offset': 0, 'gain': 3296.45},
                    },
            'VDDD1': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0, 'gain': 1638.4},
                      'ADCI': {'offset': 0, 'gain': 3296.45},
                    },
            'VDDD2': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0, 'gain': 1638.4},
                      'ADCI': {'offset': 0, 'gain': 3296.45},
                    },

            
    _map = {'VDDA2': {
                      'DACV': {'dac_ch': 0},
                      'ADCV': {'adc_ch': 2},
                      'ADCI': {'adc_ch': 3},
                    },
            'VDDD1': {
                      'DACV': {'dac_ch': 1},
                      'ADCV': {'adc_ch': 4},
                      'ADCI': {'adc_ch': 5},
                    },
            'VDDD2': {
                      'DACV': {'dac_ch': 2},
                      'ADCV': {'adc_ch': 6},
                      'ADCI': {'adc_ch': 7},
                    },
            'VDDA1': {
                      'DACV': {'dac_ch': 3},
                      'ADCV': {'adc_ch': 0},
                      'ADCI': {'adc_ch': 1},
                    },
            }

    def __init__(self, intf, conf):
        super(GPAC, self).__init__(intf, conf)

    def init(self):

        #ADC
        #adc_setup = self.MAX11644_EXT_REF | self.MAX11644_SETUP
        #self._intf.write(self._base_addr + self.MAX11644_ADD, [adc_setup])

    def set_voltage(self, channel, value, unit='mV'):

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
        karg['value'] = (2 ** 8 - 1) if DACval > (2 ** 8) else DACval
        karg['value'] = 0 if DACval < 0 else DACval
        self.SetDACValue(**karg)

    def get_voltage(self, channel, unit='mV'):

        karg = self._map[channel]['ADCV']
        raw = self._get_adc_value(**karg)

        VADCOffset = self._cal[channel]['ADCV']['offset']
        VADCGain = self._cal[channel]['ADCV']['gain']

        mV = (float)((raw - VADCOffset) / VADCGain)

        if unit == 'raw':
            return raw
        elif unit == 'V':
            return mV / 1000
        elif unit == 'mV':
            return mV
        else:
            raise TypeError("Invalid unit type.")

    def get_current(self, channel, unit='mA'):

        karg = self._map[channel]['ADCI']
        raw = self._get_adc_value(**karg)

        #IADCOffset =    0.0;
        #IADCGain   =   20.0;

        IADCOffset = self._cal[channel]['ADCI']['offset']
        IADCGain = self._cal[channel]['ADCI']['gain']

        uA = 0

        if('SRC' in channel):
            rawV = self.get_voltage(channel, unit='raw')
            uA = (float)((raw - rawV - IADCOffset) / IADCGain)
        else:
            uA = (float)((raw - IADCOffset) / IADCGain)

        #CurrentRawIq = CurrentRaw - (CalData.IqOffset + CalData.IqVgain * Voltage);
        #return (Current = (double)((CurrentRawIq - CalData.ImeasOffset) / CalData.ImeasGain));
    
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

    def SetDACValue(self, dac_ch, value):

        data = (dac_ch, value & 0xff )
        self._intf.write(self._base_addr + self.MAX_520_ADD, data)

    def _get_adc_value(self, adc_ch):

        confByte = self.SCAN_OFF | self.SINGLE_ENDED | ((0x1e) & (adc_ch << 1))
        self._intf.write(self._base_addr + self.MAX_1239_ADD, [confByte])

        rawData = self._intf.read(self._base_addr + self.MAX_1239_ADD | 1, 2)
        raw = ((0x0f & rawData[0]) * 256) + rawData[1]

        return raw

    