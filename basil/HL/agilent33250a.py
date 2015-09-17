#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import string

from basil.HL.scpi import scpi


class agilent33250a(scpi):

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
        self.set_voltage_high(raw_high)
        self.set_voltage_low(raw_low)

    def get_voltage(self, channel, unit='mV'):
        raw_low, raw_high = string.atof(self.get_voltage_low()), string.atof(self.get_voltage_high())
        if unit == 'raw':
            return raw_low, raw_high
        elif unit == 'V':
            return raw_low, raw_high
        elif unit == 'mV':
            return raw_low * 1000, raw_high * 1000
        else:
            raise TypeError("Invalid unit type.")

    def set_en(self, enable):  # TODO: bad naming
        self.set_burst(1) if enable else self.set_burst(0)

    def get_en(self):  # TODO: bad naming
        return self.get_burst() == 1

    def get_info(self):
        return self.get_name()
