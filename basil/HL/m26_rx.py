#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class m26_rx(RegisterHardwareLayer):
    '''Mimosa 26 RX interface
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'EN': {'descr': {'addr': 2, 'size': 1, 'offset': 0}},
                  'TIMESTAMP_HEADER': {'descr': {'addr': 2, 'size': 1, 'offset': 1}},
                  'LOST_COUNT': {'descr': {'addr': 3, 'size': 8, 'properties': ['ro']}}}
    _require_version = "==1"

    def __init__(self, intf, conf):
        super(m26_rx, self).__init__(intf, conf)

    def reset(self):
        '''Soft reset the module.'''
        self.RESET = 0

    def set_en(self, value):
        self.EN = value

    def get_en(self):
        return self.EN

    def get_lost_count(self):
        return self.LOST_COUNT
