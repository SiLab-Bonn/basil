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
    if (value & (1 << (bits - 1))) != 0:  # if sign bit is set e.g., 8bit: 128-255
        value = value - (1 << bits)  # compute negative value
    return value  # return positive value as is


class sensirionEKH4(HardwareLayer):

    '''Driver for the Sensirion EK-H4 multiplexer box. Can be used to read up to 4 channels of sensirion sensors for humidity and temperature
    (http://www.sensirion.com/en/products/humidity-temperature/evaluation-kits/ek-h4/).
    A TLV protocoll via serial port is used with 115200 baud rate. The type byte definitions cannot be found online...
    The data returned by the device is often too long, especially for the humidity read out. Still it is interpreted.
    But to avoid unreasonable values a max_value can be set (e.g. rel. humidity < 100). If this values is exceeded None is set for that channel.
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
        time.sleep(0.1)
        answer = self._intf.read().encode('hex_codec')
        time.sleep(0.1)
        if len(answer) < 26 or command[-2:] != '7e' or answer[:6] != command[:4] + '08':  # read failed
            return [None, None, None, None]
        data = answer[6:-4]  # cut away commas and CRC
        values = []
        for value in [data[i:i + 4] for i in range(0, len(data), 4)]:  # every chanel has 16 bit temp value, all 4 channels are always returned
            if value != '7fff':  # std. value if channel has no sensor
                values.append(int(value, 16))
            else:
                values.append(None)
        return values

    def get_temperature(self, min_val=-40, max_val=200):
        values = self.read_values(r"7e4700b87e")
        temperatures = []
        for channel_value in values:
            if channel_value:
                temperature = float(twos_complement(channel_value, 16)) / 100.
                if temperature >= min_val and temperature <= max_val:  # mask unlikely values
                    temperatures.append(temperature)
                else:
                    temperatures.append(None)
            else:
                temperatures.append(None)
        return temperatures

    def get_humidity(self, min_val=0, max_val=100):
        values = self.read_values(r"7e4600b97e")
        humidities = []
        for channel_value in values:
            if channel_value:
                humidity = float(channel_value) / 100.
                if humidity >= min_val and humidity <= max_val:  # mask unlikely values
                    humidities.append(humidity)
                else:
                    humidities.append(None)
            else:
                humidities.append(None)
        return humidities

    def get_dew_point(self, min_val=-40, max_val=100):
        values = self.read_values(r"7e4800b77e")
        dew_points = []
        for channel_value in values:
            if channel_value:
                dew_point = float(channel_value) / 100.
                if dew_point >= min_val and dew_point <= max_val:  # mask unlikely values
                    dew_points.append(dew_point)
                else:
                    dew_points.append(None)
            else:
                dew_points.append(None)
        return dew_points
