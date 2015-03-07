#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.HardwareLayer import HardwareLayer

from struct import pack, unpack_from, calcsize
from array import array

from collections import OrderedDict, Iterable

from math import log
import string


class FEI4AdapterCard(HardwareLayer):
    '''FEI4AdapterCard interface
    '''

    # DAC MAX520
    MAX_520_ADD = 0x58

    # ADC MAX1238
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
    HEADER_ADDR = 0
    HEADER_FORMAT = '>H'  # Version of EEPROM data
    HEADER_V1 = 0xa101
    HEADER_V2 = 0xa102
    ID_ADDR = HEADER_ADDR + calcsize(HEADER_FORMAT)
    ID_FORMAT = '>H'  # Adapter Card ID
    CAL_DATA_CH_V1_FORMAT = '8sddddddddd'
    CAL_DATA_CH_V2_FORMAT = '8sddddddddddddddd'
    CAL_DATA_CONST_V1_FORMAT = 'dddddd'
    CAL_DATA_ADDR = ID_ADDR + calcsize(ID_FORMAT)
    CAL_DATA_V1_FORMAT = '<' + 4 * CAL_DATA_CH_V1_FORMAT + CAL_DATA_CONST_V1_FORMAT
    CAL_DATA_V2_FORMAT = '<' + 4 * CAL_DATA_CH_V2_FORMAT

    # NTC
    T_KELVIN_0 = 273.15
    T_KELVIN_25 = (25 + T_KELVIN_0)

    SCAN_OFF = 0x60
    SCAN_ON = 0x00
    SINGLE_ENDED = 0x01

    _temp_cal = dict(
        B_NTC=3425.0,  # NTC 'b' coefficient, NTC Semitec 103KT1608-1P
        R_NTC_25=10000.0,  # NTC 25C resistance, NTC Semitec 103KT1608-1P
        R1=3900.0,  # resistor value for NTC voltage divider
        R2=4700.0,  # value of R2 in the reference voltage divider
        R4=10000.0,  # value of R4 in the reference voltage divider
        VREF=2.5  # supply voltage of the resistor bridge
    )

    _ch_cal = OrderedDict([
        ('VDDA1',
            {'name': '',
             'default': 0.0,
             'DACV': {'offset': 1.558, 'gain': -0.00193},
             'ADCV': {'offset': 0.0, 'gain': 1638.4},
             'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
             }),
        ('VDDA2',
            {'name': '',
             'default': 0.0,
             'DACV': {'offset': 1.558, 'gain': -0.00193},
             'ADCV': {'offset': 0.0, 'gain': 1638.4},
             'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
             }),
        ('VDDD1',
            {'name': '',
             'default': 0.0,
             'DACV': {'offset': 1.558, 'gain': -0.00193},
             'ADCV': {'offset': 0.0, 'gain': 1638.4},
             'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
             }),
        ('VDDD2',
            {'name': '',
             'default': 0.0,
             'DACV': {'offset': 1.558, 'gain': -0.00193},
             'ADCV': {'offset': 0.0, 'gain': 1638.4},
             'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6, 'iq_gain': 6},
             })]
    )

    _map = OrderedDict([
        ('VDDA1',
         {'DACV': {'dac_ch': 3},
          'ADCV': {'adc_ch': 0},
          'ADCI': {'adc_ch': 1},
          }),
        ('VDDA2',
         {'DACV': {'dac_ch': 0},
          'ADCV': {'adc_ch': 2},
          'ADCI': {'adc_ch': 3},
          }),
        ('VDDD1',
         {'DACV': {'dac_ch': 1},
          'ADCV': {'adc_ch': 4},
          'ADCI': {'adc_ch': 5},
          }),
        ('VDDD2',
         {'DACV': {'dac_ch': 2},
          'ADCV': {'adc_ch': 6},
          'ADCI': {'adc_ch': 7},
          }),
        ('NTC1', {'adc_ch': 8}),
        ('NTC2', {'adc_ch': 9}),
        ('VNTC', {'adc_ch': 10})
    ])

    def __init__(self, intf, conf):
        super(FEI4AdapterCard, self).__init__(intf, conf)

    def init(self):
        self.setup_adc()
        self.read_eeprom_calibration()

    def setup_adc(self):
        self._intf.write(self._base_addr + self.MAX_1239_ADD, array('B', pack('B', self.SETUP_FLAGS)))

    def set_default(self, channels=True):
        '''Set default voltage
        '''
        if isinstance(channels, Iterable):
            sel_channels = channels
        else:
            if channels:
                sel_channels = self._ch_cal.keys()
            else:
                sel_channels = []
        for channel in sel_channels:
            self.set_voltage(channel, self._ch_cal[channel]['default'], unit='V')

    def set_voltage(self, channel, value, unit='V'):
        DACOffset = self._ch_cal[channel]['DACV']['offset']
        DACGain = self._ch_cal[channel]['DACV']['gain']

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

        voltage = (voltage_raw - self._ch_cal[channel]['ADCV']['offset']) / self._ch_cal[channel]['ADCV']['gain']

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

        current_raw_iq = current_raw - (self._ch_cal[channel]['ADCI']['iq_offset'] + self._ch_cal[channel]['ADCI']['iq_gain'] * voltage)  # quiescent current (IQ) compensation
        current = (current_raw_iq - self._ch_cal[channel]['ADCI']['offset']) / self._ch_cal[channel]['ADCI']['gain']

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

    def get_temperature(self, channel='VNTC'):

        kwargs = self._map[channel]
        temp_raw = self._get_adc_value(**kwargs)

#         NTC type SEMITEC 103KT1608 http://www.semitec.co.jp/english/products/pdf/KT_Thermistor.pdf
#
#         R_NTC = R_25 * exp(B_NTC * (1/T - 1/T_25))
#
#         R_NTC       measured NTC resistance
#         R_NTC_25    resistance @ 25C
#         B_NTC       temperature coefficient
#         Temperature current temperature (Kelvin)
#         T_25        298,15 K (25C)

        v_adc = ((temp_raw - self._ch_cal.items()[0][1]['ADCV']['offset']) / self._ch_cal.items()[0][1]['ADCV']['gain'])  # voltage
        k = self._temp_cal['R4'] / (self._temp_cal['R2'] + self._temp_cal['R4'])  # reference voltage divider
        r_ntc = self._temp_cal['R1'] * (k - v_adc / self._temp_cal['VREF']) / (1 - k + v_adc / self._temp_cal['VREF'])  # NTC resistance

        return (self._temp_cal['B_NTC'] / (log(r_ntc) - log(self._temp_cal['R_NTC_25']) + self._temp_cal['B_NTC'] / self.T_KELVIN_25)) - self.T_KELVIN_0  # NTC temperature

    def _set_dac_value(self, dac_ch, value):
        '''Writing DAC MAX520
        '''
        self._intf.write(self._base_addr + self.MAX_520_ADD, array('B', pack('BB', dac_ch, value)))

    def _get_adc_value(self, adc_ch, average=None):
        '''Reading ADC MAX1238
        '''
        confByte = self.SCAN_OFF | self.SINGLE_ENDED | ((0x1e) & (adc_ch << 1))
#         self._intf.write(self._base_addr + self.MAX_1239_ADD, array('B', pack('B', confByte)))
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

    def get_format(self):
        ret = self._read_eeprom(self.HEADER_ADDR, size=calcsize(self.HEADER_FORMAT))
        return unpack_from(self.HEADER_FORMAT, ret)[0]

    def get_id(self):
        ret = self._read_eeprom(self.ID_ADDR, size=calcsize(self.ID_FORMAT))
        return unpack_from(self.ID_FORMAT, ret)[0]

    def _read_eeprom(self, addr, size):
        '''Reading EEPROM 24LC128
        '''
        n_pages, n_bytes = divmod(size, self.CAL_EEPROM_PAGE_SIZE)

        self._intf.write(self._base_addr + self.CAL_EEPROM_ADD, array('B', pack('>H', addr & 0x3FFF)))  # 14-bit address, 16384 bytes

        data = array('B')
        for _ in range(n_pages):
            data.extend(self._intf.read(self._base_addr + self.CAL_EEPROM_ADD | 1, size=self.CAL_EEPROM_PAGE_SIZE))

        if n_bytes > 0:
            data.extend(self._intf.read(self._base_addr + self.CAL_EEPROM_ADD | 1, size=n_bytes))

        return data

    def read_eeprom_calibration(self, regulator=True, temperature=False):  # use default values for temperature, EEPROM values are not calibrated and wrong
        '''Reading EEPROM calibration
        '''
        if isinstance(regulator, Iterable):
            channels = regulator
        else:
            if regulator:
                channels = self._ch_cal.keys()
            else:
                channels = []
        header = self.get_format()
        if header == self.HEADER_V1:
            data = self._read_eeprom(self.CAL_DATA_ADDR, size=calcsize(self.CAL_DATA_V1_FORMAT))
            for idx, channel in enumerate(self._ch_cal.iterkeys()):
                if channel in channels:
                    ch_data = data[idx * calcsize(self.CAL_DATA_CH_V1_FORMAT):(idx + 1) * calcsize(self.CAL_DATA_CH_V1_FORMAT)]
                    values = unpack_from(self.CAL_DATA_CH_V1_FORMAT, ch_data)
                    self._ch_cal[channel]['name'] = "".join([c for c in values[0] if c in string.letters or c in string.whitespace])  # values[0].strip()
                    self._ch_cal[channel]['default'] = values[1]
                    self._ch_cal[channel]['ADCI']['gain'] = values[2]
                    self._ch_cal[channel]['ADCI']['offset'] = values[3]
                    self._ch_cal[channel]['ADCI']['iq_gain'] = values[4]
                    self._ch_cal[channel]['ADCI']['iq_offset'] = values[5]
                    self._ch_cal[channel]['ADCV']['gain'] = values[6]
                    self._ch_cal[channel]['ADCV']['offset'] = values[7]
                    self._ch_cal[channel]['DACV']['gain'] = values[8]
                    self._ch_cal[channel]['DACV']['offset'] = values[9]
            const_data = data[-calcsize(self.CAL_DATA_CONST_V1_FORMAT):]
            values = unpack_from(self.CAL_DATA_CONST_V1_FORMAT, const_data)
            if temperature:
                self._temp_cal['B_NTC'] = values[0]
                self._temp_cal['R1'] = values[1]
                self._temp_cal['R2'] = values[2]
                self._temp_cal['R4'] = values[3]
                self._temp_cal['R_NTC_25'] = values[4]
                self._temp_cal['VREF'] = values[5]
        else:
            raise NotImplementedError('EEPROM data format not supported')
