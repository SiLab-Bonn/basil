#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
import binascii
import codecs

from basil.HL.RegisterHardwareLayer import HardwareLayer


class sensirionEKH4(HardwareLayer):
    '''Driver for the Sensirion EK-H4 multiplexer box. Can be used to read up to 4 channels of sensirion sensors for humidity and temperature
    (http://www.sensirion.com/en/products/humidity-temperature/evaluation-kits/ek-h4/).
    A TLV protocoll via serial port is used with 115200 baud rate. The type byte definitions cannot be found online...
    The data returned by the device is often too long. Different cases are handled and not reconsturctable channels are set to None.
    '''

    def __init__(self, intf, conf):
        super(sensirionEKH4, self).__init__(intf, conf)

    def init(self):
        super(sensirionEKH4, self).init()
        self._write(r"7e230200013102010c25010e2601033a7e")  # set update interval to 1Hz
        self._intf.read(size=1024)  # clear buffer

    def _write(self, command):
        self._intf.write(binascii.a2b_hex(command))

    def _read(self):
        word = ''
        data_flg = 0
        for _ in range(1024):
            b = codecs.encode(self._intf.read(size=1), 'hex_codec').decode('utf-8')

            if b == '7e':       # delimiter
                if data_flg == 0:    # data word comes next
                    data_flg = 1
                else:           # data word finished
                    break
            elif data_flg == 1:
                word += b

        return word

    def _query(self, command):
        self._write(command)
        time.sleep(0.1)
        return self._read()

    def _calc_value(self, value):
        '''
            Calculate two's complement of signed binary, if applicable.
        '''
        bits = 16
        value = int(value, 16)
        if (value & (1 << (bits - 1))) != 0:  # if sign bit is set, e.g., 8bit: 128-255
            value = value - (1 << bits)  # compute negative value
        return float(value) / 100.0

    def _get_values(self, cmd):
        '''
            Retrieve raw values via self._query and do error correction if possible
            First 4 characters of data word are unknown ("4608", "4708" or "4808").
            Last two characters seem to be some kind of checksum?
            In between there should be 16 characters, 4 per channel. Sometimes it's more.
            Two cases can be distinguished here:
                1. Some kind of common error code "7d31" plus an additional byte.
                    In this case, the affected channel is set to None,
                    the extra byte is removed and the other channels are interpreted as usual.
                2. Varying amount of extra bytes with no recognizable error code.
                    In this case, nothing can be reconstructed and all channels are set to None.

            Case 1 is reproducable for temperatures between about 43.53C and 46.1C...?
        '''
        ret = self._query(cmd)[4:-2]
        # Cut off extra bytes in case of error
        for i in range(0, 16, 4):
            if ret[i:i + 4] == '7d31':
                ret = ret[:i + 4] + ret[i + 6:]

        if len(ret) != 16:  # wrong number of bytes despite attempted error correction
            values = [None, None, None, None]
        else:
            values = []
            data = [ret[j:j + 4] for j in range(0, len(ret), 4)]
            for i, d in enumerate(data):
                if d == '7d31' or d == '7fff':  # Error or no sensor connected
                    values.append(None)
                else:
                    values.append(self._calc_value(d))

        return values

    def get_temperature(self, channel=None):
        values = self._get_values(r"7e4700b87e")

        if channel is None:
            return values
        return values[channel]

    def get_humidity(self, channel=None):
        values = self._get_values(r"7e4600b97e")

        if channel is None:
            return values
        return values[channel]

    def get_dew_point(self, channel=None):
        values = self._get_values(r"7e4800b77e")

        if channel is None:
            return values
        return values[channel]
