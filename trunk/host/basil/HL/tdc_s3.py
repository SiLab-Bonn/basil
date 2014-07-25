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

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from struct import unpack_from


class tdc_s3(RegisterHardwareLayer):
    '''TDC controller interface
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'ENABLE': {'descr': {'addr': 1, 'size': 1, 'offset': 0}},
                  'ENABLE_EXTERN': {'descr': {'addr': 1, 'size': 1, 'offset': 1}},
                  'EN_ARMING': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},
                  'EN_WRITE_TIMESTAMP': {'descr': {'addr': 1, 'size': 1, 'offset': 3}},
                  'EVENT_COUNTER': {'descr': {'addr': 2, 'size': 32, 'properties': ['ro']}}
    }

    def __init__(self, intf, conf):
        super(tdc_s3, self).__init__(intf, conf)

#    def init(self):
#        self.reset()

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
        reg = self._intf.read(self._conf['base_addr'] + 1, size=1)[0]
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
        ret = self._intf.read(self._conf['base_addr'] + 2, size=4)
        return unpack_from('I', ret)[0]
