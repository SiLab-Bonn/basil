#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class tdl_tdc(RegisterHardwareLayer):
    '''TDC controller interface
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 7, 'offset': 1, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'ENABLE': {'descr': {'addr': 1, 'size': 1, 'offset': 0}},
                  'ENABLE_EXTERN': {'descr': {'addr': 1, 'size': 1, 'offset': 1}},
                  'EN_ARMING': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},
                  'EN_WRITE_TIMESTAMP': {'descr': {'addr': 1, 'size': 1, 'offset': 3}},
                  'EN_TRIGGER_DIST': {'descr': {'addr': 1, 'size': 1, 'offset': 4}},
                  'EN_NO_WRITE_TRIG_ERR': {'descr': {'addr': 1, 'size': 1, 'offset': 5}},
                  'EN_INVERT_TDC': {'descr': {'addr': 1, 'size': 1, 'offset': 6}},
                  'EN_INVERT_TRIGGER': {'descr': {'addr': 1, 'size': 1, 'offset': 7}},
                  'EVENT_COUNTER': {'descr': {'addr': 2, 'size': 32, 'properties': ['ro']}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 6, 'size': 8, 'properties': ['ro']}},
                  'TDL_MISS_COUNTER' : {'descr' : {'addr': 7, 'size': 8, 'porperties' :['ro']}},
                  'EN_CALIBRATION_MOD': {'descr': {'addr': 8, 'size': 1, 'offset': 0}}}

    _require_version = "==0"

    def __init__(self, intf, conf):
        super(tdl_tdc, self).__init__(intf, conf)

    def reset(self):
        self.RESET = 0

    def get_lost_data_counter(self):
        return self.LOST_DATA_COUNTER

    def missed_data_counter(self):
        return self.TDL_MISS_COUNTER

    def set_en(self, value):
        self.ENABLE = value

    def get_en(self):
        return self.ENABLE

    def set_en_extern(self, value):
        self.ENABLE_EXTERN = value

    def get_en_extern(self):
        return self.ENABLE_EXTERN

    def set_arming(self, value):
        self.EN_ARMING = value

    def get_arming(self):
        return self.EN_ARMING

    def set_write_timestamp(self, value):
        self.EN_WRITE_TIMESTAMP = value

    def get_write_timestamp(self):
        return self.EN_WRITE_TIMESTAMP

    def get_event_counter(self):
        return self.EVENT_COUNTER

