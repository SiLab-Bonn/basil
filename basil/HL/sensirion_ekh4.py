#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
import binascii

from basil.HL.RegisterHardwareLayer import HardwareLayer


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
        super(sensirionEKH4, self).init()
        self.read()  # clear trash
        # set readout every second
        self.ask(r"7e230200013102010c25010e2601033a7e")

    def write(self, command):
        self._intf.write(binascii.a2b_hex(command))

    def ask(self, command):
        '''Read response to command and convert it to 16-bit integer.
        Returns : list of values
        '''
        self.write(command)
        time.sleep(0.1)
        return self.read()

    def read(self):
        answer = []
        flg = 0
        for i in range(1024):  # data assumed to be less than 1024 words
            a = self._intf.read(size=1).encode('hex_codec')
            if a == '':
                break
            elif flg == 0 and a == '7e':
                flg = 1
            elif flg == 1 and a == '7e':
                break
            elif flg == 1:
                answer.append(a)
        return answer

    def get_temperature(self, min_val=-40, max_val=200):
        ret = self.ask(r"7e4700b87e")
        values = []
        for j in range(4):
            if ret[2 + 2 * j] == "7f" and ret[2 + 2 * j + 1] == "ff":
                values.append(None)
            else:
                values.append(self.cal_ret(
                    ret[2 + 2 * j] + ret[2 + 2 * j + 1]))
        return values

    def get_humidity(self, min_val=0, max_val=100):
        ret = self.ask(r"7e4600b97e")
        values = []
        for j in range(4):
            if ret[2 + 2 * j] == "7f" and ret[2 + 2 * j + 1] == "ff":
                values.append(None)
            else:
                values.append(self.cal_ret(
                    ret[2 + 2 * j] + ret[2 + 2 * j + 1]))
        return values

    def get_dew_point(self, min_val=-40, max_val=100):
        ret = self.ask(r"7e4800b77e")
        values = []
        for j in range(4):
            if ret[2 + 2 * j] == "7f" and ret[2 + 2 * j + 1] == "ff":
                values.append(None)
            else:
                values.append(self.cal_ret(
                    ret[2 + 2 * j] + ret[2 + 2 * j + 1]))
        return values

    def cal_ret(self, value):
        bits = 16
        value = int(value, 16)
        # compute the 2's compliment of int value
        if (value & (1 << (bits - 1))) != 0:  # if sign bit is set, e.g., 8bit: 128-255
            value = value - (1 << bits)  # compute negative value
        return float(value) / 100.0  # return positive value as is
