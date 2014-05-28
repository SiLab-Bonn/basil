#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from HL.HardwareLayer import HardwareLayer
from struct import pack, unpack, unpack_from
from array import array


class tdc_s3(HardwareLayer):
    '''
    TDC controller interface
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def get_lost_data_counter(self):
        ret = self._intf.read(self._conf['base_addr'], size=1)
        return unpack_from('B', ret)[0]

    def set_en(self, value):
        reg = self._intf.read(self._conf['base_addr'] + 1, size=1)[0]
        reg = (value & 0x01) | (reg & 0xfe)
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def get_en(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x01) else False

    def set_en_extern(self, value):
        reg = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = ((value & 0x01) << 1) | (reg & 0xfd)
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def get_en_extern(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x02) else False

    def set_arming(self, value):
        reg = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = ((value & 0x01) << 2) | (reg & 0xfb)
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def get_arming(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x04) else False

    def set_write_timestamp(self, value):
        reg = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = ((value & 0x01) << 3) | (reg & 0xf7)
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def get_write_timestamp(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x08) else False

    def get_event_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=2)
        return unpack_from('H', ret)[0]
