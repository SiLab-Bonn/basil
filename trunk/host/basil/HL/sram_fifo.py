# SiLab , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from basil.HL.HardwareLayer import HardwareLayer
from struct import pack, unpack_from
from array import array
from time import sleep
import numpy as np


class sram_fifo(HardwareLayer):
    '''SRAM FIFO controller interface for sram_fifo FPGA module.
    '''
    def __init__(self, intf, conf):
        super(sram_fifo, self).__init__(intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))
        sleep(0.01)  # wait some time for initialization

    def set_almost_full_threshold(self, value):
        self._intf.write(self._conf['base_addr'] + 1, array.array('B', pack('B', value)))  # no get function possible

    def set_almost_empty_threshold(self, value):
        self._intf.write(self._conf['base_addr'] + 2, array.array('B', pack('B', value)))  # no get function possible

    def get_fifo_size(self):
        '''
        Get FIFO size in units of two bytes (16 bit).

        Returns
        -------
        fifo_size : int
            FIFO size in units of shorts (16 bit).
        '''
        ret = self._intf.read(self._conf['base_addr'] + 1, size=3)
        ret.append(0)  # increase to 4 bytes to do the conversion
        return unpack_from('I', ret)[0]

    def get_fifo_int_size(self):
        '''
        Get FIFO size in units of integers (32 bit).

        Returns
        -------
        fifo_size : int
            FIFO size in units of integers (32 bit).
        '''
        fifo_size = self.get_fifo_size()
        # sometimes reading of FIFO size happens during writing to SRAM, but we want to have a multiplicity of 32 bits
        return (fifo_size - (fifo_size % 2)) / 2

    def get_read_error_counter(self):
        '''
        Get read error counter.

        Returns
        -------
        fifo_size : int
            Read error counter (read attempts when SRAM is empty).
        '''
        ret = self._intf.read(self._conf['base_addr'] + 4, size=1)
        return unpack_from('B', ret)[0]

    def get_data(self):
        '''
        Reading data in SRAM.

        Returns
        -------
        array : numpy.ndarray
            Array of unsigned integers (32 bit).
        '''
        fifo_int_size = self.get_fifo_int_size()
        if fifo_int_size:
            return np.fromstring(self._intf.read(self._conf['base_data_addr'], size=4 * fifo_int_size).tostring(), dtype=np.dtype('>u4'))  # size in number of bytes
        else:
            return np.array([], dtype=np.dtype('>u4'))
