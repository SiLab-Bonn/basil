#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import yaml

from basil.HL.HardwareLayer import HardwareLayer
from basil.RL.StdRegister import StdRegister
from basil.utils.BitLogic import BitLogic


jtag_gpio_yaml = """
name        : GPIO
type        : StdRegister
driver      : None
size        : 8
fields:
  - name    : RESETB
    size    : 1
    offset  : 0
  - name    : TCK
    size    : 1
    offset  : 1
  - name    : TMS
    size    : 1
    offset  : 2
  - name    : TDI
    size    : 1
    offset  : 3
  - name    : TDO
    size    : 1
    offset  : 4
"""


class JtagGpio(HardwareLayer):
    '''GPIO based JTAG interface
    '''

    def __init__(self, intf, conf):
        super(JtagGpio, self).__init__(intf, conf)

        cfg = yaml.safe_load(jtag_gpio_yaml)
        self.reg = StdRegister(driver=None, conf=cfg)

        # self.RESETB = 0
        # self.TCK = 0
        # self.reg['TMS'] = 0
        # self.TDI = 0
        # self.TD0 = 0

    def init(self):
        super(JtagGpio, self).init()

    def reset(self):
        self.reg['RESETB'] = 0
        self._write(tck=False)
        self.reg['RESETB'] = 1
        self._write(tck=False)
        self.tms_reset()

    def tms_reset(self):
        for _ in range(5):
            self.reg['TMS'] = 1
            self._write()

        self.reg['TMS'] = 0
        self._write()  # idle

    def scan_ir(self, data):
        self.reg['TMS'] = 1
        self._write()

        self.reg['TMS'] = 1
        self._write()  # select ir

        return self._scan(data)

    def scan_dr(self, data):
        self.reg['TMS'] = 1
        self._write()  # select dr

        return self._scan(data)

    def _scan(self, data):
        self.reg['TMS'] = 0
        self._write()  # capture

        self.reg['TMS'] = 0
        ret_bit = self._write(tdo=True)

        ret = []
        size_dev = len(data)
        for dev in range(size_dev):
            dev_ret = BitLogic(len(data[dev]))
            size = len(data[dev])
            for bit in range(size):
                if dev == len(data) - 1 and bit == len(data[dev]) - 1:
                    self.reg['TMS'] = 1  # exit1
                self.reg['TDI'] = data[dev][bit]
                dev_ret[bit] = ret_bit
                if bit == size - 1 and dev == size_dev - 1:  # last bit
                    self._write()
                else:
                    ret_bit = self._write(tdo=True)
            ret.append(dev_ret)

        self.reg['TDI'] = 0
        self.reg['TMS'] = 1
        self._write()  # update

        self.reg['TMS'] = 0
        self._write()  # idle

        return ret

    def _write(self, tck=True, tdo=False):
        self._intf.set_data(self.reg.tobytes())

        if(tck):
            self.reg['TCK'] = 0
            self._intf.set_data(self.reg.tobytes())
            self.reg['TCK'] = 1
            self._intf.set_data(self.reg.tobytes())
            self.reg['TCK'] = 0
            self._intf.set_data(self.reg.tobytes())

        if tdo:
            return (self._intf.get_data()[0] & 0b0010000) >> 4  # TODO:
