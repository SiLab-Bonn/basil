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
import abc

from basil.HL.HardwareLayer import HardwareLayer


class AdcMax1239(HardwareLayer):
    '''ADC MAX1238/MAX1239

    Read current and voltage (AC & QMAC).
    '''
    MAX_1239_ADD = 0x6a

    INT_REF_OFF_EXT_REF_ON = 0x20
    INT_REF_ON_OUTPUT_OFF = 0x50
    VDD_REF = 0x00
    SETUP_DATA = 0x80
    NO_RESET = 0x02
    EXT_CLK = 0x08
    SETUP_FLAGS = (SETUP_DATA | INT_REF_OFF_EXT_REF_ON | NO_RESET | EXT_CLK)  # use external reference
    SETUP_FLAGS_BI = (SETUP_DATA | INT_REF_ON_OUTPUT_OFF | NO_RESET | EXT_CLK)  # use internal reference

    SCAN_OFF = 0x60
    SCAN_ON = 0x00
    SINGLE_ENDED = 0x01

    def __init__(self, intf, conf):
        super(AdcMax1239, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _setup_adc(self, flags):
        '''Initialize ADC
        '''
        self._intf.write(self._base_addr + self.MAX_1239_ADD, array('B', pack('B', flags)))

    def _get_adc_value(self, channel, average=None):
        '''Read ADC
        '''
        conf = self.SCAN_OFF | self.SINGLE_ENDED | ((0x1e) & (channel << 1))
        self._intf.write(self._base_addr + self.MAX_1239_ADD, array('B', pack('B', conf)))

        def read_data():
            ret = self._intf.read(self._base_addr + self.MAX_1239_ADD | 1, size=2)
            ret.reverse()
            ret[1] = ret[1] & 0x0f  # 12-bit ADC
            return unpack_from('H', ret)[0]

        if average:
            raw = 0
            for _ in range(average):
                raw += read_data()
            raw /= average
        else:
            raw = read_data()

        return raw


class DacMax520(HardwareLayer):
    '''DAC MAX520

    Write voltage (AC).
    '''
    MAX_520_ADD = 0x58

    def __init__(self, intf, conf):
        super(DacMax520, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _set_dac_value(self, channel, value):
        '''Write DAC
        '''
        self._intf.write(self._base_addr + self.MAX_520_ADD, array('B', pack('BB', channel, value)))


class Eeprom24Lc128(HardwareLayer):
    '''EEPROM 24LC128

    Reading and writing EEPROM (AC & QMAC).
    '''
    CAL_EEPROM_ADD = 0xa8
    CAL_EEPROM_PAGE_SIZE = 32

    def __init__(self, intf, conf):
        super(Eeprom24Lc128, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _read_eeprom(self, address, size):
        '''Read EEPROM
        '''
        self._intf.write(self._base_addr + self.CAL_EEPROM_ADD, array('B', pack('>H', address & 0x3FFF)))  # 14-bit address, 16384 bytes

        n_pages, n_bytes = divmod(size, self.CAL_EEPROM_PAGE_SIZE)
        data = array('B')
        for _ in range(n_pages):
            data.extend(self._intf.read(self._base_addr + self.CAL_EEPROM_ADD | 1, size=self.CAL_EEPROM_PAGE_SIZE))

        if n_bytes > 0:
            data.extend(self._intf.read(self._base_addr + self.CAL_EEPROM_ADD | 1, size=n_bytes))

        return data

    def _write_eeprom(self, address, data):
        raise NotImplementedError()


class Fei4Dcs(object):
    '''FEI4AdapterCard interface
    '''

    __metaclass__ = abc.ABCMeta

    # EEPROM
    HEADER_ADDR = 0
    HEADER_FORMAT = '>H'  # Version of EEPROM data
    ID_ADDR = HEADER_ADDR + calcsize(HEADER_FORMAT)
    ID_FORMAT = '>H'  # Adapter Card ID

    # Channel mappings
    _ch_map = None

    def __init__(self):
        # Channel calibrations
        self._ch_cal = None

    def set_default(self, channels=None):
        '''Setting default voltage
        '''
        if not channels:
            channels = self._ch_cal.keys()
        for channel in channels:
            self.set_voltage(channel, self._ch_cal[channel]['default'], unit='V')

    def set_voltage(self, channel, value, unit='V'):
        '''Setting voltage
        '''
        dac_offset = self._ch_cal[channel]['DACV']['offset']
        dac_gain = self._ch_cal[channel]['DACV']['gain']

        if unit == 'raw':
            value = value
        elif unit == 'V':
            value = int((value - dac_offset) / dac_gain)
        elif unit == 'mV':
            value = int((value / 1000 - dac_offset) / dac_gain)
        else:
            raise TypeError("Invalid unit type.")

        self._set_dac_value(value=value, **self._ch_map[channel]['DACV'])

    def get_voltage(self, channel, unit='V'):
        '''Reading voltage
        '''
        kwargs = self._ch_map[channel]['ADCV']
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
        '''Reading current
        '''
        kwargs = self._ch_map[channel]['ADCI']
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

    def get_format(self):
        ret = self._read_eeprom(self.HEADER_ADDR, size=calcsize(self.HEADER_FORMAT))
        return unpack_from(self.HEADER_FORMAT, ret)[0]

    def get_id(self):
        ret = self._read_eeprom(self.ID_ADDR, size=calcsize(self.ID_FORMAT))
        return unpack_from(self.ID_FORMAT, ret)[0]

    @abc.abstractmethod
    def _get_adc_value(self, channel):
        pass

    @abc.abstractmethod
    def _set_dac_value(self, channel, value):
        pass

    @abc.abstractmethod
    def _read_eeprom(self, address, size):
        pass


class FEI4AdapterCard(AdcMax1239, DacMax520, Eeprom24Lc128, Fei4Dcs):
    '''FEI4 Adapter Card interface
    '''

    # EEPROM data V1
    HEADER_V1 = 0xa101
    CAL_DATA_CH_V1_FORMAT = '8sddddddddd'
    CAL_DATA_CONST_V1_FORMAT = 'dddddd'
    CAL_DATA_ADDR = Fei4Dcs.ID_ADDR + calcsize(Fei4Dcs.ID_FORMAT)
    CAL_DATA_V1_FORMAT = '<' + 4 * CAL_DATA_CH_V1_FORMAT + CAL_DATA_CONST_V1_FORMAT

    # NTC
    T_KELVIN_0 = 273.15
    T_KELVIN_25 = (25.0 + T_KELVIN_0)

    # Channel mappings
    _ch_map = {
        'VDDA1':
            {'DACV': {'channel': 3},
             'ADCV': {'channel': 0},
             'ADCI': {'channel': 1},
             'NTC1': {'channel': 8},
             'NTC2': {'channel': 9},
             'VNTC': {'channel': 10}
             },
        'VDDA2':
            {'DACV': {'channel': 0},
             'ADCV': {'channel': 2},
             'ADCI': {'channel': 3},
             'NTC1': {'channel': 8},
             'NTC2': {'channel': 9},
             'VNTC': {'channel': 10}
             },
        'VDDD1':
            {'DACV': {'channel': 1},
             'ADCV': {'channel': 4},
             'ADCI': {'channel': 5},
             'NTC1': {'channel': 8},
             'NTC2': {'channel': 9},
             'VNTC': {'channel': 10}
             },
        'VDDD2':
            {'DACV': {'channel': 2},
             'ADCV': {'channel': 6},
             'ADCI': {'channel': 7},
             'NTC1': {'channel': 8},
             'NTC2': {'channel': 9},
             'VNTC': {'channel': 10}
             }
    }

    def __init__(self, intf, conf):
        super(FEI4AdapterCard, self).__init__(intf, conf)

        # Channel calibrations
        self._ch_cal = OrderedDict([
            ('VDDA1',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.558, 'gain': -0.00193},
                 'ADCV': {'offset': 0.0, 'gain': 1638.4},
                 'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6.0, 'iq_gain': 6.0},
                 'NTC1': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'NTC2': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'VNTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5}
                 }),
            ('VDDA2',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.558, 'gain': -0.00193},
                 'ADCV': {'offset': 0.0, 'gain': 1638.4},
                 'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6.0, 'iq_gain': 6.0},
                 'NTC1': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'NTC2': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'VNTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5}
                 }),
            ('VDDD1',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.558, 'gain': -0.00193},
                 'ADCV': {'offset': 0.0, 'gain': 1638.4},
                 'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6.0, 'iq_gain': 6.0},
                 'NTC1': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'NTC2': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'VNTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5}
                 }),
            ('VDDD2',
                {'name': '',
                 'default': 0.0,
                 'DACV': {'offset': 1.558, 'gain': -0.00193},
                 'ADCV': {'offset': 0.0, 'gain': 1638.4},
                 'ADCI': {'offset': 0.0, 'gain': 3296.45, 'iq_offset': 6.0, 'iq_gain': 6.0},
                 'NTC1': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'NTC2': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5},
                 'VNTC': {'B_NTC': 3425.0, 'R_NTC_25': 10000.0, 'R1': 3900.0, 'R2': 4700.0, 'R4': 10000.0, 'VREF': 2.5}
                 })]
        )

    def init(self):
        self._setup_adc(self.SETUP_FLAGS)

        self._init.setdefault('no_calibration', False)
        # read calibration
        if not self._init['no_calibration']:
            self.read_eeprom_calibration()
            logging.info('Found adapter card: {}'.format('%s with ID %s' % ('Single Chip Adapter Card', self.get_id())))
        else:
            logging.info('FEI4AdapterCard: Skeeping calibration.')

    def read_eeprom_calibration(self, temperature=False):  # use default values for temperature, EEPROM values are usually not calibrated and random
        '''Reading EEPROM calibration for power regulators and temperature
        '''
        header = self.get_format()
        if header == self.HEADER_V1:
            data = self._read_eeprom(self.CAL_DATA_ADDR, size=calcsize(self.CAL_DATA_V1_FORMAT))
            for idx, channel in enumerate(self._ch_cal.iterkeys()):
                ch_data = data[idx * calcsize(self.CAL_DATA_CH_V1_FORMAT):(idx + 1) * calcsize(self.CAL_DATA_CH_V1_FORMAT)]
                values = unpack_from(self.CAL_DATA_CH_V1_FORMAT, ch_data)
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
            const_data = data[-calcsize(self.CAL_DATA_CONST_V1_FORMAT):]
            values = unpack_from(self.CAL_DATA_CONST_V1_FORMAT, const_data)
            if temperature:
                for channel in self._ch_cal.keys():
                    self._ch_cal[channel]['VNTC']['B_NTC'] = values[0]
                    self._ch_cal[channel]['VNTC']['R1'] = values[1]
                    self._ch_cal[channel]['VNTC']['R2'] = values[2]
                    self._ch_cal[channel]['VNTC']['R4'] = values[3]
                    self._ch_cal[channel]['VNTC']['R_NTC_25'] = values[4]
                    self._ch_cal[channel]['VNTC']['VREF'] = values[5]
        else:
            raise ValueError('EEPROM data format not supported (header: %s)' % header)

    def get_temperature(self, channel, sensor='VNTC'):
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

        kwargs = self._ch_map[channel][sensor]
        temp_raw = self._get_adc_value(**kwargs)

        v_adc = ((temp_raw - self._ch_cal.items()[0][1]['ADCV']['offset']) / self._ch_cal.items()[0][1]['ADCV']['gain'])  # voltage, VDDA1
        k = self._ch_cal[channel][sensor]['R4'] / (self._ch_cal[channel][sensor]['R2'] + self._ch_cal[channel][sensor]['R4'])  # reference voltage divider
        r_ntc = self._ch_cal[channel][sensor]['R1'] * (k - v_adc / self._ch_cal[channel][sensor]['VREF']) / (1 - k + v_adc / self._ch_cal[channel][sensor]['VREF'])  # NTC resistance

        return (self._ch_cal[channel][sensor]['B_NTC'] / (log(r_ntc) - log(self._ch_cal[channel][sensor]['R_NTC_25']) + self._ch_cal[channel][sensor]['B_NTC'] / self.T_KELVIN_25)) - self.T_KELVIN_0  # NTC temperature
