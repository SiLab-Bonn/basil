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

    def set_position(self, x, y):
        ''' Move chuck to absolute position in um'''
        self._intf.write('34 %1.1f %1.1f', (x, y))

    def get_position(self):
        ''' Read chuck position (x, y, z)'''
        return self._intf.write('31')

    def goto_die(self, index_x, index_y):
        ''' Move chuck to wafer map chip index'''
        self._intf.write('35 %d %d', (index_x, index_y))

    def get_die(self, index_x, index_y):
        ''' Move chuck to wafer map chip index'''
        self._intf.write('43')

    def contact(self):
        ''' Move chuck to contact z position'''
        self._intf.write('37')

    def separate(self):
        ''' Move chuck to separation z position'''
        self._intf.write('39')
