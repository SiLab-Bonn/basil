#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class i2c(RegisterHardwareLayer):
    '''I2C module to communicate via i2c_sda and i2c_scl lines
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'ADDR': {'descr': {'addr': 1, 'size': 8}},
                  'DATA': {'descr': {'addr': 2, 'size': 8}},
                  'START': {'descr': {'addr': 3, 'size': 8, 'properties': ['writeonly']}},
                  'CLK_RST': {'descr': {'addr': 4, 'size': 8, 'properties': ['writeonly']}}}
    _require_version = "==0"

    def __init__(self, intf, conf):
        super(i2c, self).__init__(intf, conf)

    def reset(self):
        self.RESET

    def start(self):
        self.START

    def set_addr(self, value):
        self.ADDR = value

    def set_data(self, value):
        self.DATA = value

    def clk_reset(self):
        self.CLK_RST
