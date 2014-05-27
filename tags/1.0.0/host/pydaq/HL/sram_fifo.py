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
from time import sleep


class SramFifoDriver(HardwareLayer):
    '''
    FEI4 Rx Controller Interface
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))
        sleep(0.2)  # wait for deleting

    def set_almost_full_threshold(self, value):
        self._intf.write(self._conf['base_addr'] + 1, array.array('B', pack('B', value)))  # no get function possible

    def set_almost_empty_threshold(self, value):
        self._intf.write(self._conf['base_addr'] + 2, array.array('B', pack('B', value)))  # no get function possible

    def get_fifo_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 1, size=3)
        ret.append(0)  # 4 bytes
        return unpack_from('I', ret)[0]

    def get_read_error_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 4, size=1)
        return unpack_from('B', ret)[0]
