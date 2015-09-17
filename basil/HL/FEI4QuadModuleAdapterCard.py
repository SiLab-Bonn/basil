#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
from struct import pack, unpack_from, calcsize
from array import array
from collections import OrderedDict
from math import log
import string

from basil.HL.HardwareLayer import HardwareLayer
from basil.HL.FEI4AdapterCard import AdcMax1239, Eeprom24Lc128, Fei4Dcs


class DacMax5380(HardwareLayer):
    '''DAC MAX5380

    Write current limit (QMAC).
    '''
    MAX_5380_ADD = 0x60

    def __init__(self, intf, conf):
        super(DacMax5380, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _set_dac_value(self, channel, value):
        '''Write DAC
        '''
        self._intf.write(self._base_addr + self.MAX_5380_ADD, array('B', pack('B', value)))


class DacDs4424(HardwareLayer):
    '''DAC DS4424

    Write voltage (QMAC).
    '''
    DS_4424_ADD = 0x20

    def __init__(self, intf, conf):
        super(DacDs4424, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _set_dac_value(self, channel, value):
        '''Write DAC
        '''
        # DAC value cannot be -128
        if value == -128:
            value = -127
        if value < 0:
            sign = 1
        else:
            sign = 0
        value = (sign << 7) | (0x7F & abs(value))
        self._intf.write(self._base_addr + self.DS_4424_ADD, array('B', pack('BB', channel, value)))


class FEI4QuadModuleAdapterCard(AdcMax1239, DacDs4424, DacMax5380, Eeprom24Lc128, Fei4Dcs):
    '''FEI4 Quad Module Adapter Card interface
    '''

    # EEPROM data V2
    HEADER_V2 = 0xa102
    CAL_DATA_CH_V2_FORMAT = '8sddddddddddddddd'
    CAL_DATA_ADDR = Fei4Dcs.ID_ADDR + calcsize(Fei4Dcs.ID_FORMAT)
    CAL_DATA_V2_FORMAT = '<' + 4 * CAL_DATA_CH_V2_FORMAT

    # NTC
    T_KELVIN_0 = 273.15
    T_KELVIN_25 = (25.0 + T_KELVIN_0)

    # Channel mappings
    _ch_map = {
        'CH1':
            {'DACV': {'channel': 0xf8},
             'ADCV': {'channel': 0},
             'ADCI': {'channel': 1},
             'NTC': {'channel': 8}
             },
        'CH2':
            {'DACV': {'channel': 0xf9},
             'ADCV': {'channel': 2},
             'ADCI': {'channel': 3},
             'NTC': {'channel': 9}
             },
        'CH3':
            {'DACV': {'channel': 0xfa},
             'ADCV': {'channel': 4},
             'ADCI': {'channel': 5},
             'NTC': {'channel': 10}
             },
        'CH4':
            {'DACV': {'channel': 0xfb},
             'ADCV': {'channel': 6},
             'ADCI': {'channel': 7},
             'NTC': {'channel': 11}
             }
    }

    def __init__(self, intf, conf):
        super(FEI4QuadModuleAdapterCard, self).__init__(intf, conf)

        # Channel calibrations
        self._ch_cal = OrderedDict([
            ('CH1',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.8, 'gain': 0.00397},
                 'ADCV': {'offset': 0.0, 'gain': 1000.0},
                 'DACI': {'offset': 0.0, 'gain': 0.0078125},
                 'ADCI': {'offset': 0.0, 'gain': 1000.0, 'iq_offset': 1.5, 'iq_gain': 7.0},
                 'NTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 39200.0, 'R2': 4750.0, 'R4': 10000.0, 'VREF': 4.5}
                 }),
            ('CH2',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.8, 'gain': 0.00397},
                 'ADCV': {'offset': 0.0, 'gain': 1000.0},
                 'DACI': {'offset': 0.0, 'gain': 0.0078125},
                 'ADCI': {'offset': 0.0, 'gain': 1000.0, 'iq_offset': 1.5, 'iq_gain': 7.0},
                 'NTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 39200.0, 'R2': 4750.0, 'R4': 10000.0, 'VREF': 4.5}
                 }),
            ('CH3',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.8, 'gain': 0.00397},
                 'ADCV': {'offset': 0.0, 'gain': 1000.0},
                 'DACI': {'offset': 0.0, 'gain': 0.0078125},
                 'ADCI': {'offset': 0.0, 'gain': 1000.0, 'iq_offset': 1.5, 'iq_gain': 7.0},
                 'NTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 39200.0, 'R2': 4750.0, 'R4': 10000.0, 'VREF': 4.5}
                 }),
            ('CH4',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.8, 'gain': 0.00397},
                 'ADCV': {'offset': 0.0, 'gain': 1000.0},
                 'DACI': {'offset': 0.0, 'gain': 0.0078125},
                 'ADCI': {'offset': 0.0, 'gain': 1000.0, 'iq_offset': 1.5, 'iq_gain': 7.0},
                 'NTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 39200.0, 'R2': 4750.0, 'R4': 10000.0, 'VREF': 4.5}
                 })]
        )

    def init(self):
        self._setup_adc(self.SETUP_FLAGS_BI)
        self.read_eeprom_calibration()
        self.set_current_limit('CH1', 1.0)
        logging.info('Found adapter card: {}'.format('%s with ID %s' % ('Quad Module Adapter Card', self.get_id())))

    def read_eeprom_calibration(self, temperature=False):  # use default values for temperature, EEPROM values are usually not calibrated and random
        '''Reading EEPROM calibration for power regulators and temperature
        '''
        header = self.get_format()
        if header == self.HEADER_V2:
            data = self._read_eeprom(self.CAL_DATA_ADDR, size=calcsize(self.CAL_DATA_V2_FORMAT))
            for idx, channel in enumerate(self._ch_cal.iterkeys()):
                ch_data = data[idx * calcsize(self.CAL_DATA_CH_V2_FORMAT):(idx + 1) * calcsize(self.CAL_DATA_CH_V2_FORMAT)]
                values = unpack_from(self.CAL_DATA_CH_V2_FORMAT, ch_data)
                self._ch_cal[channel]['name'] = "".join([c for c in values[0] if (c in string.printable)])  # values[0].strip()
                self._ch_cal[channel]['default'] = values[1]
                self._ch_cal[channel]['ADCI']['gain'] = values[2]
                self._ch_cal[channel]['ADCI']['offset'] = values[3]
                self._ch_cal[channel]['ADCI']['iq_gain'] = values[4]
                self._ch_cal[channel]['ADCI']['iq_offset'] = values[5]
                self._ch_cal[channel]['ADCV']['gain'] = values[6]
                self._ch_cal[channel]['ADCV']['offset'] = values[7]
                self._ch_cal[channel]['DACV']['gain'] = values[8]
                self._ch_cal[channel]['DACV']['offset'] = values[9]
                if temperature:
                    self._ch_cal[channel]['NTC']['B_NTC'] = values[10]
                    self._ch_cal[channel]['NTC']['R1'] = values[11]
                    self._ch_cal[channel]['NTC']['R2'] = values[12]
                    self._ch_cal[channel]['NTC']['R4'] = values[13]
                    self._ch_cal[channel]['NTC']['R_NTC_25'] = values[14]
                    self._ch_cal[channel]['NTC']['VREF'] = values[15]
        else:
            raise ValueError('EEPROM data format not supported (header: %s)' % header)

    def get_temperature(self, channel):
        '''Reading temperature
        '''
        #         NTC type SEMITEC 103KT1608 http://www.semitec.co.jp/english/products/pdf/KT_Thermistor.pdf
        #
        #         R_NTC = R_25 * exp(B_NTC * (1/T - 1/T_25))
        #
        #         R_NTC       measured NTC resistance
        #         R_NTC_25    resistance @ 25C
        #         B_NTC       temperature coefficient
        #         Temperature current temperature (Kelvin)
        #         T_25        298,15 K (25C)
        #
        #         B_NTC       NTC 'b' coefficient, NTC Semitec 103KT1608-1P
        #         R_NTC_25    NTC 25C resistance, NTC Semitec 103KT1608-1P
        #         R1          resistor value for NTC voltage divider
        #         R2          value of R2 in the reference voltage divider
        #         R4          value of R4 in the reference voltage divider
        #         VREF        supply voltage of the resistor bridge
        #
        #         Note:
        #         new NTC on FE-I4
        #         NTC type TDK NTCG163JF103FT1
        #
        kwargs = self._ch_map[channel]['NTC']
        temp_raw = self._get_adc_value(**kwargs)

        v_adc = ((temp_raw - self._ch_cal[channel]['ADCV']['offset']) / self._ch_cal[channel]['ADCV']['gain'])  # voltage, VDDA1
        k = self._ch_cal[channel]['NTC']['R4'] / (self._ch_cal[channel]['NTC']['R2'] + self._ch_cal[channel]['NTC']['R4'])  # reference voltage divider
        r_ntc = self._ch_cal[channel]['NTC']['R1'] * (k - v_adc / self._ch_cal[channel]['NTC']['VREF']) / (1 - k + v_adc / self._ch_cal[channel]['NTC']['VREF'])  # NTC resistance

        return (self._ch_cal[channel]['NTC']['B_NTC'] * self.T_KELVIN_25) / (self._ch_cal[channel]['NTC']['B_NTC'] + self.T_KELVIN_25 * log(r_ntc / self._ch_cal[channel]['NTC']['R_NTC_25'])) - self.T_KELVIN_0  # NTC temperature

    def set_current_limit(self, channel, value, unit='A'):
        '''Setting current limit

        Note: same limit for all channels.
        '''
        dac_offset = self._ch_cal[channel]['DACI']['offset']
        dac_gain = self._ch_cal[channel]['DACI']['gain']

        if unit == 'raw':
            value = value
        elif unit == 'A':
            value = int((value - dac_offset) / dac_gain)
        elif unit == 'mA':
            value = int((value / 1000 - dac_offset) / dac_gain)
        else:
            raise TypeError("Invalid unit type.")

        DacMax5380._set_dac_value(self, channel, value)
