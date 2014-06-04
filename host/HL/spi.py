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
from struct import pack, unpack, unpack_from
from array import array


class spi(HardwareLayer):
    '''Serial programming interface.
    Together with a GPIO module it is used to configure the local registers of the pixel matrix
    Assigns bits like in the following example:
    >>> dut[ <name of SR as defined in YAML config file> ][bit position] = value
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)
        self._spi_mem_offset = 8  # in bytes
        try:
            self._spi_mem_size = conf['mem_size'] - self._spi_mem_offset  # in bytes
        except KeyError:
            self._spi_mem_size = 2048 - self._spi_mem_offset  # default is 2048 bytes

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def init(self):
        self.reset()

    def start(self):
        '''
        Starts the shifting in of data
        '''
        self._intf.write(self._conf['base_addr'] + 1, (0,))

    def set_size(self, value):
        '''
        Overwrites the size defined in YAML config file
        Number of clock cycles for shifting in data
        length of matrix shift register (number of pixels daisy chained)
        '''
        self._intf.write(self._conf['base_addr'] + 3, array.array('B', pack('H', value)))

    def get_size(self):
        '''
        Get size of shift register length
        '''
        ret = self._intf.read(self._conf['base_addr'] + 3, size=2)
        return unpack_from('H', ret)[0]

    def set_wait(self, value):
        '''
        Defines time delay between repetitions in clock cycles (80ns)
        '''
        self._intf.write(self._conf['base_addr'] + 5, array.array('B', pack('H', value)))

    def get_wait(self):
        '''
        Gets time delay between repetitions in clock cycles (80ns)
        '''
        ret = self._intf.read(self._conf['base_addr'] + 5, size=2)
        return unpack_from('L', ret)[0]

    def set_repeat(self, value):
        '''
        If 0: Repeat sequence forever
        Other: Number of repetitions of sequence with delay 'wait'
        '''
        self._intf.write(self._conf['base_addr'] + 7, (value,))

    def get_repeat(self):
        '''
        Gets Number of repetitions of sequence with delay 'wait' (if 0 --> repeat forever)
        '''
        return self._intf.read(self._conf['base_addr'] + 7, 1)[0]

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 1)[0] & 0x01) else False

    @property
    def is_ready(self):
        return (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x01) == 1

    def set_data(self, data, addr=0):
        if self._spi_mem_size < len(data):
            raise ValueError('Size of data is too big')
        self._intf.write(self._conf['base_addr'] + self._spi_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if size and self._spi_mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._spi_mem_offset + addr, self._spi_mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._spi_mem_offset + addr, size)
