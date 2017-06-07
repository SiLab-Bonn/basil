#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class i2c(RegisterHardwareLayer):
    '''Implement master i2c programming interface driver.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'NO_ACK': {'descr': {'addr': 1, 'size': 1, 'offset': 1, 'properties': ['ro']}},
                  'SIZE': {'descr': {'addr': 3, 'size': 16}},
                  'ADDR': {'descr': {'addr': 2, 'size': 8}},
                  'MEM_BYTES': {'descr': {'addr': 6, 'size': 16}},
                  }

    _require_version = "==1"

    def __init__(self, intf, conf):
        super(i2c, self).__init__(intf, conf)
        self._seq_mem_offset = 8  # in bytes

    def init(self):
        super(i2c, self).init()
        self._mem_size = self.get_mem_size()

    def get_mem_size(self):
        return self.MEM_BYTES

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def set_addr(self, value):
        self.ADDR = value

    def set_address(self, value):
        self.ADDR = value

    def get_addr(self):
        return self.ADDR

    def get_address(self):
        return self.ADDR

    def set_size(self, value):
        self.SIZE = value

    def get_size(self):
        return self.SIZE

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        '''
         :raises ExceptionType: IOError
        Transfer not acknowledged.
        '''
        if(self.NO_ACK):
            raise IOError('i2c:Transfer not acknowledged')
        return self.READY

    def get_done(self):
        return self.is_ready

    def set_data(self, data, addr=0):
        if self._mem_size < len(data):
            raise ValueError('Size of data (%d bytes) is too big for memory (%d bytes)' % (len(data), self._mem_size))
        self._intf.write(self._conf['base_addr'] + self._seq_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if size and self._mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, self._mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, size)

    def write(self, addr, data):
        '''Write access.

        :param addr: i2c slave address
        :type addr: char
        :param data: array/list of bytes
        :type data: iterable
        :rtype: None

        '''
        self.set_addr(addr & 0xfe)
        self.set_data(data)
        self.set_size(len(data))
        self.start()
        while not self.is_ready:
            pass

    def read(self, addr, size):
        '''Read access.

        :param addr: i2c slave address
        :type addr: char
        :param size: size of transfer
        :type size: int
        :returns: data byte array
        :rtype: array.array('B')

        '''
        self.set_addr(addr | 0x01)
        self.set_size(size)
        self.start()
        while not self.is_ready:
            pass
        return self.get_data(size)
