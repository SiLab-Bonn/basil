#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer


class SussProber(HardwareLayer):

    '''Implements functions to steer a Suss probe station. The interface is the same for all SiLab Suss probe stations.
        Dangerous commands like set_position while in contact are ignored by the Suss command server.
    '''

    def __init__(self, intf, conf):
        super(SussProber, self).__init__(intf, conf)

    def set_position(self, x, y, speed=None):
        ''' Move chuck to absolute position in um'''
        if speed:
            self._intf.write('MoveChuckSubsite %1.1f %1.1f R Y %d' % (x, y, speed))
        else:
            self._intf.write('MoveChuckSubsite %1.1f %1.1f R Y' % (x, y))

    def move_position(self, dx, dy, speed=None):
        ''' Move chuck relative to actual position in um'''
        if speed:
            self._intf.write('MoveChuckPosition %1.1f %1.1f R Y %d' % (dx, dy, speed))
        else:
            self._intf.write('MoveChuckPosition %1.1f %1.1f R Y' % (dx, dy))

    def get_position(self):
        ''' Read chuck position (x, y, z)'''
        reply = self._intf.query('ReadChuckPosition Y H')[2:]
        return [float(i) for i in reply.split()]

    def goto_die(self, index_x, index_y):
        ''' Move chuck to wafer map chip index'''
        self._intf.write('StepNextDie %d %d' % (index_x, index_y))

    def goto_next_die(self):
        ''' Move chuck to next die from wafer map'''
        self._intf.write('StepNextDie')

    def goto_first_die(self):
        ''' Move chuck to first die from wafer map'''
        self._intf.write('StepFirstDie')

    def get_die(self):
        ''' Get chip index '''
        reply = self._intf.query('ReadMapPosition').strip()
        if reply == '0:' or reply == '':
            reply = self._intf.query('ReadMapPosition')

        values = reply[2:].split(' ')
        return (int(values[0]), int(values[1]))

    def contact(self):
        ''' Move chuck to contact z position'''
        self._intf.write('MoveChuckContact')

    def separate(self):
        ''' Move chuck to separation z position'''
        self._intf.write('MoveChuckSeparation')

    def load(self):
        ''' Move chuck to load z position'''
        self._intf.write('MoveChuckLoad')
