#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class seq_gen(RegisterHardwareLayer):
    '''Sequencer generator controller interface for seq_gen FPGA module.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'EN_EXT_START': {'descr': {'addr': 2, 'size': 1}},
                  'CLK_DIV': {'descr': {'addr': 3, 'size': 8}},
                  'SIZE': {'descr': {'addr': 4, 'size': 16}},
                  'WAIT': {'descr': {'addr': 6, 'size': 16}},
                  'REPEAT': {'descr': {'addr': 8, 'size': 16}},
                  'REPEAT_START': {'descr': {'addr': 10, 'size': 16}},
                  'NESTED_START': {'descr': {'addr': 12, 'size': 16}},
                  'NESTED_STOP': {'descr': {'addr': 14, 'size': 16}},
                  'NESTED_REPEAT': {'descr': {'addr': 16, 'size': 16}},
                  'MEM_BYTES': {'descr': {'addr': 18, 'size': 16, 'properties': ['ro']}},
                  }
    _require_version = "==2"

    def __init__(self, intf, conf):
        super(seq_gen, self).__init__(intf, conf)
        self._seq_mem_offset = 32  # in bytes

    def init(self):
        super(seq_gen, self).init()
        self._seq_mem_size = self.get_mem_size()

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def set_size(self, value):
        self.SIZE = value

    def get_size(self):
        return self.SIZE

    def set_wait(self, value):
        self.WAIT = value

    def get_wait(self):
        return self.WAIT

    def set_clk_divide(self, value):
        self.CLK_DIV = value

    def get_clk_divide(self):
        return self.CLK_DIV

    def set_repeat_start(self, value):
        self.REPEAT_START = value

    def get_repeat_start(self):
        return self.REPEAT_START

    def set_repeat(self, value):
        self.REPEAT = value

    def get_repeat(self):
        return self.REPEAT

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def get_done(self):
        return self.is_ready

    def set_en_ext_start(self, value):
        self.EN_EXT_START = value

    def get_en_ext_start(self):
        return self.EN_EXT_START

    def set_nested_start(self, value):
        self.NESTED_START = value

    def get_nested_start(self):
        return self.NESTED_START

    def set_nested_stop(self, value):
        self.NESTED_STOP = value

    def get_nested_stop(self):
        return self.NESTED_STOP

    def set_nested_repeat(self, value):
        self.NESTED_REPEAT = value

    def get_nested_repeat(self):
        return self.NESTED_REPEAT

    def get_mem_size(self):
        return self.MEM_BYTES

    def set_data(self, data, addr=0):
        if self._seq_mem_size < len(data):
            raise ValueError('Size of data (%d bytes) is too big for memory (%d bytes)' % (len(data), self._seq_mem_size))
        self._intf.write(self._conf['base_addr'] + self._seq_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if size and self._seq_mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, self._seq_mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, size)
