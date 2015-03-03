#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class pulse_gen(RegisterHardwareLayer):
    '''Pulser generator
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'EN': {'descr': {'addr': 2, 'size': 1}},
                  'DELAY': {'descr': {'addr': 3, 'size': 16}},
                  'WIDTH': {'descr': {'addr': 5, 'size': 16}},
                  'REPEAT': {'descr': {'addr': 7, 'size': 8}}
                  }
    _require_version = "==1"

    def __init__(self, intf, conf):
        super(pulse_gen, self).__init__(intf, conf)

    def reset(self):
        self.RESET = 0

    def start(self):
        '''
        Software start of pulse at random time
        '''
        self.START = 0

    def set_delay(self, delay):
        '''
        Pulse delay w.r.t. shift register finish signal [in clock cycles(?)]
        '''
        self.DELAY = delay

    def get_delay(self):
        return self.DELAY

    def set_width(self, width):
        '''
        Pulse width in terms of clock cycles
        '''
        self.WIDTH = width

    def get_width(self):
        return self.WIDTH

    def set_repeat(self, repeat):
        '''
        Pulse repetition in range of 0-255
        '''
        self.REPEAT = repeat

    def get_repeat(self):
        return self.REPEAT

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY == 1

    def set_en(self, enable):
        '''
        If true: The pulse comes with a fixed delay with respect to the external trigger (EXT_START).
        If false: The pulse comes only at software start.
        '''
        self.EN = enable

    def get_en(self):
        '''
        Return info if pulse starts with a fixed delay w.r.t. shift register finish signal (true) or if it only starts with .start() (false)
        '''
        return self.EN == 1
