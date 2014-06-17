#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
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


class seq_gen(HardwareLayer):
    '''Sequencer generator controller interface for seq_gen FPGA module.
    '''
    def __init__(self, intf, conf):
        super(seq_gen, self).__init__(intf, conf)
        self._seq_mem_offset = 16  # in bytes
        try:
            self._seq_mem_size = conf['mem_size']  # in bytes
        except KeyError:
            self._seq_mem_size = 2048  # default is 2048 bytes, user should be aware of address ranges in FPGA

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, (0,))

    def set_size(self, value):
        self._intf.write(self._conf['base_addr'] + 3, array('B', pack('H', value)))

    def get_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, size=2)
        return unpack_from('H', ret)[0]

    def set_wait(self, value):
        self._intf.write(self._conf['base_addr'] + 5, array('B', pack('H', value)))

    def get_wait(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, size=2)
        return unpack_from('H', ret)[0]

    def set_clk_divide(self, value):
        self._intf.write(self._conf['base_addr'] + 2, (value,))

    def get_clk_divide(self):
        return self._intf.read(self._conf['base_addr'] + 2, 1)[0]

    def set_repeat_start(self, value):
        self._intf.write(self._conf['base_addr'] + 8, array('B', pack('H', value)))

    def get_repeat_start(self):
        ret = self._intf.read(self._conf['base_addr'] + 8, size=2)
        return unpack_from('H', ret)[0]

    def set_repeat(self, value):
        self._intf.write(self._conf['base_addr'] + 7, (value,))

    def get_repeat(self):
        return self._intf.read(self._conf['base_addr'] + 7, 1)[0] 

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
