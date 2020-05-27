#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class pulse_gen640(RegisterHardwareLayer):
    '''Pulser generator
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'EN': {'descr': {'addr': 2, 'size': 1}},
                  'DELAY': {'descr': {'addr': 3, 'size': 32}},
                  'WIDTH': {'descr': {'addr': 7, 'size': 32}},
                  'REPEAT': {'descr': {'addr': 11, 'size': 32}},
                  'PHASE_DES': {'descr': {'addr': 15, 'size': 16}},
                  'DEBUG': {'descr': {'addr': 17, 'size': 64}},
                  }
    _require_version = "==1"

    def __init__(self, intf, conf):
        super(pulse_gen640, self).__init__(intf, conf)

    def start(self):
        '''
        Software start of pulse at random time
        '''
        self.START = 0

    def reset(self):
        self.RESET = 0

    def set_delay(self, value):
        '''
        Pulse delay w.r.t. shift register finish signal [in clock cycles(?)]
        '''
        self.DELAY = value

    def get_delay(self):
        return self.DELAY

    def set_phase(self, value):
        '''
        Pulse phase in 640MHz from 0 to 16
        '''
        self.PHASE_DES = (0xFFFF << (value % 16)) & 0xFFFF

    def get_phase(self):
        for i in range(16):
            if ((0xFFFF0000 | self.PHASE_DES) >> i) & 0xFFFF == 0xFFFF:
                break
        return i

    def set_width(self, value):
        '''
        Pulse width in terms of clock cycles
        '''
        self.WIDTH = value

    def get_width(self):
        return self.WIDTH

    def set_repeat(self, value):
        '''
        Pulse repetition in range of 0-255
        '''
        self.REPEAT = value

    def get_repeat(self):
        return self.REPEAT

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def set_en(self, value):
        '''
        If true: The pulse comes with a fixed delay with respect to the external trigger (EXT_START).
        If false: The pulse comes only at software start.
        '''
        self.EN = value

    def get_en(self):
        '''
        Return info if pulse starts with a fixed delay w.r.t. shift register finish signal (true) or if it only starts with .start() (false)
        '''
        return self.EN
