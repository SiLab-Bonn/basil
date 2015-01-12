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

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}}
    }

    def __init__(self, intf, conf):

        io_width = 8
        if 'size' in conf.keys():
            io_width = conf['size']

        io_bytes = ((io_width - 1) / 8) + 1

        self._registers['INPUT'] = {'descr': {'addr': 1, 'size': io_bytes, 'properties': ['ro', 'byte_array']}}
        self._registers['OUTPUT'] = {'descr': {'addr': 2 + io_bytes - 1, 'size': io_bytes, 'properties': ['byte_array']}}
        self._registers['OUTPUT_EN'] = {'descr': {'addr': 3 + 2 * (io_bytes - 1), 'size': io_bytes, 'properties': ['byte_array']}}

        super(gpio, self).__init__(intf, conf)

    def init(self):
        if 'output_en' in self._init:
            self.OUTPUT_EN = self._init['output_en']

    def reset(self):
        '''Soft reset the module.'''
        self.RESET = 0

    def set_output_en(self, data):
        self.OUTPUT_EN = data

    def get_output_en(self):
        return self.OUTPUT_EN

    def set_data(self, data, **kwargs):
        self.OUTPUT = data

    def get_data(self, **kwargs):
        return self.INPUT
