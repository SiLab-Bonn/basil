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
from time import sleep
import string

from basil.HL.HardwareLayer import HardwareLayer
from basil.HL.FEI4AdapterCard import Eeprom24Lc128


class MuxPca9540B(HardwareLayer):
    '''PCA 9540B

    I2C Bus Multiplexer (GPAC).
    '''
    PCA9540B_BASE_ADD = 0xE0  # generic slave address
    PCA9540B_SEL_CH0 = 0x04  # select channel 0
    PCA9540B_SEL_CH1 = 0x05  # select channel 1
    PCA9540B_SEL_NONE = 0x00  # de-select channels

    def __init__(self, intf, conf):
        super(MuxPca9540B, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']
        self.PCA9540B_ADD = self.PCA9540B_BASE_ADD

    def _set_i2c_mux(self, bus):
        self._intf.write(self._base_addr + self.PCA9540B_ADD, array('B', pack('B', bus)))

    def _get_i2c_mux(self):
        return unpack_from('B', self._intf.read(self._base_addr + self.PCA9540B_ADD | 1, size=1))[0]


class GpioPca9554(HardwareLayer):
    '''PCA 9554

    GPIO extension (GPAC).
    '''
    PCA9554_BASE_ADD = 0x40  # generic slave address
    PCA9554_CFG = 0x03  # configuration register: 1 -> input (default), 0 -> output
    PCA9554_POL = 0x02  # polarity inversion register
    PCA9554_OUT = 0x01  # output port register
    PCA9554_IN = 0x00  # input port register (internal pull-up)

    def __init__(self, intf, conf):
        super(GpioPca9554, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']
        self.PCA9554_ADD = self.PCA9554_BASE_ADD
        self.GPIO_CFG = 0x00

    def init(self):
        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_CFG, self.GPIO_CFG))
        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_OUT, 0x00))

    def _write_output_port_select(self, value):
        self._intf.write(self._base_addr + self.PCA9554_ADD, array('B', pack('BB', self.PCA9554_CFG, value)))  # configure output lines

    def _read_input_port(self):
        self._intf.write(self._base_addr + self.PCA9554_ADD, array('B', pack('B', self.PCA9554_IN)))  # set command byte
        return unpack_from('B', self._intf.read(self._base_addr + self.PCA9554_ADD | 1, size=1))[0]  # read input lines

    def _write_output_port(self, value):
        self._intf.write(self._base_addr + self.PCA9554_ADD, array('B', pack('BB', self.PCA9554_OUT, value)))  # write output lines

    def _read_output_port(self):
        self._intf.write(self._base_addr + self.PCA9554_ADD, array('B', pack('B', self.PCA9554_OUT)))
        return unpack_from('B', self._intf.read(self._base_addr + self.PCA9554_ADD | 1, size=1))[0]

    def _set_output_port(self, mask):
        self._write_output_port(mask | self._read_output_port())

    def _clear_output_port(self, mask):
        self._write_output_port(~mask & self._read_output_port())

    def _get_input_port(self, mask):
        return True if ((mask & self._read_input_port()) == mask) else False


class PowerGpio(GpioPca9554):
    '''Power GPIO
    '''
    POWER_GPIO_ADD = GpioPca9554.PCA9554_BASE_ADD | 0x02
    POWER_GPIO_CFG = 0xf0  # LSB -> ON, MSB -> OC (over current read back)

    def __init__(self, intf, conf):
        super(PowerGpio, self).__init__(intf, conf)
        self.PCA9554_ADD = self.POWER_GPIO_ADD
        self.GPIO_CFG = self.POWER_GPIO_CFG


class AdcMuxGpio(GpioPca9554):
    '''ADC NUX GPIO
    '''
    ADCMUX_GPIO_ADD = GpioPca9554.PCA9554_BASE_ADD
    ADCMUX_GPIO_CFG = 0x00  # all outputs

    def __init__(self, intf, conf):
        super(AdcMuxGpio, self).__init__(intf, conf)
        self.PCA9554_ADD = self.ADCMUX_GPIO_ADD
        self.GPIO_CFG = self.ADCMUX_GPIO_CFG


class CalMuxGpio(GpioPca9554):
    '''CAL MUX GPIO
    '''
    CALMUX_GPIO_ADD = GpioPca9554.PCA9554_BASE_ADD | 0x08
    CALMUX_GPIO_CFG = 0x00  # all outputs
    CALMUX_GPIO_SEL = 0x20
    CALMUX_GPIO_INHB = 0x40

    def __init__(self, intf, conf):
        super(CalMuxGpio, self).__init__(intf, conf)
        self.PCA9554_ADD = self.CALMUX_GPIO_ADD
        self.GPIO_CFG = self.CALMUX_GPIO_CFG


class DacDac7578(HardwareLayer):
    '''DAC 7578

    Set voltage and current (GPAC).
    '''
    DAC7578_CMD_WRITE_CH = 0x00  # write DAC input register channel
    DAC7578_CMD_UPDATE_CH = 0x10  # write DAC input register channel
    DAC7578_CMD_WRITE_UPDATE_CH = 0x30  # write and update DAC input register channel
    DAC7578_CMD_POWER = 0x40  # Power down/on DAC
    DAC7578_CMD_POWER = 0x50  # Software reset DAC

    def __init__(self, intf, conf):
        super(DacDac7578, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _set_dac_value(self, address, dac_ch, value):
        msb = (value >> 4)  # MSB first
        lsb = (value << 4) & 0xff  # LSB left aligned

        data = array('B', pack('BBB', self.DAC7578_CMD_WRITE_UPDATE_CH | dac_ch, msb, lsb))
        self._intf.write(self._base_addr + address, data)


class AdcMax11644(HardwareLayer):
    '''ADC MAX11644

    Read current and voltage (GPAC).
    '''
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

    def __init__(self, intf, conf):
        super(AdcMax11644, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def _setup_adc(self, flags):
        '''Initialize ADC
        '''
        self._intf.write(self._base_addr + self.MAX11644_ADD, array('B', pack('B', flags | self.MAX11644_SETUP)))

    def _get_adc_value(self, average=None):
        def read_data():
            self._intf.write(self._base_addr + self.MAX11644_ADD, array('B', pack('B', self.ADC_CONF)))  # single-ended inputs, conversion of both channels in a scan

            data = self._intf.read(self._base_addr + self.MAX11644_ADD | 1, size=4)
            raw = unpack_from('>HH', data)
            return raw[0] & 0xfff, raw[1] & 0xfff  # ch0, ch1

        if average:
            raw_ch0 = 0
            raw_ch1 = 0
            for _ in range(average):
                tmp_raw_ch0, tmp_raw_ch1 = read_data()
                raw_ch0 += tmp_raw_ch0
                raw_ch1 += tmp_raw_ch1
            raw_ch0 /= average
            raw_ch1 /= average
        else:
            raw_ch0, raw_ch1 = read_data()

        return raw_ch0, raw_ch1


class I2cAnalogChannel(AdcMax11644, DacDac7578, MuxPca9540B):
    I2CBUS_ADC = MuxPca9540B.PCA9540B_SEL_CH1
    I2CBUS_DAC = MuxPca9540B.PCA9540B_SEL_CH0
    I2CBUS_DEFAULT = MuxPca9540B.PCA9540B_SEL_NONE

    def __init__(self, intf, conf):
        super(I2cAnalogChannel, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']
        self.adc_mux_gpio = AdcMuxGpio(intf, conf)
        self.power_gpio = PowerGpio(intf, conf)

    def init(self):
        # setup PWR GPIO
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DAC)
        self.power_gpio.init()

        # setup ADC GPIO
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_ADC)
        self.adc_mux_gpio.init()

        # setup ADC
        AdcMax11644._setup_adc(self, self.MAX11644_EXT_REF)

        # setup I2C Mux default
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)

    def _set_dac_value(self, address, dac_ch, value):
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DAC)
        DacDac7578._set_dac_value(self, address=address, dac_ch=dac_ch, value=value)
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)

    def _get_adc_value(self, address):
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_ADC)
        self.adc_mux_gpio._write_output_port(value=address)
        if 15 < address < 20:
            AdcMax11644._setup_adc(self, self.MAX11644_INT_REF)
            sleep(0.010)
        adc_ch0, adc_ch1 = AdcMax11644._get_adc_value(self)
        if 15 < address < 20:
            AdcMax11644._setup_adc(self, self.MAX11644_EXT_REF)
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)
        return adc_ch0, adc_ch1

    def _set_power_gpio_value(self, bit, value):
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DAC)
        if value:
            self.power_gpio._set_output_port(bit)
        else:
            self.power_gpio._clear_output_port(bit)
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)

    def _get_power_gpio_value(self, bit):
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DAC)
        value = self.power_gpio._get_input_port(bit)
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)
        return value


class I2cEeprom(Eeprom24Lc128, MuxPca9540B):
    I2CBUS_ADC = MuxPca9540B.PCA9540B_SEL_CH1
    I2CBUS_DAC = MuxPca9540B.PCA9540B_SEL_CH0
    I2CBUS_DEFAULT = MuxPca9540B.PCA9540B_SEL_NONE

    def _read_eeprom(self, address, size):
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DAC)
        data = Eeprom24Lc128._read_eeprom(self, address, size)
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)
        return data

    def _write_eeprom(self, address, data):
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DAC)
        data = Eeprom24Lc128._write_eeprom(self, address, data)
        MuxPca9540B._set_i2c_mux(self, self.I2CBUS_DEFAULT)


class GPAC(I2cAnalogChannel, I2cEeprom):
    '''GPAC interface

    Note:
    - Solder 100 Ohm resistor parallel to C55
    - Replace R14 by 50 Ohm resistor (0 Ohm on some cards)
    - Close JP2 (2-3, SENSE-GND)
    - Close JP3 (2-3, REF_2.048V-VREF_1)
    - Outputs are clamped to potential of PWR0, keep potential of PWR0 close to supply voltage
    '''
    # EEPROM data V1
    HEADER_GPAC = 0xa101
    HEADER_ADDR = 0
    HEADER_FORMAT = '>H'  # Version of EEPROM data
    ID_ADDR = HEADER_ADDR + calcsize(HEADER_FORMAT)
    ID_FORMAT = '>H'  # Adapter Card ID
    CAL_DATA_CH_GPAC_FORMAT = '64sdddddddddd'
    CAL_DATA_ADDR = ID_ADDR + calcsize(ID_FORMAT)
    CAL_DATA_GPAC_FORMAT = '<' + 22 * CAL_DATA_CH_GPAC_FORMAT

    # DAC
    DAC7578_1_ADD = 0x90
    DAC7578_2_ADD = 0x94
    DAC7578_3_ADD = 0x98

    # Current limit
    CURRENT_LIMIT_GAIN = 20.0
    CURRENT_LIMIT_DAC_CH = 0
    CURRENT_LIMIT_DAC_SLAVE_ADD = DAC7578_1_ADD

    # Channel mappings
    _ch_map = {
        'PWR0': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 1},
            'ADCV': {'address': 16, 'adc_ch': 0},
            'ADCI': {'address': 16, 'adc_ch': 1},
            'GPIOEN': {'bit': 1},
            'GPIOOC': {'bit': 16},
        },
        'PWR1': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 2},
            'ADCV': {'address': 17, 'adc_ch': 0},
            'ADCI': {'address': 17, 'adc_ch': 1},
            'GPIOEN': {'bit': 2},
            'GPIOOC': {'bit': 32},
        },
        'PWR2': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 3},
            'ADCV': {'address': 18, 'adc_ch': 0},
            'ADCI': {'address': 18, 'adc_ch': 1},
            'GPIOEN': {'bit': 4},
            'GPIOOC': {'bit': 64},
        },
        'PWR3': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 4},
            'ADCV': {'address': 19, 'adc_ch': 0},
            'ADCI': {'address': 19, 'adc_ch': 1},
            'GPIOEN': {'bit': 8},
            'GPIOOC': {'bit': 128},
        },
        'VSRC0': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 1},
            'ADCV': {'address': 15, 'adc_ch': 0},
            'ADCI': {'address': 15, 'adc_ch': 1},
        },

        'VSRC1': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 2},
            'ADCV': {'address': 14, 'adc_ch': 0},
            'ADCI': {'address': 14, 'adc_ch': 1},
        },

        'VSRC2': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 3},
            'ADCV': {'address': 13, 'adc_ch': 0},
            'ADCI': {'address': 13, 'adc_ch': 1},
        },

        'VSRC3': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 4},
            'ADCV': {'address': 12, 'adc_ch': 0},
            'ADCI': {'address': 12, 'adc_ch': 1},
        },
        'INJ0': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 5},
        },
        'INJ1': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 6},
        },
        'ISRC0': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 5},
            'ADCV': {'address': 20, 'adc_ch': 0},
            'ADCI': {'address': 20, 'adc_ch': 1},
        },
        'ISRC1': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 6},
            'ADCV': {'address': 21, 'adc_ch': 0},
            'ADCI': {'address': 21, 'adc_ch': 1},
        },
        'ISRC2': {
            'DAC': {'address': DAC7578_1_ADD, 'dac_ch': 7},
            'ADCV': {'address': 22, 'adc_ch': 0},
            'ADCI': {'address': 22, 'adc_ch': 1},
        },
        'ISRC3': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 0},
            'ADCV': {'address': 23, 'adc_ch': 0},
            'ADCI': {'address': 23, 'adc_ch': 1},
        },
        'ISRC4': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 1},
            'ADCV': {'address': 24, 'adc_ch': 0},
            'ADCI': {'address': 24, 'adc_ch': 1},
        },
        'ISRC5': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 2},
            'ADCV': {'address': 25, 'adc_ch': 0},
            'ADCI': {'address': 25, 'adc_ch': 1},
        },

        'ISRC6': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 3},
            'ADCV': {'address': 26, 'adc_ch': 0},
            'ADCI': {'address': 26, 'adc_ch': 1},
        },
        'ISRC7': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 4},
            'ADCV': {'address': 27, 'adc_ch': 0},
            'ADCI': {'address': 27, 'adc_ch': 1},
        },
        'ISRC8': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 5},
            'ADCV': {'address': 28, 'adc_ch': 0},
            'ADCI': {'address': 28, 'adc_ch': 1},
        },
        'ISRC9': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 6},
            'ADCV': {'address': 29, 'adc_ch': 0},
            'ADCI': {'address': 29, 'adc_ch': 1},
        },
        'ISRC10': {
            'DAC': {'address': DAC7578_2_ADD, 'dac_ch': 7},
            'ADCV': {'address': 30, 'adc_ch': 0},
            'ADCI': {'address': 30, 'adc_ch': 1},
        },
        'ISRC11': {
            'DAC': {'address': DAC7578_3_ADD, 'dac_ch': 0},
            'ADCV': {'address': 31, 'adc_ch': 0},
            'ADCI': {'address': 31, 'adc_ch': 1},
        },
        # reead-only
        'VREF': {
            'ADCV': {'address': 0, 'adc_ch': 0},
        },
        'VREF/2': {
            'ADCV': {'address': 1, 'adc_ch': 0},
        },
        'AUX0': {
            'ADCV': {'address': 11, 'adc_ch': 0},
        },
        'AUX1': {
            'ADCV': {'address': 10, 'adc_ch': 0},
        },
        'AUX2': {
            'ADCV': {'address': 9, 'adc_ch': 0},
        },
        'AUX3': {
            'ADCV': {'address': 8, 'adc_ch': 0},
        },
    }

    def __init__(self, intf, conf):
        super(GPAC, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

        # Channel calibrations
        self._ch_cal = OrderedDict([
            ('PWR0', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 2826.0, 'gain': -0.5},
                'ADCV': {'offset': 0.0, 'gain': 1.0},
                'ADCI': {'offset': 0.0, 'gain': 10.0}
            }),
            ('PWR1', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 2826.0, 'gain': -0.5},
                'ADCV': {'offset': 0.0, 'gain': 1.0},
                'ADCI': {'offset': 0.0, 'gain': 10.0}
            }),
            ('PWR2', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 2826.0, 'gain': -0.5},
                'ADCV': {'offset': 0.0, 'gain': 1.0},
                'ADCI': {'offset': 0.0, 'gain': 10.0}
            }),
            ('PWR3', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 2826.0, 'gain': -0.5},
                'ADCV': {'offset': 0.0, 'gain': 1.0},
                'ADCI': {'offset': 0.0, 'gain': 10.0}
            }),
            ('VSRC0', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 0.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('VSRC1', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 0.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('VSRC2', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 0.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('VSRC3', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 0.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('INJ0', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 0.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('INJ1', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': 0.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC0', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC1', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC2', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC3', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC4', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC5', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC6', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC7', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC8', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC9', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC10', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
            ('ISRC11', {
                'name': '',
                'default': 0.0,
                'min': 0.0,
                'max': 1.0,
                'limit': 0.0,  # PWR only
                'Vref': float('nan'),
                'DAC': {'offset': -1024.0, 'gain': 0.5},
                'ADCV': {'offset': 0.0, 'gain': 2.0},
                'ADCI': {'offset': 0.0, 'gain': 2.0}
            }),
        ])

    def init(self):
        # init DACs and ADCs
        super(GPAC, self).init()

        self._init.setdefault('no_calibration', False)
        # read calibration
        if not self._init['no_calibration']:
            self.read_eeprom_calibration()
            logging.info('Found adapter card: {}'.format('%s with ID %s' % ('General Purpose Analog Card', self.get_id())))
        else:
            logging.info('GPAC: Skeeping calibration.')

        # setup current limit and current source
        self.set_current_limit('PWR0', 0.1)
        for i in range(12):
            self.set_current('ISRC' + str(i), 0.0)

    def read_eeprom_calibration(self):  # use default values for temperature, EEPROM values are usually not calibrated and random
        '''Reading EEPROM calibration for sources and regulators
        '''
        header = self.get_format()
        if header == self.HEADER_GPAC:
            data = self._read_eeprom(self.CAL_DATA_ADDR, size=calcsize(self.CAL_DATA_GPAC_FORMAT))
            for idx, channel in enumerate(self._ch_cal.iterkeys()):
                ch_data = data[idx * calcsize(self.CAL_DATA_CH_GPAC_FORMAT):(idx + 1) * calcsize(self.CAL_DATA_CH_GPAC_FORMAT)]
                values = unpack_from(self.CAL_DATA_CH_GPAC_FORMAT, ch_data)
                self._ch_cal[channel]['name'] = "".join([c for c in values[0] if (c in string.printable)])  # values[0].strip()
                self._ch_cal[channel]['default'] = values[1]
                self._ch_cal[channel]['min'] = values[2]
                self._ch_cal[channel]['max'] = values[3]
                self._ch_cal[channel]['ADCI']['gain'] = -values[4]  # fix gain sign
                self._ch_cal[channel]['ADCI']['offset'] = values[5]
                self._ch_cal[channel]['ADCV']['gain'] = values[6]
                self._ch_cal[channel]['ADCV']['offset'] = values[7]
                self._ch_cal[channel]['DAC']['gain'] = values[8]
                self._ch_cal[channel]['DAC']['offset'] = values[9]
                self._ch_cal[channel]['limit'] = values[10]
        else:
            raise ValueError('EEPROM data format not supported (header: %s)' % header)

    def get_format(self):
        ret = self._read_eeprom(self.HEADER_ADDR, size=calcsize(self.HEADER_FORMAT))
        return unpack_from(self.HEADER_FORMAT, ret)[0]

    def get_id(self):
        ret = self._read_eeprom(self.ID_ADDR, size=calcsize(self.ID_FORMAT))
        return unpack_from(self.ID_FORMAT, ret)[0]

    def set_voltage(self, channel, value, unit='V'):
        '''Setting voltage
        '''
        dac_offset = self._ch_cal[channel]['DAC']['offset']
        dac_gain = self._ch_cal[channel]['DAC']['gain']

        if unit == 'raw':
            value = value
        elif unit == 'V':
            value = int((value * 1000 - dac_offset) / dac_gain)
        elif unit == 'mV':
            value = int((value - dac_offset) / dac_gain)
        else:
            raise TypeError("Invalid unit type.")

        self._set_dac_value(channel=channel, value=value)

    def get_voltage(self, channel, unit='V'):
        '''Reading voltage
        '''
        adc_ch = self._ch_map[channel]['ADCV']['adc_ch']
        address = self._ch_map[channel]['ADCV']['address']
        raw = self._get_adc_value(address=address)[adc_ch]

        dac_offset = self._ch_cal[channel]['ADCV']['offset']
        dac_gain = self._ch_cal[channel]['ADCV']['gain']

        voltage = ((raw - dac_offset) / dac_gain)

        if unit == 'raw':
            return raw
        elif unit == 'V':
            return voltage / 1000
        elif unit == 'mV':
            return voltage
        else:
            raise TypeError("Invalid unit type.")

    def get_current(self, channel, unit='A'):
        '''Reading current
        '''
        values = self._get_adc_value(address=self._ch_map[channel]['ADCI']['address'])
        raw = values[self._ch_map[channel]['ADCI']['adc_ch']]
        dac_offset = self._ch_cal[channel]['ADCI']['offset']
        dac_gain = self._ch_cal[channel]['ADCI']['gain']

        if 'PWR' in channel:
            current = ((raw - dac_offset) / dac_gain)

            if unit == 'raw':
                return raw
            elif unit == 'A':
                return current / 1000
            elif unit == 'mA':
                return current
            elif unit == 'uA':
                return current * 1000
            else:
                raise TypeError("Invalid unit type.")
        else:
            voltage = values[self._ch_map[channel]['ADCV']['adc_ch']]
            current = (((raw - voltage) - dac_offset) / dac_gain)

            if unit == 'raw':
                return raw
            elif unit == 'A':
                return current / 1000000
            elif unit == 'mA':
                return current / 1000
            elif unit == 'uA':
                return current
            else:
                raise TypeError("Invalid unit type.")

    def set_enable(self, channel, value):
        '''Enable/Disable output of power channel
        '''
        try:
            bit = self._ch_map[channel]['GPIOEN']['bit']
        except KeyError:
            raise ValueError('set_enable() not supported for channel %s' % channel)
        self._set_power_gpio_value(bit=bit, value=value)

    def get_over_current(self, channel):
        '''Reading over current status of power channel
        '''
        try:
            bit = self._ch_map[channel]['GPIOOC']['bit']
        except KeyError:
            raise ValueError('get_over_current() not supported for channel %s' % channel)
        return not self._get_power_gpio_value(bit)

    def set_current_limit(self, channel, value, unit='A'):
        '''Setting current limit

        Note: same limit for all channels.
        '''
        # TODO: add units / calibration
        if unit == 'raw':
            value = value
        elif unit == 'A':
            value = int(value * 1000 * self.CURRENT_LIMIT_GAIN)
        elif unit == 'mA':
            value = int(value * self.CURRENT_LIMIT_GAIN)
        elif unit == 'uA':
            value = int(value / 1000 * self.CURRENT_LIMIT_GAIN)
        else:
            raise TypeError("Invalid unit type.")

        I2cAnalogChannel._set_dac_value(self, address=self.CURRENT_LIMIT_DAC_SLAVE_ADD, dac_ch=self.CURRENT_LIMIT_DAC_CH, value=value)

    def set_current(self, channel, value, unit='A'):
        '''Setting current of current source
        '''
        dac_offset = self._ch_cal[channel]['DAC']['offset']
        dac_gain = self._ch_cal[channel]['DAC']['gain']
        if unit == 'raw':
            value = value
        elif unit == 'A':
            value = int((-value * 1000000 - dac_offset) / dac_gain)  # fix sign of output
        elif unit == 'mA':
            value = int((-value * 1000 - dac_offset) / dac_gain)  # fix sign of output
        elif unit == 'uA':
            value = int((-value - dac_offset) / dac_gain)  # fix sign of output
        else:
            raise TypeError("Invalid unit type.")

        self._set_dac_value(channel=channel, value=value)

    def _get_adc_value(self, address):
        raw_ch0, raw_ch1 = I2cAnalogChannel._get_adc_value(self, address=address)
        return raw_ch0, raw_ch1

    def _set_dac_value(self, channel, value):
        # due to small offset and gain variations value can be slightly nagative
        if -2 < value < 0:
            value = 0
        # if value is greater than maximum dac value, set it to maximum and output an error message
        if value > 4095:
            value = 4095
            logging.warning('%s DAC value reached maximum value', channel)
        I2cAnalogChannel._set_dac_value(self, value=value, **self._ch_map[channel]['DAC'])
