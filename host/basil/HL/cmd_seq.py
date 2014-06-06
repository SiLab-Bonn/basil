#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 185                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-05-27 13:57:23 #$:
#

from HL.HardwareLayer import HardwareLayer
from struct import pack, unpack, unpack_from
from array import array


output_modes = {
    0: 'positive edge (default)',
    1: 'negative edge',
    2: 'Manchester Code IEEE 802.3 (for capacitively coupled transmission)',
    3: 'Manchester Code G.E. Thomas'
}


class cmd_seq(HardwareLayer):
    '''FEI4 Command Sequencer Controller Interface for cmd_seq FPGA module.
    '''
    def __init__(self, intf, conf):
        super(cmd_seq, self).__init__(intf, conf)
        self._cmd_mem_offset = 16  # in bytes
        try:
            self._cmd_mem_size = conf['mem_size'] - self._cmd_mem_offset  # in bytes
        except KeyError:
            self._cmd_mem_size = 2048 - self._cmd_mem_offset  # default is 2048 bytes

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, (0,))

    @property
    def is_ready(self):
        return (self._intf.read(self._conf['base_addr'] + 1, size=1)[0] & 0x01) == 1

    def set_ext_trigger(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x01
        else:
            reg &= ~0x01
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_output_mode(self, value):
        if value not in output_modes.iterkeys():
            raise ValueError('Output mode does not exist')
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        reg = ((value & 0x03) << 1) | (reg & 0xf9)
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_clock_gate(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        if not value:
            reg |= 0x08
        else:
            reg &= ~0x08
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_cmd_pulse(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x10
        else:
            reg &= ~0x10
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def get_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, size=2)
        return unpack_from('H', ret)[0]

    def set_size(self, value):
        self._intf.write(self._conf['base_addr'] + 3, array.array('B', pack('H', value)))  # alternatively: unpack('BB', pack('H', value))

    def get_repeat(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, size=4)
        return unpack_from('L', ret)[0]

    def set_repeat(self, value):
        self._intf.write(self._conf['base_addr'] + 5, array.array('B', pack('L', value)))

    def get_start_seq_length(self):
        ret = self._intf.read(self._conf['base_addr'] + 9, size=2)
        return unpack_from('H', ret)[0]

    def set_start_seq_length(self, value):
        if value < 2:
            raise ValueError('Length is too short')  # bug in FPGA module
        self._intf.write(self._conf['base_addr'] + 9, array.array('B', pack('H', value)))

    def get_stop_seq_length(self):
        ret = self._intf.read(self._conf['base_addr'] + 11, size=2)
        return unpack_from('H', ret)[0]

    def set_stop_seq_length(self, value):
        if value < 2:
            raise ValueError('Length is too short')  # bug in FPGA module
        self._intf.write(self._conf['base_addr'] + 1, array.array('B', pack('H', value)))

    def set_data(self, data, addr=0):
        if self._cmd_mem_size < len(data):
            raise ValueError('Size of data is too big')
        self._intf.write(self._conf['base_addr'] + self._cmd_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if self._cmd_mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._cmd_mem_offset + addr, self._cmd_mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._cmd_mem_offset + addr, size)
