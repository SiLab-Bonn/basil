#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer


class SignatoneProber(HardwareLayer):

    '''
    Implements functions to steer a Signatone probe station such as the one of lal in2p3 in Paris.
    '''

    def __init__(self, intf, conf):
        super(SignatoneProber, self).__init__(intf, conf)

    def goto_die(self, index_x, index_y):
        ''' Move chuck to wafer map chip index'''
        self._intf.write('MOVECR %d, %d' % (index_x, index_y))

    def goto_next_die(self):
        ''' Move chuck to next die from wafer map'''
        self._intf.write('NEXT')

    def goto_first_die(self):
        ''' Move chuck to first die from wafer map'''
        self._intf.write('TOFIRSTSITE')

    def get_die(self):
        ''' Get chip index '''
        reply = ''
        for n in range(10):
            if reply == '0:' or reply == '':
                reply = self._intf.query('GETCR')
            else:
                break
        values = reply.split(',')
        return (int(values[0]), int(values[1]))

    def contact(self):
        ''' Move chuck to contact z position'''
        self._intf.write('ZCHUCKUP')

    def separate(self):
        ''' Move chuck to separation z position'''
        self._intf.write('ZCHUCKDOWN')

    def load(self):
        ''' Move chuck to load z position'''
        self._intf.write('LOADWAFER')
