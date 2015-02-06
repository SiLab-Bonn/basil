#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from struct import unpack_from


class fei4_rx(RegisterHardwareLayer):
    '''FEI4 receiver controller interface for fei4_rx FPGA module
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 2, 'size': 1, 'properties': ['ro']}},
                  'INVERT_RX': {'descr': {'addr': 2, 'size': 1, 'offset': 1}},
                  'FIFO_SIZE': {'default': 0, 'descr': {'addr': 3, 'size': 16, 'properties': ['ro']}},
                  'DECODER_ERROR_COUNTER': {'descr': {'addr': 5, 'size': 8, 'properties': ['ro']}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 6, 'size': 8, 'properties': ['ro']}}}
    _require_version = "==1"

    def __init__(self, intf, conf):
        super(fei4_rx, self).__init__(intf, conf)

#    def init(self):
#        self.reset()

    def reset(self):
        self.soft_reset()
        self.fifo_reset()

    def soft_reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

    def fifo_reset(self):
        self._intf.write(self._conf['base_addr'] + 1, (0,))

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return (self._intf.read(self._conf['base_addr'] + 2, size=1)[0] & 0x01) == 1

    def set_invert_rx(self, value):
        reg = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = ((value & 0x01) << 1) | (reg & 0xfd)
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def get_invert_rx(self):
        return True if (self._intf.read(self._conf['base_addr'] + 2, size=1)[0] & 0x02) else False

    def get_fifo_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, size=2)
        return unpack_from('H', ret)[0]

    def get_decoder_error_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, size=1)
        return unpack_from('B', ret)[0]

    def get_lost_data_counter(self):
        ret = self._intf.read(self._conf['base_addr'] + 6, size=1)
        return unpack_from('B', ret)[0]
