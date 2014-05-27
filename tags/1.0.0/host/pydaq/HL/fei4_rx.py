#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 183                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-05-27 11:55:36 #$:
#

from HL.HardwareLayer import HardwareLayer
from struct import pack, unpack, unpack_from
from array import array


class Fei4RxDriver(HardwareLayer):
    '''
    FEI4 Rx Controller Interface
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self.soft_reset()
        self.fifo_reset()

    def soft_reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def fifo_reset(self):
        self._intf.write(self._conf['base_addr'] + 1, (0,))

    @property
    def is_ready(self):
        return (self._intf.read(self._conf['base_addr'] + 2, size=1)[0] & 0x01) == 1

    def set_invert_rx(self, value):
        reg = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = ((value & 0x01) << 1) | (reg & 0xfd)
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def get_invert_rx(self):
        return True if (self._intf.read(self._conf['base_addr'] + 2, size=1)[0] & 0x02) else False

    def get_fifo_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, size=2)
        return unpack_from('H', ret)[0]

    def get_decoder_error_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, size=1)
        return unpack_from('B', ret)[0]

    def get_lost_data_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 6, size=1)
        return unpack_from('B', ret)[0]
