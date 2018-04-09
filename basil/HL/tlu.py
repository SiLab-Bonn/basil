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


trigger_data_format = {
    'TRIGGER_COUNTER': 0,  # trigger number according to TRIGGER_MODE
    'TIMESTAMP': 1,  # time stamp only
    'COMBINED': 2,  # combined, 15bit time stamp + 16bit trigger number
}


class tlu(RegisterHardwareLayer):
    '''TLU controller interface
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'TRIGGER_MODE': {'descr': {'addr': 1, 'size': 2, 'offset': 0}},
                  'TRIGGER_DATA_MSB_FIRST': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},
                  'TRIGGER_ENABLE': {'descr': {'addr': 1, 'size': 1, 'offset': 3}},
                  'DATA_FORMAT': {'descr': {'addr': 2, 'size': 2, 'offset': 0}},
                  'EN_TLU_RESET_TIMESTAMP': {'descr': {'addr': 2, 'size': 1, 'offset': 5}},
                  'EN_TLU_VETO': {'descr': {'addr': 2, 'size': 1, 'offset': 6}},
                  'TRIGGER_LOW_TIMEOUT': {'descr': {'addr': 3, 'size': 8}},
                  'CURRENT_TLU_TRIGGER_NUMBER': {'descr': {'addr': 4, 'size': 32, 'properties': ['ro']}},
                  'TRIGGER_COUNTER': {'descr': {'addr': 8, 'size': 32}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 12, 'size': 8, 'properties': ['ro']}},
                  'TRIGGER_SELECT': {'descr': {'addr': 13, 'size': 32}},
                  'TRIGGER_VETO_SELECT': {'descr': {'addr': 17, 'size': 32}},
                  'TRIGGER_INVERT': {'descr': {'addr': 21, 'size': 32}},
                  'MAX_TRIGGERS': {'descr': {'addr': 25, 'size': 32}},
                  'TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES': {'descr': {'addr': 29, 'size': 8}},
                  'HANDSHAKE_BUSY_VETO_WAIT_CYCLES': {'descr': {'addr': 30, 'size': 8}},
                  'TRIGGER_LOW_TIMEOUT_ERROR_COUNTER': {'descr': {'addr': 31, 'size': 8, 'properties': ['ro']}},
                  'TLU_TRIGGER_ACCEPT_ERROR_COUNTER': {'descr': {'addr': 32, 'size': 8, 'properties': ['ro']}},
                  'TRIGGER_THRESHOLD': {'descr': {'addr': 33, 'size': 8}},
                  'SOFT_TRIGGER': {'descr': {'addr': 34, 'size': 8, 'properties': ['writeonly']}},
                  'TRIGGER_DATA_DELAY': {'descr': {'addr': 35, 'size': 8}}}
    _require_version = "==11"

    def __init__(self, intf, conf):
        super(tlu, self).__init__(intf, conf)

    def reset(self):
        self.RESET = 0
