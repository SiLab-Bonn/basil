import logging
import time

from basil.HL.RegisterHardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class rs_HMP4040(HardwareLayer):
    '''
    HL for the RS HMP4040
    !! Analog to tti ql355tp for compatibility with bdaq53
    '''

    def __init__(self, intf, conf):
        super(rs_HMP4040, self).__init__(intf, conf)

    def init(self):
        super(rs_HMP4040, self).init()

    def reinit(self):
        self._intf.init()

    def write(self, command):
        self._intf.write(command)
        time.sleep(0.1)

    def ask(self, command):
        self.write(command)
        return self.read()

    def read(self):
        ret = self._intf.read()
        time.sleep(0.1)
        return ret

    def set_channel(self, channel):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        cmd = "INST:NSEL %d" % channel
        self.write(cmd)

    def get_channel(self):
        ret = self.ask("INST:NSEL?")
        return ret

    def set_enable(self, on, channel=1):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4, ALL=all channels"""
        if channel=="ALL":
            for i in [1, 2, 3, 4]:
                self.set_enable(on, channel=i)
        else:
            self.set_channel(channel)

            if on:
                cmd = "OUTP ON"
            else:
                cmd = "OUTP OFF"

            self.write(cmd)
        time.sleep(1)

    def get_name(self):
        return self.ask("*IDN?")

    def get_current(self, channel):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        self.set_channel(channel)
        ret = self.ask("MEAS:CURR?")

        return float(ret)

    def get_voltage(self, channel):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        self.set_channel(channel)
        ret = self.ask("MEAS:VOLT?")

        return float(ret)

    def get_set_voltage(self, channel):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        self.set_channel(channel)
        ret = self.ask("VOLT?")

        return float(ret)

    def get_current_limit(self, channel):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        self.set_channel(channel)
        ret = self.ask("CURR?")

        return float(ret)

    def set_voltage(self, value, channel=1):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        self.set_channel(channel)
        cmd = "VOLT %f" % value
        self.write(cmd)

    def set_current_limit(self, value, channel=1):
        """ channel: 1=OP1, 2=OP2, 3=OP3, 4=OP4"""
        self.set_channel(channel)
        cmd = "CURR %f" % value
        self.write(cmd)

    def reset_trip(self):
        cmd = "VOLT:PROT:CLE"
        self.write(cmd)
        time.sleep(1)
