#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class seq_rec(RegisterHardwareLayer):
    '''Sequencer receiver controller interface for seq_rec FPGA module.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'EN_EXT_START': {'descr': {'addr': 2, 'size': 8}},
                  'SIZE': {'descr': {'addr': 3, 'size': 16}}}
    _require_version = "==0"

    def __init__(self, intf, conf):
        super(seq_rec, self).__init__(intf, conf)
        self._seq_mem_offset = 16  # in bytes
        try:
            self._seq_mem_size = conf['mem_size']  # in bytes
        except KeyError:
            self._seq_mem_size = 2048  # default is 2048 bytes, user should be aware of address ranges in FPGA

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def set_size(self, value):
        self.SIZE = value

    def get_size(self):
        return self.SIZE

    def set_count(self, value):
        self.SIZE = value

    def set_en_ext_start(self, value):
        self.EN_EXT_START = value

    def get_en_ext_start(self):
        return self.EN_EXT_START

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def get_done(self):
        return self.is_ready

    def get_data(self, size=None, addr=0):
        if size and self._seq_mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, self._seq_mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, size)
