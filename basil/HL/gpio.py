#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class gpio(RegisterHardwareLayer):
    '''GPIO interface
    '''

    def __init__(self, intf, conf):

        self._registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                           'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}}}
        self._require_version = "==0"

        self._size = 8
        if 'size' in conf.keys():
            self._size = conf['size']

        io_bytes = ((self._size - 1) / 8) + 1

        self._registers['INPUT'] = {'descr': {'addr': 1, 'size': io_bytes, 'properties': ['ro', 'byte_array']}}
        self._registers['OUTPUT'] = {'descr': {'addr': 2 + io_bytes - 1, 'size': io_bytes, 'properties': ['byte_array']}}
        self._registers['OUTPUT_EN'] = {'descr': {'addr': 3 + 2 * (io_bytes - 1), 'size': io_bytes, 'properties': ['byte_array']}}
        # __init__() after updating register
        super(gpio, self).__init__(intf, conf)

    def init(self):
        super(gpio, self).init()
        if 'output_en' in self._init:
            self.OUTPUT_EN = self._init['output_en']

    def reset(self):
        '''Soft reset the module.'''
        self.RESET = 0

    def set_output_en(self, value):
        self.OUTPUT_EN = value

    def get_output_en(self):
        return self.OUTPUT_EN

    def set_data(self, value):
        self.OUTPUT = value

    def get_data(self):
        return self.INPUT
