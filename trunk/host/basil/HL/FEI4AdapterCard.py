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

from struct import pack, unpack_from
from array import array


class FEI4AdapterCard(HardwareLayer):
    '''FEI4AdapterCard interface
    '''

    #DAC MAX520
    MAX_520_ADD = 0x58

    #ADC MAX1238
    MAX_1239_ADD = 0x6a
    INT_REF_OFF_EXT_REF_ON = 0x20
    INT_REF_ON_OUTPUT_OFF = 0x50
    VDD_REF = 0x00
    SETUP_DATA = 0x80
    NO_RESET = 0x02
    EXT_CLK = 0x08
    SETUP_FLAGS = (SETUP_DATA | INT_REF_OFF_EXT_REF_ON | NO_RESET | EXT_CLK)  # use external reference
    SETUP_FLAGS_BI = (SETUP_DATA | INT_REF_ON_OUTPUT_OFF | NO_RESET | EXT_CLK)  # use internal reference

    # EEPROM 24LC128
    CAL_EEPROM_ADD = 0xa8
    CAL_EEPROM_PAGE_SIZE = 32
    CAL_DATA_HEADER_FORMAT = 'BB'
    CAL_DATA_HEADER_V1 = 0xa101
    CAL_DATA_CH_V1_FORMAT = 'ccccccccddddddddd'
    CAL_DATA_CONST_V1_FORMAT = 'dddddd'
    CAL_DATA_V1_FORMAT = CAL_DATA_HEADER_FORMAT + 4 * CAL_DATA_CH_V1_FORMAT + CAL_DATA_CONST_V1_FORMAT
    CAL_DATA_HEADER_V2 = 0xa102
    CAL_DATA_CH_V2_FORMAT = 'ccccccccddddddddddddddd'
    CAL_DATA_V1_FORMAT = CAL_DATA_HEADER_FORMAT + 8 * CAL_DATA_CH_V2_FORMAT

    SCAN_OFF = 0x60
    SCAN_ON = 0x00
    SINGLE_ENDED = 0x01

    _cal = {'VDDA1': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0.0, 'gain': 1638.4},
                      'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
                    },
            'VDDA2': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0.0, 'gain': 1638.4},
                      'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
                    },
            'VDDD1': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0.0, 'gain': 1638.4},
                      'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
                    },
            'VDDD2': {
                      'DACV': {'offset': 1.558, 'gain': -0.00193},
                      'ADCV': {'offset': 0.0, 'gain': 1638.4},
                      'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
                    }
            }

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
        super(FEI4AdapterCard, self).__init__(intf, conf)

    def init(self):
        self.setup_adc()

    def setup_adc(self):
        self._intf.write(self._base_addr + self.MAX_1239_ADD, array('B', pack('B', self.SETUP_FLAGS)))

    def set_voltage(self, channel, value, unit='V'):
        DACOffset = self._cal[channel]['DACV']['offset']
        DACGain = self._cal[channel]['DACV']['gain']

        DACval = 0
        if unit == 'raw':
            DACval = value
        elif unit == 'V':
            DACval = int((value - DACOffset) / DACGain)
        elif unit == 'mV':
            DACval = int((value / 1000 - DACOffset) / DACGain)
        else:
            raise TypeError("Invalid unit type.")

        kwargs = self._map[channel]['DACV']
        kwargs['value'] = (2 ** 8 - 1) if DACval >= (2 ** 8) else DACval
        kwargs['value'] = 0 if DACval < 0 else DACval
        self._set_dac_value(**kwargs)

    def get_voltage(self, channel, unit='V'):
        kwargs = self._map[channel]['ADCV']
        voltage_raw = self._get_adc_value(**kwargs)

        voltage = (voltage_raw - self._cal[channel]['ADCV']['offset']) / self._cal[channel]['ADCV']['gain']

        if unit == 'raw':
            return voltage_raw
        elif unit == 'V':
            return voltage
        elif unit == 'mV':
            return voltage * 1000
        else:
            raise TypeError("Invalid unit type.")

    def get_current(self, channel, unit='A'):
        kwargs = self._map[channel]['ADCI']
        current_raw = self._get_adc_value(**kwargs)
        voltage = self.get_voltage(channel)

        current_raw_iq = current_raw - (self._cal[channel]['ADCI']['iq_offset'] + self._cal[channel]['ADCI']['iq_gain'] * voltage)  # quiescent current (IQ) compensation
        current = (current_raw_iq - self._cal[channel]['ADCI']['offset']) / self._cal[channel]['ADCI']['gain']

        if unit == 'raw':
            return current_raw
        elif unit == 'raw_iq':
            return current_raw_iq
        elif unit == 'A':
            return current
        elif unit == 'mA':
            return current * 1000
        elif unit == 'uA':
            return current * 1000000
        else:
            raise TypeError("Invalid unit type.")

    def _set_dac_value(self, dac_ch, value):
        '''Writing DAC MAX520
        '''
        self._intf.write(self._base_addr + self.MAX_520_ADD, array('B', pack('BB', dac_ch, value)))

    def _get_adc_value(self, adc_ch, average=None):
        '''Reading ADC MAX1238
        '''
        confByte = self.SCAN_OFF | self.SINGLE_ENDED | ((0x1e) & (adc_ch << 1))
        #self._intf.write(self._base_addr + self.MAX_1239_ADD, array('B', pack('B', confByte)))
        self._intf.write(self._base_addr + self.MAX_1239_ADD, [confByte])

        if average:
            raw = 0
            for _ in range(average):
                ret = self._intf.read(self._base_addr + self.MAX_1239_ADD | 1, size=2)
                ret.reverse()
                ret[1] = ret[1] & 0x0f  # 12-bit ADC
                raw += unpack_from('H', ret)[0]
            raw /= average
        else:
            ret = self._intf.read(self._base_addr + self.MAX_1239_ADD | 1, size=2)
            ret.reverse()
            ret[1] = ret[1] & 0x0f  # 12-bit ADC
            raw = unpack_from('H', ret)[0]

        return raw

    def _read_eeprom(self, addr, size):
        '''Reading EEPROM 24LC128
        '''
        n_pages, n_bytes = divmod(size, self.CAL_EEPROM_PAGE_SIZE)

        self._intf.write(self._base_addr + self.CAL_EEPROM_ADD, array('B', pack('H', addr & 0x3FFF)))  # 14-bit address, 16384 bytes

        data = array('B')
        for _ in range(n_pages):
            data.extend(self._intf.read(self._base_addr + self.CAL_EEPROM_ADD | 1, size=self.CAL_EEPROM_PAGE_SIZE))

        if n_bytes > 0:
            data.extend(self._intf.read(self._base_addr + self.CAL_EEPROM_ADD | 1, size=n_bytes))

        return data

    def read_eeprom_calibration(self):
        '''Reading EEPROM calibration
        '''
        ret = self._read_eeprom(0, 2)
        ret.reverse()
        header = unpack_from('H', ret)[0]
        if header == self.CAL_DATA_HEADER_V1:
            raise NotImplementedError('Reading EEPROM calibration not supported')
        else:
            raise NotImplementedError('Format not supported')
