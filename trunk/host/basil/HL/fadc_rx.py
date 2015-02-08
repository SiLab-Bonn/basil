#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from struct import pack, unpack


class fadc_rx(RegisterHardwareLayer):
    '''Fast ADC channel receiver
    '''
    
    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'ALIGN_TO_SYNC': {'descr': {'addr': 2, 'size': 1}},
                  'SINGLE_DATA': {'descr': {'addr': 2, 'size': 1, 'offset': 2}},
                  'COUNT': {'descr':{'addr': 3, 'size': 24}},
                  }
    _require_version = "==1"
    
    def __init__(self, intf, conf):
        super(fadc_rx, self).__init__(intf, conf)

    #def init(self):
    #    self.reset()

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def set_align_to_sync(self, value=False):
        '''
        Align data taking to a synchronization signal, reset signal is the synchronization signal (hard coded connection in Verilog source code)
        '''
        self.ALIGN_TO_SYNC = value

    def set_single_data(self, value=False):
        '''
        '''
        self.SINGLE_DATA = value

    def get_align_to_sync(self):
        return self.ALIGN_TO_SYNC

    def set_data_count(self, count):
        self.COUNT = count

    def get_data_count(self):
        return self.COUNT

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY == 1

    def get_done(self):
        return self.is_ready
