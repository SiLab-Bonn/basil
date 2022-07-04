#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.arduino_base import ArduinoBase


class RelayBoard(ArduinoBase):
    '''
    Implement functions to control the Arduino digital IO using the Basil Arduino firmware.
    '''

    CMDS = {
        'read': 'R',
        'write': 'W',
        'delay': 'D'
    }

    ERRORS = {
        'error': "Serial transmission error"  # Custom return code for unsuccesful serial communciation
    }

    def __init__(self, intf, conf):
        super(RelayBoard, self).__init__(intf, conf)

    def set_output(self, channel, value):
        if value == 'ON':
            value = 1
        elif value == 'OFF':
            value = 0

        if value != 0 and value != 1:
            raise ValueError('The value for the output has to be ON, OFF, 0 or 1')

        if channel == 'ALL':
            channel = 99  # All channels are internally channel 99

        if channel < 2 or (channel > 13 and channel != 99):
            raise ValueError('Arduino supports only 14 IOs and pins 0 and 1 are blocked by Serial communication. %d is out of range.' % channel)

        ret = self.query(self.create_command(self.CMDS['write'], channel, value))

        error = False
        if channel == 99 and int(ret) != value * 1111111111:
            error = True
        elif channel != 99 and ret[channel - 2] != str(value):
            error = True

        if error:
            raise RuntimeError('Got no or wrong response from Arduino!')

    def get_state(self):
        return self.query(self.create_command(self.CMDS['read']))
