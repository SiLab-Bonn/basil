# SiLab , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from struct import pack, unpack_from
from array import array
from time import sleep
import numpy as np


class sram_fifo(RegisterHardwareLayer):
    '''SRAM FIFO controller interface for sram_fifo FPGA module.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'ALMOST_FULL_THRESHOLD': {'descr': {'addr': 1, 'size': 8, 'properties': ['wo']}},
                  'ALMOST_EMPTY_THRESHOLD': {'descr': {'addr': 2, 'size': 8, 'properties': ['wo']}},
                  'FIFO_SIZE': {'descr': {'addr': 1, 'size': 21, 'properties': ['ro']}},
                  'READ_ERROR_COUNTER': {'descr': {'addr': 4, 'size': 8, 'properties': ['ro']}}
    }

    def __init__(self, intf, conf):
        super(sram_fifo, self).__init__(intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))
        sleep(0.01)  # wait some time for initialization

    def set_almost_full_threshold(self, value):
        self._intf.write(self._conf['base_addr'] + 1, array('B', pack('B', value)))  # no get function possible

    def set_almost_empty_threshold(self, value):
        self._intf.write(self._conf['base_addr'] + 2, array('B', pack('B', value)))  # no get function possible

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

    @property
    def FIFO_INT_SIZE(self):
        '''
        Get FIFO size in units of integers (32 bit).

        Returns
        -------
        fifo_size : int
            FIFO size in units of integers (32 bit).
        '''
        fifo_size = self.FIFO_SIZE
        # sometimes reading of FIFO size happens during writing to SRAM, but we want to have a multiplicity of 32 bits
        return (fifo_size - (fifo_size % 2)) / 2

    def get_fifo_int_size(self):
        '''
        Get FIFO size in units of integers (32 bit).

        Returns
        -------
        fifo_size : int
            FIFO size in units of integers (32 bit).
        '''
        return self.FIFO_INT_SIZE

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
