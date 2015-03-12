#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import HardwareLayer
from yaml import safe_load


class scpi(HardwareLayer):
    '''Implement Standard Commands for Programmable Instruments (SCPI).
    '''

    def __init__(self, intf, conf):
        super(scpi, self).__init__(intf, conf)

    def init(self):
        with open(self._init['device'], 'r') as in_file:
            self._scpi_commands = safe_load(in_file)

    def clear(self):  # SCPI command mandatory by IEEE 488.2
        self._intf.write('*CLS')

    def reset(self):  # SCPI command mandatory by IEEE 488.2
        self._intf.write('*RST')

    def get_name(self):  # SCPI command mandatory by IEEE 488.2
        return self._intf.ask('*IDN?')

    def __getattr__(self, name):
        '''called only on last resort if there are no attributes in the instance that match the name
        '''
        if name not in self._scpi_commands:
            raise ValueError('SCPI command %s is not defined for %s' % (name, self.__class__))

        def method(*args, **kwargs):
            self._intf.ask(self._scpi_commands[name])
        return method
