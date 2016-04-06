#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer


class Arduino(HardwareLayer):

    '''Implement functions to steer the Arduino digital IO using the BASIL Arduino firmware.
    '''

    def __init__(self, intf, conf):
        super(Arduino, self).__init__(intf, conf)

    def set_output(self, channel, value):
        if value == 'ON':
            value = 1
        elif value == 'OFF':
            value = 0

        if value != 0 and value != 1:
            raise ValueError('The value for the output has to be ON, OFF, 0 or 1')

        if channel < 1 or channel > 14:
            raise ValueError('Arduino support only 14 IOs. %d is out of range', channel)

        self._intf.write('GPIO%d %d' % channel, value)
