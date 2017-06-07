#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import os
from yaml import load, BaseLoader, scanner

from basil.HL.RegisterHardwareLayer import HardwareLayer


class scpi(HardwareLayer):
    '''Implement Standard Commands for Programmable Instruments (SCPI).
    '''

    def __init__(self, intf, conf):
        super(scpi, self).__init__(intf, conf)

    def init(self):
        device_desciption = os.path.join(os.path.dirname(__file__), self._init['device'].lower().replace(" ", "_") + '.yaml')
        try:
            with open(device_desciption, 'r') as in_file:
                self._scpi_commands = load(in_file, Loader=BaseLoader)
        except scanner.ScannerError:
            raise RuntimeError('Parsing error for ' + self._init['device'] + ' device description in ' + device_desciption)
        except IOError:
            raise RuntimeError('Cannot find a device description for ' + self._init['device'] + ' Consider adding it!')
        name = self.get_name()
        if self._scpi_commands['identifier'] not in self.get_name():
            raise RuntimeError('Wrong device description (' + self._init['device'] + ') loaded for ' + name)

    def clear(self):  # SCPI command mandatory by IEEE 488.2
        self._intf.write('*CLS')

    def reset(self):  # SCPI command mandatory by IEEE 488.2
        self._intf.write('*RST')

    def trigger(self):  # SCPI command mandatory by IEEE 488.2
        self._intf.write('*TRG')

    def get_name(self):  # SCPI command mandatory by IEEE 488.2
        return self._intf.query('*IDN?')

    def __getattr__(self, name):
        '''called only on last resort if there are no attributes in the instance that match the name
        '''
        def method(*args, **kwargs):
            channel = kwargs.pop('channel', None)
            try:
                command = self._scpi_commands['channel %s' % channel][name] if channel is not None else self._scpi_commands[name]
            except:
                raise ValueError('SCPI command %s is not defined for %s' % (name, self.__class__))
            name_split = name.split('_', 1)
            if len(name_split) == 1:
                self._intf.write(command)
            elif len(name_split) == 2 and name_split[0] == 'set' and len(args) == 1 and not kwargs:
                self._intf.write(command + ' ' + str(args[0]))
            elif len(name_split) == 2 and name_split[0] == 'get' and not args and not kwargs:
                return self._intf.query(command)

        return method
