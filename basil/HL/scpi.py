#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import os
from yaml import load, BaseLoader, scanner

from basil.HL.RegisterHardwareLayer import HardwareLayer


# SCPI command mandatory by IEEE 488.2
_scpi_ieee_488_2 = {
    'clear': '*CLS',
    'reset': '*RST',
    'trigger': '*TRG',
    'get_name': '*IDN?'
}


class scpi(HardwareLayer):

    '''Implement Standard Commands for Programmable Instruments (SCPI).
    '''

    def __init__(self, intf, conf):
        super(scpi, self).__init__(intf, conf)

    def init(self):
        super(scpi, self).init()
        self._scpi_commands = _scpi_ieee_488_2.copy()
        device_desciption = os.path.join(os.path.dirname(__file__), self._init['device'].lower().replace(" ", "_") + '.yaml')
        try:
            with open(device_desciption, 'r') as in_file:
                self._scpi_commands.update(load(in_file, Loader=BaseLoader))
        except scanner.ScannerError:
            raise RuntimeError('Parsing error for ' + self._init['device'] + ' device description in file ' + device_desciption)
        except IOError:
            raise RuntimeError('Cannot find a device description for ' + self._init['device'] + '. Consider adding it!')
        name = self.get_name()
        if self._scpi_commands['identifier'] not in self.get_name():
            raise RuntimeError('Wrong device description (' + self._init['device'] + ') loaded for ' + name)

    def __getattr__(self, name):
        '''dynamically adding device specific commands
        '''
        def method(*args, **kwargs):
            channel = kwargs.pop('channel', None)
            try:
                command = self._scpi_commands['channel %s' % channel][name] if channel is not None else self._scpi_commands[name]
            except:
                raise ValueError('SCPI command %s is not defined for device %s' % (name, self.name))

            name_split = name.split('_', 1)
            if len(name_split) == 2 and name_split[0] == 'set' and len(args) == 1 and not kwargs:
                self._intf.write(command + ' ' + str(args[0]))
            elif len(name_split) == 2 and name_split[0] == 'get' and not args and not kwargs:
                return self._intf.query(command)
            elif len(name_split) >= 1 and not args and not kwargs:
                self._intf.write(command)
            else:
                raise ValueError('Invalid SCPI command %s for device %s with args=%s and kwargs=%s' % (name, self.name, str(args), str(kwargs)))

        return method
