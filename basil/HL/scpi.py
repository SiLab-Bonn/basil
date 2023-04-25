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
    @property
    def has_formatting(self):
        '''Whether or not device has SCPI query formatting specified in device description'''
        return self._scpi_query_fmt is not None

    @has_formatting.setter
    def has_formatting(self, val):
        raise AttributeError("Attribute is read-only")

    @property
    def formatting_enabled(self):
        '''Whether or not device has SCPI query formatting is enabled'''
        return self._formatting_enabled

    @formatting_enabled.setter
    def formatting_enabled(self, val):
        raise AttributeError("Attribute is read-only")

    def __init__(self, intf, conf):
        super(scpi, self).__init__(intf, conf)

    def init(self):
        super(scpi, self).init()
        self._scpi_commands = _scpi_ieee_488_2.copy()
        self._scpi_query_fmt = None
        self._formatting_enabled = False
        device_desciption = os.path.join(os.path.dirname(__file__), self._init['device'].lower().replace(" ", "_") + '.yaml')
        try:
            with open(device_desciption, 'r') as in_file:
                self._scpi_commands.update(load(in_file, Loader=BaseLoader))
        except scanner.ScannerError:
            raise RuntimeError('Parsing error for ' + self._init['device'] + ' device description in file ' + device_desciption)
        except IOError:
            raise RuntimeError('Cannot find a device description for ' + self._init['device'] + '. Consider adding it!')
        if 'identifier' in self._scpi_commands and self._scpi_commands['identifier']:
            name = self.get_name()
            if self._scpi_commands['identifier'] not in name:
                raise RuntimeError('Wrong device description (' + self._init['device'] + ') loaded for ' + name)
        # Device specific query return value formatting
        if '__scpi_query_fmt' in self._scpi_commands:
            self._scpi_query_fmt = self._scpi_commands.pop('__scpi_query_fmt')
        # Check if we want to enable formatting from the init
        if 'enable_formatting' in self._init and self._init['enable_formatting']:
            self.enable_formatting()

    def __getattr__(self, name):
        '''dynamically adding device specific commands
        '''
        def method(*args, **kwargs):
            channel = kwargs.pop('channel', None)
            command = None
            try:
                command = self._scpi_commands[f'channel {channel}'][name] if channel is not None else self._scpi_commands[name]
            # Fails with KeyError if attribute is not found; TypeError if channel-based attribute is not a dict
            except (KeyError, TypeError):
                pass
            # If command is still None, the attribute does not exist and we raise an AttributeError
            if command is None:
                chnl_msg = f"channel {channel} of"
                err_msg = f"SCPI command {name} is not defined for {chnl_msg if channel is not None else ''} device {self.name}!"
                raise AttributeError(err_msg)

            name_split = name.split('_', 1)
            if len(name_split) == 2 and name_split[0] == 'set' and len(args) == 1 and not kwargs:
                self._intf.write(command + ' ' + str(args[0]))
            elif len(name_split) == 2 and name_split[0] == 'get' and not args and not kwargs:
                res = self._intf.query(command)
                if self.has_formatting and self._formatting_enabled and name in self._scpi_query_fmt['fmt_method']:
                    res = self._scpi_query_fmt['fmt_method'][name].format(*res.strip().split(self._scpi_query_fmt['fmt_sep']))
                return res
            elif len(name_split) >= 1 and not args and not kwargs:
                self._intf.write(command)
            else:
                raise ValueError('Invalid SCPI command %s for device %s with args=%s and kwargs=%s' % (name, self.name, str(args), str(kwargs)))

        return method

    def enable_formatting(self):
        '''Enables formatting if specified in device description'''
        if not self.has_formatting:
            raise AttributeError("No formatting specified for {}! Specify formatting by adding '__scpi_query_fmt' in the device description yaml".format(self._init['device']))
        self._formatting_enabled = True

    def disable_formatting(self):
        self._formatting_enabled = False
