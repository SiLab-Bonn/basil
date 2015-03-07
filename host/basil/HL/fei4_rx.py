#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class fei4_rx(RegisterHardwareLayer):
    '''FEI4 receiver controller interface for fei4_rx FPGA module
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'RX_RESET': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 2, 'size': 1, 'properties': ['ro']}},
                  'INVERT_RX': {'descr': {'addr': 2, 'size': 1, 'offset': 1}},
                  'FIFO_SIZE': {'default': 0, 'descr': {'addr': 3, 'size': 16, 'properties': ['ro']}},
                  'DECODER_ERROR_COUNTER': {'descr': {'addr': 5, 'size': 8, 'properties': ['ro']}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 6, 'size': 8, 'properties': ['ro']}}}
    _require_version = "==2"

    def __init__(self, intf, conf):
        super(fei4_rx, self).__init__(intf, conf)

    def reset(self):
        self.RESET = 0

    def rx_reset(self):
        self.RX_RESET = 0

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def set_invert_rx(self, value):
        self.INVERT_RX = value

    def get_invert_rx(self):
        return self.INVERT_RX

    def get_fifo_size(self):
        return self.FIFO_SIZE

    def get_decoder_error_counter(self):
        return self.DECODER_ERROR_COUNTER

    def get_lost_data_counter(self):
        return self.LOST_DATA_COUNTER
