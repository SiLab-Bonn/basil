#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


trigger_modes = {
    'EXTERNAL': 0,  # external trigger
    'NO_HANDSHAKE': 1,  # TLU no handshake
    'SIMPLE_HANDSHALKE': 2,  # TLU simple handshake
    'DATA_HANDSHAKE': 3  # TLU trigger data handshake
}


class tlu(RegisterHardwareLayer):
    '''TLU controller interface
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'TRIGGER_MODE': {'descr': {'addr': 1, 'size': 2, 'offset': 0}},
                  'TRIGGER_DATA_MSB_FIRST': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},
                  'TRIGGER_DATA_DELAY': {'descr': {'addr': 1, 'size': 4, 'offset': 4}},
                  'TRIGGER_CLOCK_CYCLES': {'descr': {'addr': 2, 'size': 5, 'offset': 0}},
                  'EN_TLU_RESET_TIMESTAMP': {'descr': {'addr': 2, 'size': 1, 'offset': 5}},
                  'EN_TLU_VETO': {'descr': {'addr': 2, 'size': 1, 'offset': 6}},
                  'EN_WRITE_TIMESTAMP': {'descr': {'addr': 2, 'size': 1, 'offset': 7}},
                  'TRIGGER_LOW_TIMEOUT': {'descr': {'addr': 3, 'size': 8}},
                  'CURRENT_TLU_TRIGGER_NUMBER': {'descr': {'addr': 4, 'size': 32, 'properties': ['ro']}},
                  'TRIGGER_COUNTER': {'descr': {'addr': 8, 'size': 32}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 12, 'size': 8, 'properties': ['ro']}},
                  'TRIGGER_SELECT': {'descr': {'addr': 13, 'size': 8}},
                  'TRIGGER_VETO_SELECT': {'descr': {'addr': 14, 'size': 8}},
                  'TRIGGER_INVERT': {'descr': {'addr': 15, 'size': 8}},
                  'MAX_TRIGGERS': {'descr': {'addr': 16, 'size': 32}}}
    _require_version = "==4"

    def __init__(self, intf, conf):
        super(tlu, self).__init__(intf, conf)

    def reset(self):
        self.RESET = 0

    def get_lost_data_counter(self):
        return self.LOST_DATA_COUNTER

    def set_trigger_mode(self, value):
        self.TRIGGER_MODE = value

    def set_trigger_msb_first(self, value):
        self.TRIGGER_DATA_MSB_FIRST = value

    def set_trigger_data_delay(self, value):
        self.TRIGGER_DATA_DELAY = value

    def set_trigger_clock_cycles(self, value):
        self.TRIGGER_CLOCK_CYCLES = value

    def set_tlu_reset(self, value):
        self.EN_TLU_RESET = value

    def set_write_timestamp(self, value):
        self.EN_WRITE_TIMESTAMP = value

    def set_trigger_low_timeout(self, value):
        self.TRIGGER_LOW_TIMEOUT = value

    def get_current_tlu_trigger_number(self):
        '''Reading current trigger number.
        '''
        return self.CURRENT_TLU_TRIGGER_NUMBER

    def set_trigger_counter(self, value):
        self.TRIGGER_COUNTER = value

    def get_trigger_counter(self):
        '''Reading trigger counter.
        '''
        return self.TRIGGER_COUNTER
