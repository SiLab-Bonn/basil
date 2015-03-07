#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import Agilent33250A

from basil.HL.HardwareLayer import HardwareLayer


class agilent33250a(HardwareLayer):
    '''interface for Agilent 33250A
    '''
    def __init__(self, intf, conf):
        super(agilent33250a, self).__init__(intf, conf)

    def init(self):
        self.s = Agilent33250A.Agilent33250A(port=self._init['port'])

    def set_repeat(self, repeat):
        raise NotImplementedError("Not implemented")

    def get_repeat(self, repeat):
        raise NotImplementedError("Not implemented")

    def set_voltage(self, low, high, unit='mV'):
        if unit == 'raw':
            raw_low = low
            raw_high = high
        elif unit == 'V':
            raw_low = low
            raw_high = high
        elif unit == 'mV':
            raw_low = low * 0.001
            raw_high = high * 0.001
        else:
            raise TypeError("Invalid unit type.")
        self.s.put_voltage(raw_low, raw_high)

    def get_voltage(self, channel, unit='mV'):
        raw_low, raw_high = self.s.get_voltage()
        if unit == 'raw':
            return raw_low, raw_high
        elif unit == 'V':
            return raw_low, raw_high
        elif unit == 'mV':
            return raw_low * 1000, raw_high * 1000
        else:
            raise TypeError("Invalid unit type.")

    def set_en(self, enable):
        self.s.put_burst(enable)

    def get_en(self):
        return self.s.get_burst()

    def get_info(self):
        return self.s.get_version()
