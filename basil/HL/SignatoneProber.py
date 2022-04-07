#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import re
from basil.HL.RegisterHardwareLayer import HardwareLayer


class SignatoneProber(HardwareLayer):
    '''
    Implements functions to steer a Signatone probe station such as the one of lal in2p3 in Paris.
    '''

    def __init__(self, intf, conf):
        super(SignatoneProber, self).__init__(intf, conf)

    def goto_die(self, index_x, index_y):
        ''' Move chuck to wafer map chip index'''
        index_x = abs(index_x) * -1
        index_y = abs(index_y) * -1

        reply = self._intf.query('MOVECR %d, %d' % (index_x, index_y))
        print("Reponse : ", reply)


    def goto_next_die(self):
        ''' Move chuck to next die from wafer map'''
        self._intf.query('NEXT')

    def goto_first_die(self):
        ''' Move chuck to first die from wafer map'''
        self._intf.query('TOFIRSTSITE')

    def get_die(self):
        ''' Get chip index '''
        reply=''
        for n in range(10):
            if reply == '0:' or reply == '':
                reply = self._intf.query('GETCR')
            else:
                break
        reply = re.sub(r'[a-zA-Z]', r'', reply)
        values = reply.split(',')
        return (abs(int(values[1])), abs(int(values[0])))

    def contact(self):
        ''' Move chuck to contact z position'''
        self._intf.query('ZCHUCKUP')

    def separate(self):
        ''' Move chuck to separation z position'''
        self._intf.query('ZCHUCKDOWN')

    def load(self):
        ''' Move chuck to load z position'''
        self._intf.query('LOADWAFER')

    def unload(self):
        ''' Move chuck to load z position'''
        self._intf.query('UNLOADWAFER')

    def get_id(self):
        ''' Get id '''
        return self._intf.query('*IDN?')

    def step_z(self, amount):
        self._intf.query('STEPZCHUCK %i' % (amount))

    def mv_z_rel(self, amount):
        self._intf.query('MOVEZREL %i' % (amount))

    def mv_z_abs(self, amount):
        self._intf.query('MOVEZABS %i' % (amount))

    def get_z(self):
        return self._intf.query('GETZCHUCK')

    def set_z_home(self):
        self._intf.query('SETZHOME')

    def reset_z(self):
        self._intf.query('RESETZCHUCK')

    def set_speed(self, amount):
        self._intf.query('SETSPEED %i' % (amount))

    def get_id(self):
        ''' Get id '''
        return self._intf.query('*IDN?')
