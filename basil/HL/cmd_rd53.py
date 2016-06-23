#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class cmd_rd53(RegisterHardwareLayer):
    '''Implement master RD53 configuration and timing interface driver.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 1, 'offset': 7, 'properties': ['writeonly']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'SYNCING': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'SYNCMODE': {'descr': {'addr': 2, 'size': 1, 'properties': ['rw']}},
                  'SIZE': {'descr': {'addr': 3, 'size': 16}},
                  'MEM_BYTES': {'descr': {'addr': 6, 'size': 16}},
                  }

    _require_version = "==1"

    def __init__(self, intf, conf):
        super(cmd_rd53, self).__init__(intf, conf)
        self._mem_offset = 16 # in bytes

    def init(self):
        super(cmd_rd53, self).init()
        self._mem_size = self.get_mem_size()

    def get_mem_size(self):
        return self.MEM_BYTES

    def get_cmd_size(self):
        return self.SIZE

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def set_size(self, value):
        self.SIZE = value

    def set_syncmode(self, mode):
        self.SYNCMODE = mode

    def get_size(self):
        return self.SIZE

    def is_done(self):
        return self.is_ready

    def is_syncing(self):
        return self.syncing


    @property
    def is_ready(self):
        return self.READY

    def syncing(self):
        return self.SYNCING

    def get_done(self):
        return self.is_ready

    def set_data(self, data, addr=0):
        if self._mem_size < len(data):
            raise ValueError('Size of data (%d bytes) is too big for memory (%d bytes)' % (len(data), self._mem_size))
        self._intf.write(self._conf['base_addr'] + self._mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if size and self._mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._mem_offset + addr, self._mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._mem_offset + addr, size)

