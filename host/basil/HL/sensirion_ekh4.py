#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import binascii
import time
from basil.HL.RegisterHardwareLayer import HardwareLayer


def twos_complement(value, bits):
    """compute the 2's compliment of int value"""
    if (value & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        value = value - (1 << bits)        # compute negative value
    return value                           # return positive value as is


class sensirionEKH4(HardwareLayer):

    '''Driver for the Sensirion EK-H4 multiplexer box. Can be used to read up to 4 channels of sensirion sensors for humidity and temperature
    (http://www.sensirion.com/en/products/humidity-temperature/evaluation-kits/ek-h4/).
    A TLV protocoll via serial port is used with 115200 baud rate. The type byte definitions cannot be found online...
    The data send by the device is often too long. Thus the device is most usable when specifiing read_termination = '7e' and
    write_termination=''
    '''

    def __init__(self, intf, conf):
        super(sensirionEKH4, self).__init__(intf, conf)

    def init(self):
        self._intf.write(binascii.a2b_hex(r"7e230200013102010c25010e2601033a7e"))  # set readout every second

    def read_values(self, command):
        '''Read response to command and convert it to 16-bit integer.
        Returns : list of values
        '''
        self._intf.write(binascii.a2b_hex(command))
        answer = self._intf.read().encode('hex_codec')
        if len(answer) != 26 or answer[:6] != command[:4] + '08':  # read failed, often 4 bytes too much
            return None
        data = answer[6:-4]  # cut away commas and CRC
        values = []
        for value in [data[i:i + 4] for i in range(0, len(data), 4)]:  # every chanel has 16 bit temp value, all 4 channels are always returned
            if value != '7fff':  # std. value if channel has no sensor
                values.append(int(value, 16))
            else:
                values.append(None)
        return values

    def get_temperature(self, max_val=200):
        values = self.read_values(r"7e4700b87e")
        if values:
            temperatures = []
            for channel_value in values:
                if channel_value:
                    temperature = float(twos_complement(channel_value, 16)) / 100.
                    if temperature < max_val:  # mask unlikely values
                        temperatures.append(temperature)
                    else:
                        temperatures.append(None)
                else:
                    temperatures.append(None)
            return temperatures
        return [None, None, None, None]  # read failed

    def get_humidity(self, max_val=100):
        values = self.read_values(r"7e4600b97e")
        if values:
            humidities = []
            for channel_value in values:
                if channel_value:
                    humidity = float(channel_value) / 100.
                    if humidity < max_val:  # mask unlikely values
                        humidities.append(humidity)
                    else:
                        humidities.append(None)
                else:
                    humidities.append(None)
            return humidities
        return [None, None, None, None]  # read failed

    def get_dew_point(self):
        return self.read_values(r"7e4800b77e")
