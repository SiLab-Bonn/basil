#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class spi(RegisterHardwareLayer):
    '''Implement serial programming interface (SPI) driver.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'SIZE': {'descr': {'addr': 3, 'size': 16}},
                  'WAIT': {'descr': {'addr': 5, 'size': 32}},
                  'REPEAT': {'descr': {'addr': 9, 'size': 32}},
                  'MEM_BYTES': {'descr': {'addr': 13, 'size': 16, 'properties': ['ro']}}}
    _require_version = "==1"

    def __init__(self, intf, conf):
        super(spi, self).__init__(intf, conf)
        self._spi_mem_offset = 16  # in bytes

    def init(self):
        super(spi, self).init()
        self._mem_bytes = self.MEM_BYTES

    def reset(self):
        '''Soft reset the module.'''
        self.RESET = 0

    def start(self):
        '''
        Starts the shifting in of data
        '''
        self.START = 0

    def set_size(self, value):
        '''
        Overwrites the size defined in YAML config file
        Number of clock cycles for shifting in data
        length of matrix shift register (number of pixels daisy chained)
        '''
        self.SIZE = value

    def get_size(self):
        '''
        Get size of shift register length
        '''
        return self.SIZE

    def set_wait(self, value):
        '''
        Defines time delay between repetitions in clock cycles (80ns)
        '''
        self.WAIT = value

    def get_wait(self):
        '''
        Gets time delay between repetitions in clock cycles (80ns)
        '''
        return self.WAIT

    def set_repeat(self, value):
        '''
        If 0: Repeat sequence forever
        Other: Number of repetitions of sequence with delay 'wait'
        '''
        self.REPEAT = value

    def get_repeat(self):
        '''
        Gets Number of repetitions of sequence with delay 'wait' (if 0 --> repeat forever)
        '''
        return self.REPEAT

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def get_mem_size(self):
        return self.MEM_BYTES

    def set_data(self, data, addr=0):
        '''
        Sets data for outgoing stream
        '''
        if self._mem_bytes < len(data):
            raise ValueError('Size of data is too big')
        self._intf.write(self._conf['base_addr'] + self._spi_mem_offset + addr, data)

    # This needs to be changed to return written value
    def get_data(self, size=None, addr=None):
        '''
        Gets data for incoming stream
        '''
        # readback memory offset
        if addr is None:
            addr = self._mem_bytes

        if size and self._mem_bytes < size:
            raise ValueError('Size is too big')

        if size is None:
            return self._intf.read(self._conf['base_addr'] + self._spi_mem_offset + addr, self._mem_bytes)
        else:
            return self._intf.read(self._conf['base_addr'] + self._spi_mem_offset + addr, size)
