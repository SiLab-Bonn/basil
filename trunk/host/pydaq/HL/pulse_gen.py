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


class pulse_gen(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_delay(self, delay):
        self._intf.write(self._conf['base_addr'] + 3, unpack('BB', pack('>H', delay)))

    def get_delay(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 2)
        return ret[0] * 255 + ret[1]

    def set_width(self, width):
        self._intf.write(self._conf['base_addr'] + 5, unpack('BB', pack('>H', width)))

    def get_width(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, 2)
        return ret[0] * 255 + ret[1]

    def set_en(self, enable):
        #self._intf.write(self._conf['base_addr'] + 2, [0x01])
        current = self._intf.read(self._conf['base_addr'] + 2, 1)[0]
        self._intf.write(self._conf['base_addr'] + 2, [(current & 0xfe) | enable])
        
    def get_en(self):
        return True if (self._intf.read(self._conf['base_addr'] + 2, 1)[0] & 0x01) else False
