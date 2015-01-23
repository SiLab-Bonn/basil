#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer

class fast_spi_rx(RegisterHardwareLayer):
    '''Fast SPI interface
    '''
    
    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'EN': {'descr': {'addr': 2, 'size': 1, 'offset': 0}},
                  'LOST_COUNT': {'descr': {'addr': 3, 'size': 8, 'properties': ['ro']}},
    }
    
    def __init__(self, intf, conf):
        super(fast_spi_rx, self).__init__(intf, conf)

    def init(self):
        pass

    def reset(self):
        '''Soft reset the module.'''
        self.RESET = 0

    def set_en(self, value=True):
        self.EN = value

    def get_en(self):
        return True if self.EN else False

    def get_lost_count(self):
        return self.LOST_COUNT
