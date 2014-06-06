#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from basil.HL.HardwareLayer import HardwareLayer
from struct import pack, unpack


class pulse_gen(HardwareLayer):
    '''Pulser generator
    '''
    def __init__(self, intf, conf):
        super(pulse_gen, self).__init__(intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        '''
        Software start of pulse at random time
        '''
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_delay(self, delay):
        '''
        Pulse delay w.r.t. shift register finish signal [in clock cycles(?)]
        '''
        self._intf.write(self._conf['base_addr'] + 3, unpack('BB', pack('>H', delay)))

    def get_delay(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 2)
        return ret[0] * 256 + ret[1]

    def set_width(self, width):
        '''
        Pulse width in terms of clock cycles
        '''
        self._intf.write(self._conf['base_addr'] + 5, unpack('BB', pack('>H', width)))

    def get_width(self):
        ret = self._intf.read(self._conf['base_addr'] + 5, 2)
        return ret[0] * 256 + ret[1]

    def set_repeat(self, repeat):
        '''
        Pulse repetition in range of 0-255
        '''
        self._intf.write(self._conf['base_addr'] + 7, [repeat])

    def get_repeat(self):
        ret = self._intf.read(self._conf['base_addr'] + 7, 1)
        return ret[0]

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 1)[0] & 0x01) else False

    def set_en(self, enable):
        '''
        If true: The pulse comes with a fixed delay with respect to the external trigger (EXT_START).
        If false: The pulse comes only at software start.
        '''
        current = self._intf.read(self._conf['base_addr'] + 2, 1)[0]
        self._intf.write(self._conf['base_addr'] + 2, [(current & 0xfe) | enable])

    def get_en(self):
        '''
        Return info if pulse starts with a fixed delay w.r.t. shift register finish signal (true) or if it only starts with .start() (false)
        '''
        return True if (self._intf.read(self._conf['base_addr'] + 2, 1)[0] & 0x01) else False
