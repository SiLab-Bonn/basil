#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from HL.HardwareLayer import HardwareLayer
from struct import pack, unpack


class seq_gen(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        self.reset()
        
    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_size(self, value):
        self._intf.write(self._conf['base_addr'] + 3, unpack('BBBB', pack('>L', value))[2:4])

    def get_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 2)
        return ret[0] * (2 ** 8) + ret[1]

    def set_clk_divide(self, value):
        self._intf.write(self._conf['base_addr'] + 2, [value])

    def get_clk_divide(self):
        return self._intf.read(self._conf['base_addr'] + 2, 1)[0]

    def set_data(self, addr, data):
        self._intf.write(self._conf['base_addr'] + 16 + addr, data)

    def get_data(self, addr, size):
        return self._intf.read(self._conf['base_addr'] + 16 + addr, size)
    
    def set_repaet_start(self, value):
        self._intf.write(self._conf['base_addr'] + 8, unpack('BBBB', pack('>L', value))[2:4])

    def get_repaet_start(self):
        ret = self._intf.read(self._conf['base_addr'] + 8, 2)
        return ret[0] * (2 ** 8) + ret[1]
