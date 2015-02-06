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

    _registers = {'RESET': {'addr': 0, 'size': 8},
                  'ADDR': {'addr': 1, 'size': 8},
                  'DATA': {'addr': 2, 'size': 8},
                  'START': {'addr': 3, 'size': 8},
                  'CLK_RST': {'addr': 4, 'size': 8}}
    _require_version = "==0"

    def __init__(self, intf, conf):
        super(i2c, self).__init__(intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], 0)

    def start(self):
        self._intf.write(self._conf['base_addr'] + 3, 1)
#         self._intf.write(self._conf['base_addr'] + 3, 0)

#      def stop(self):
#     	self._intf.write(self._conf['base_addr'] + 3, "0")

    def set_addr(self, addr):
        self._intf.write(self._conf['base_addr'] + 1, addr)

    def set_data(self, val):
        self._intf.write(self._conf['base_addr'] + 2, val)

#     def get_data(self):
#        self._intf.read(self._conf['base_addr'] + 2, 1)

    def clk_reset(self):
        self._intf.write(self._conf['base_addr'] + 4, 1)
#         self._intf.write(self._conf['base_addr'] + 4, 0)
