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


class fadc_rx(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_align_to_sync(self, value=True):
        current = self._intf.read(self._conf['base_addr'] + 2, 1)[0]
        self._intf.write(self._conf['base_addr'] + 2, [current | value])
    
    def get_align_to_sync(self):
        return True if (self._intf.read(self._conf['base_addr'] + 2, 1)[0] & 0x01) else False

    def set_data_count(self, count):
        self._intf.write(self._conf['base_addr'] + 3, unpack('BBBB', pack('>L', count))[1:4])

    def get_data_count(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 3)
        return ret[0] * (2 ** 16) + ret[1] * (2 ** 8) + ret[2]

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 1)[0] & 0x01) else False