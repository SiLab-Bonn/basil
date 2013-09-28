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


class spi(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def init(self):
        self.reset()
        
    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])
        
    def set_size(self, value):
        self._intf.write(self._conf['base_addr'] + 3, unpack('BBBB', pack('>L', value))[2:4])

    def get_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 2)
        return ret[0] * (2 ** 8) + ret[1]

    def set_wait(self, value):
        self._intf.write(self._conf['base_addr'] + 5, unpack('BBBB', pack('>L', value))[2:4])

    def get_wait(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, 2)
        return ret[0] * (2 ** 8) + ret[1]

    def set_repeat(self, value):
        self._intf.write(self._conf['base_addr'] + 7, [value])

    def get_repeat(self):
        self._intf.read(self._conf['base_addr'] + 7, 1)[0]

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'], 1)[0] & 0x01) else False

    def set_data(self, addr, data):
        self._intf.write(self._conf['base_addr'] + 8 + addr, data)

    def get_data(self, addr=0, size=None):
        if(size == None):
            size = self._conf['mem_bytes']

        return self._intf.read(self._conf['base_addr'] + 8 + self._conf['mem_bytes'], size)
