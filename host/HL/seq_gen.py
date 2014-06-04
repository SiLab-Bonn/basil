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


class seq_gen(HardwareLayer):
    '''Sequencer generator controller interface for seq_gen FPGA module.
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)
        self._seq_mem_offset = 8  # in bytes
        try:
            self._seq_mem_size = conf['mem_size'] - self._seq_mem_offset  # in bytes
        except KeyError:
            self._seq_mem_size = 2048 - self._seq_mem_offset  # default is 2048 bytes

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, (0,))

    def set_size(self, value):
        self._intf.write(self._conf['base_addr'] + 3, array.array('B', pack('H', value)))

    def get_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, size=2)
        return unpack_from('H', ret)[0]

    def set_wait(self, value):
        self._intf.write(self._conf['base_addr'] + 5, array.array('B', pack('H', value)))

    def get_wait(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, size=2)
        return unpack_from('H', ret)[0]

    def set_clk_divide(self, value):
        self._intf.write(self._conf['base_addr'] + 2, (value,))

    def get_clk_divide(self):
        return self._intf.read(self._conf['base_addr'] + 2, 1)[0]

    def set_repeat_start(self, value):
        self._intf.write(self._conf['base_addr'] + 8, array.array('B', pack('H', value)))

    def get_repeat_start(self):
        ret = self._intf.read(self._conf['base_addr'] + 8, size=2)
        return unpack_from('H', ret)[0]

    @property
    def is_ready(self):
        return (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x01) == 1

    def set_data(self, data, addr=0):
        if self._seq_mem_size < len(data):
            raise ValueError('Size of data is too big')
        self._intf.write(self._conf['base_addr'] + self._seq_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if size and self._seq_mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, self._seq_mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._seq_mem_offset + addr, size)
