#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class timestamp_div(RegisterHardwareLayer):
    '''Implement timestamp driver.
    '''

    def __init__(self, intf, conf):
        self._registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                           'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                           'ENABLE': {'descr': {'addr': 2, 'size': 1, 'offset': 0}},
                           'EXT_TIMESTAMP': {'descr': {'addr': 2, 'size': 1, 'offset': 1}},
                           'ENABLE_EXTERN': {'descr': {'addr': 2, 'size': 1, 'offset': 2}},
                           'ENABLE_TOT': {'descr': {'addr': 2, 'size': 1, 'offset': 3}},
                           'LOST_COUNT': {'descr': {'addr': 3, 'size': 8}},
                           }
        self._require_version = "==1"

        super(timestamp_div, self).__init__(intf, conf)

    def init(self):
        super(timestamp_div, self).init()

    def reset(self):
        '''Soft reset the module.'''
        self.RESET = 0
