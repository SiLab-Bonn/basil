#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import binascii

from basil.HL.RegisterHardwareLayer import HardwareLayer


class sensirionEKH4(HardwareLayer):

    '''Driver for the Sensirion EK-H4 multiplexer box. Can be used to read up to 4 channels of sensirion sensors for humidity and temperature
    (http://www.sensirion.com/en/products/humidity-temperature/evaluation-kits/ek-h4/).
    A TLV protocoll via serial port is used with 115200 baud rate. The type byte definitions cannot be found online...
    '''

    def __init__(self, intf, conf):
        super(sensirionEKH4, self).__init__(intf, conf)

    def read_values(self, command):
        self._intf.write(binascii.a2b_hex(command))
        answer = self._intf.read(13).encode('hex_codec')
        if len(answer) != 26 or answer[:6] != command[:4] + '08':  # read failed
            return None
        data = answer[6:-4]  # cut away commas and CRC
        values = []
        for value in [data[i:i + 4] for i in range(0, len(data), 4)]:  # every chanel has 16 bit temp value, all 4 channels are always returned
            if value != '7fff':  # std. value if channel has no sensor
                values.append(float(int(value, 16)) / 100.)
            else:
                values.append(None)
        return values

    def get_temperature(self):
        return self.read_values("7e4700b87e")

    def get_humidity(self):
        return self.read_values("7e4600b97e")

    def get_dew_point(self):
        return self.read_values("7e4800b77e")
