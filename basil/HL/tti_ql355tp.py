#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time

from basil.HL.RegisterHardwareLayer import HardwareLayer


class ttiQl355tp(HardwareLayer):
    ''' HL for the TTi QL3335TP.
    '''

    def __init__(self, intf, conf):
        super(ttiQl355tp, self).__init__(intf, conf)

    def init(self):
        super(ttiQl355tp, self).init()

    def reinit(self):
        self._intf.init()

    def write(self, command):
        self._intf.write(command)

    def ask(self, command):
        self.write(command)
        time.sleep(0.1)
        return self.read()

    def read(self):
        ret = self._intf.read()
        if ret[-2:] != "\r\n":
            print "ttiTp355tp.read() terminator error"
        return ret[:-2]

    def set_enable(self, on, channel=1):
        """ channel: 1=OP1, 2=OP2, 3=AUX, ALL=all channels"""
        if isinstance(channel, str):
            cmd = "OPALL %d" % int(on)
        elif isinstance(channel, int):
            cmd = "OP%d %d" % (channel, int(on))
        self.write(cmd)

    def get_info(self):
        return self.ask("*IDN?")

    def get_current(self, channel):
        """ channel: 1=OP1, 2=OP2, AUX is not suppoted"""
        ret = self.ask("I%dO?" % channel)
        if ret[-1] != "A":
            print "ttiQl355tp.get_current() format error", ret
            return None
        return float(ret[:-1])

    def get_voltage(self, channel):
        """ channel: 1=OP1, 2=OP2, AUX is not suppoted"""
        ret = self.ask("V%dO?" % channel)
        if ret[-1] != "V":
            print "ttiQl355tp.get_voltage() format error", ret
            return None
        return float(ret[:-1])

    def get_set_voltage(self, channel):
        """ channel: 1=OP1, 2=OP2, AUX is not suppoted"""
        ret = self.ask("V%d?" % channel)
        if ret[:3] != "V%d " % channel:
            print "ttiQl355tp.get_voltage() format error", ret
            return None
        return float(ret[3:])

    def get_current_limit(self, channel):
        """ channel: 1=OP1, 2=OP2, AUX is not suppoted"""
        ret = self.ask("I%d?" % channel)
        if ret[:3] != "I%d " % channel:
            print "ttiQl355tp.get_current_limit() format error", ret
            return None
        return float(ret[3:])

    def set_voltage(self, value, channel=1):
        """ channel: 1=OP1, 2=OP2, AUX is not suppoted"""
        cmd = "V%d %f" % (channel, value)
        self.write(cmd)

    def set_current_limit(self, value, channel=1):
        """ channel: 1=OP1, 2=OP2, AUX is not suppoted"""
        cmd = "I%d %f" % (channel, value)
        self.write(cmd)
