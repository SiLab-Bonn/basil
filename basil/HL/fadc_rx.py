#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class fadc_rx(RegisterHardwareLayer):

    '''Fast ADC channel receiver
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'ALIGN_TO_SYNC': {'descr': {'addr': 2, 'size': 1}},
                  'EN_TRIGGER': {'descr': {'addr': 2, 'size': 1, 'offset': 1}},
                  'SINGLE_DATA': {'descr': {'addr': 2, 'size': 1, 'offset': 2}},
                  'SAMPLE_DLY': {'descr': {'addr': 7, 'size': 8}},
                  'COUNT': {'descr': {'addr': 3, 'size': 24}},
                  'COUNT_LOST': {'descr': {'addr': 8, 'size': 8, 'properties': ['ro']}}}

    _require_version = "==1"

    def __init__(self, intf, conf):
        super(fadc_rx, self).__init__(intf, conf)

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def set_align_to_sync(self, value):
        '''
        Align data taking to a synchronization signal, reset signal is the synchronization signal (hard coded connection in Verilog source code)
        '''
        self.ALIGN_TO_SYNC = value

    def set_single_data(self, value):
        '''
        '''
        self.SINGLE_DATA = value

    def get_align_to_sync(self):
        return self.ALIGN_TO_SYNC

    def set_data_count(self, count):
        self.COUNT = count

    def get_data_count(self):
        return self.COUNT

    def set_en_trigger(self, val):
        self.EN_TRIGGER = val

    def get_en_trigger(self):
        return self.EN_TRIGGER

    def set_delay(self, val):
        self.SAMPLE_DLY = val

    def get_delay(self):
        return self.SAMPLE_DLY

    def get_count_lost(self):
        return self.COUNT_LOST

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def get_done(self):
        return self.is_ready
