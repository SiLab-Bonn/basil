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


class gpio(HardwareLayer):
    '''GPIO interface
    '''
    def __init__(self, intf, conf):
        super(gpio, self).__init__(intf, conf)

    def init(self):
        if 'init' in self._conf:
            if 'direction' in self._conf['init']:
                self.set_direction(0, self._conf['init']['direction'])

    def reset(self):
        '''Soft reset the module.'''
        self._intf.write(self._conf['base_addr'], [0])

    def set_direction(self, addr, value):
        self._intf.write(self._conf['base_addr'] + 3, value)

    def get_direction(self, addr):
        return self._intf.read(self._conf['base_addr'] + 3, size=1)

    def set_data(self, data):
        self._intf.write(self._conf['base_addr'] + 2, data)

    def get_data(self):
        return self._intf.read(self._conf['base_addr'] + 1, size=1)
