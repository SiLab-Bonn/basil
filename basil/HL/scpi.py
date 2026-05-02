#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging
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
    def has_error_queue(self):
        '''Whether or not device has an error queue which could be be read with the available commands.'''
        return self._scpi_error_available

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
        self._scpi_binary_enabled = False
        self._scpi_error_available = True
        device_desciption = os.path.join(os.path.dirname(__file__),
                                         self._init['device'].lower().replace(" ", "_") + '.yaml')
        try:
            with open(device_desciption, 'r') as in_file:
                self._scpi_commands.update(load(in_file, Loader=BaseLoader))
        except scanner.ScannerError:
            raise RuntimeError(
                'Parsing error for ' + self._init['device'] + ' device description in file ' + device_desciption)
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

        # Device commands using binary data to return
        if '__scpi_binary_commands' in self._scpi_commands:
            self._scpi_binary_commands = self._scpi_commands.pop('__scpi_binary_commands')
            if "enable_binary_commands" in self._init and self._init["enable_binary_commands"]:
                self._scpi_binary_enabled = True

        # check for the availability of the error queue
        if 'clear_errors' not in self._scpi_commands:
            self._scpi_error_available = False
        if 'get_n_errors' not in self._scpi_commands:
            self._scpi_error_available = False

        if 'load_error' not in self._scpi_commands:
            self._scpi_error_available = False

        if 'get_error_code' not in self._scpi_commands:
            self._scpi_error_available = False

        if 'get_error_message' not in self._scpi_commands:
            self._scpi_error_available = False

        if 'get_error_severity' not in self._scpi_commands:
            self._scpi_error_available = False

        if 'get_error_node' not in self._scpi_commands:
            self._scpi_error_available = False

    def __getattr__(self, name):
        '''dynamically adding device specific commands
        '''

        def method(*args, **kwargs):
            channel = kwargs.pop('channel', None)

            # some devices could use a binary stream to transmit data
            binarystream = kwargs.pop('binary_enabled', False)
            try:
                command = self._scpi_commands['channel %s' % channel][name] if channel is not None else \
                self._scpi_commands[name]
            except Exception:
                raise ValueError('SCPI command %s is not defined for device %s' % (name, self.name))

            name_split = name.split('_', 1)
            if len(name_split) == 2 and name_split[0] == 'set' and len(args) == 1 and not kwargs:
                self._intf.write(command + ' ' + str(args[0]))
            elif len(name_split) == 2 and name_split[0] == 'get' and not args and not kwargs:
                if binarystream and self._scpi_binary_enabled and name in self._scpi_binary_command:
                    res = self._intf.query_binary(command, datatype=self._scpi_binary_commands[name]['datatype'])
                else:
                    res = self._intf.query(command)
                if self.has_formatting and self._formatting_enabled and name in self._scpi_query_fmt['fmt_method']:
                    res = self._scpi_query_fmt['fmt_method'][name].format(
                        *res.strip().split(self._scpi_query_fmt['fmt_sep']))
                return res
            elif len(name_split) >= 1 and not args and not kwargs:
                self._intf.write(command)
            else:
                raise ValueError(
                    'Invalid SCPI command %s for device %s with args=%s and kwargs=%s' % (name, self.name, str(args),
                                                                                          str(kwargs)))

        return method

    def enable_formatting(self):
        '''Enables formatting if specified in device description'''
        if not self.has_formatting:
            raise AttributeError(
                "No formatting specified for {}! Specify formatting by adding '__scpi_query_fmt' in the device description yaml".format(
                    self._init['device']))
        self._formatting_enabled = True

    def disable_formatting(self):
        self._formatting_enabled = False

    def user_command(self, data):
        self._intf.write(data)

    def user_query(self, data):
        self._intf.query(data)

    def drain_error_queue(self):
        '''Drains the error queue of the device and creates log entries for each error.'''
        if not self.has_error_queue:
            logging.getLogger(__name__).warning("Device {} does not have an error queue".format(self.name))
        else:
            n_errors = self.get_n_errors()
            while n_errors > 0:
                # need to verify the implementation:
                if "load_error" in self._scpi_error_available:
                    self.load_error()
                    err_code = self.get_error_code()
                    err_msg = self.get_error_message()
                    err_severity = self.get_error_severity()
                    err_node = self.get_error_node()
                elif "get_error_code" in self._scpi_error_available:
                    next_error = self.get_error_code()
                    err_code, err_msg = next_error.split(',')
                    err_severity = 20
                    err_node = "UNDEFINED"
                else:
                    raise AttributeError("No error queue available for device {}".format(self.name))
                if err_severity == 40:
                    logging.getLogger(__name__).fatal(
                        "Device {} at node {} with code {}: {}".format(self.name, err_node, err_code, err_msg))
                elif err_severity == 30:
                    logging.getLogger(__name__).error(
                        "Device {} at node {} with code {}: {}".format(self.name, err_node, err_code, err_msg))
                elif err_severity == 20:
                    logging.getLogger(__name__).warning(
                        "Device {} at node {} with code {}: {}".format(self.name, err_node, err_code, err_msg))
                else:
                    logging.getLogger(__name__).info(
                        "Device {} at node {} with code {}: {}".format(self.name, err_node, err_code, err_msg))
                n_errors = self.get_n_errors()

