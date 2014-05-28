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
import numpy as np


class sram_fifo(HardwareLayer):
    '''
    SRAM FIFO controller interface for sram_fifo FPGA module
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
        '''
        Get FIFO size in units of two bytes (16 bits)
        '''
        ret = self._intf.read(self._conf['base_addr'] + 1, size=3)
        ret.append(0)  # increase to 4 bytes to do the conversion
        return unpack_from('I', ret)[0]

    def get_fifo_int_size(self):
        fifo_size = self.get_fifo_size(self)
        # sometimes a read happens during writing, but we want to have a multiplicity of 32 bits
        return (fifo_size - (fifo_size % 2)) / 2

    def get_read_error_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 4, size=1)
        return unpack_from('B', ret)[0]

    def get_data(self):
        fifo_int_size = self.get_fifo_int_size()
        if fifo_int_size:
            return np.fromstring(self._intf.read(self._conf['base_data_addr'], size=4 * fifo_int_size).tostring(), dtype=np.dtype('>u4'))  # size is number of bytes
        else:
            return np.array([], dtype=np.dtype('>u4'))
