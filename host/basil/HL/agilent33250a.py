#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import string

from basil.HL.HardwareLayer import HardwareLayer


class agilent33250a(HardwareLayer):

    '''Interface for Agilent 33250A SCPI device implementing additional functions.
    Based in Tokos implementation.
    '''

    def __init__(self, intf, conf):
        super(agilent33250a, self).__init__(intf, conf)

    def set_repeat(self, repeat):
        raise NotImplementedError("Not implemented")

    def get_repeat(self, repeat):
        raise NotImplementedError("Not implemented")

    def set_voltage(self, low, high=0.75, unit='mV'):
        if unit == 'raw':
            raw_low, raw_high = low, high
        elif unit == 'V':
            raw_low, raw_high = low, high
        elif unit == 'mV':
            raw_low, raw_high = low * 0.001, high * 0.001
        else:
            raise TypeError("Invalid unit type.")
        self._intf.write("VOLT:HIGH %f" % raw_high)
        self._intf.write("VOLT:LOW %f" % raw_low)

    def get_voltage(self, channel, unit='mV'):
        raw_low, raw_high = string.atof(self._intf.query("VOLT:LOW?")), string.atof(self._intf.query("VOLT:HIGH?"))
        if unit == 'raw':
            return raw_low, raw_high
        elif unit == 'V':
            return raw_low, raw_high
        elif unit == 'mV':
            return raw_low * 1000, raw_high * 1000
        else:
            raise TypeError("Invalid unit type.")

    def set_en(self, enable):  # TODO: bad naming
        self._intf.write('BURST:STAT ON' if enable else 'BURST:STAT OFF')

    def get_en(self):  # TODO: bad naming
        return self._intf.query('BURST:STAT?') == 1

    def get_info(self):
        return self._intf.query('*IDN?')
