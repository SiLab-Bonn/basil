#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
from copy import deepcopy
import collections
import array
from collections import namedtuple

from basil.utils.BitLogic import BitLogic
from basil.HL.HardwareLayer import HardwareLayer


# description attributes
read_only = ['read_only', 'read-only', 'readonly', 'ro']
write_only = ['write_only', 'write-only', 'writeonly', 'wo']
is_byte_array = ['byte_array', 'byte-array', 'bytearray']


class RegisterHardwareLayer(HardwareLayer):
    '''Register Hardware Layer.

    Implementation of advanced register operations.

    Example:
    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},       <-- 8-bit reset register, writeonly
                  'LOST_DATA_COUNTER': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},  <-- 8-bit data register, 'ro' equivalent to 'readonly'
                  'ENABLE': {'descr': {'addr': 1, 'size': 1, 'offset': 0}},                      <-- 1-bit register
                  'ENABLE_EXTERN': {'descr': {'addr': 1, 'size': 1, 'offset': 1}},               <-- 1-bit register
                  'EN_ARMING': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},                   <-- 1-bit register
                  'EN_WRITE_TIMESTAMP': {'descr': {'addr': 1, 'size': 1, 'offset': 3}},          <-- 1-bit register
                  'EVENT_COUNTER': {'descr': {'addr': 2, 'size': 32, 'properties': ['ro']}}      <-- 32-bit register, 'ro' equivalent to 'readonly'
    _require_version = '==3'  <-- or use '<=', '>=', ... accordingly
    '''
    _registers = {}
    _require_version = None

    def __init__(self, intf, conf):
        super(RegisterHardwareLayer, self).__init__(intf, conf)
        # require interface and base address
        self._intf = intf
        self._base_addr = conf['base_addr']
        rv = namedtuple('_register_values', field_names=self._registers.iterkeys())
        self._register_values = rv(*([None] * len(self._registers)))
        for reg in self._registers.iterkeys():
            if not reg.isupper():
                raise ValueError("Register %s must be uppercase." % reg)
            self.add_property(reg)

    def init(self):
        super(RegisterHardwareLayer, self).init()
        # reset during initialization to get default state and to remove any prior settings
        if "RESET" in self._registers:
            self.RESET  # assign no value, to read back value and write same value or default value
        if 'VERSION' in self._registers:
            version = str(self.VERSION)
        else:
            version = None
        logging.info("Initializing %s (firmware version: %s), module %s, base_addr %s" % (self.name, version if 'VERSION' in self._registers else 'n/a', self.__class__.__module__, hex(self._base_addr)))
        if self._require_version and not eval(version + self._require_version):
            raise Exception("FPGA module %s does not satisfy version requirements (read: %s, require: %s)" % (self.__class__.__module__, version, self._require_version.strip()))
        for reg, value in self._registers.iteritems():
            if reg in self._init:
                self[reg] = self._init[reg]
            elif 'default' in value and not ('properties' in value['descr'] and [i for i in read_only if i in value['descr']['properties']]):
                self[reg] = value['default']
            else:  # do nothing here, keep existing value
                pass
        unknown_regs = set(self._init.keys()).difference(set(self._registers.keys()))
        if unknown_regs:
            raise KeyError("Attempt to write to unknown register(s) in %s, module %s during initialization: %s" % (self.name, self.__class__.__module__, ", ".join(unknown_regs)))

    def set_value(self, value, addr, size, offset, **kwargs):
        '''Writing a value of any arbitrary size (max. unsigned int 64) and offset to a register

        Parameters
        ----------
        value : int, str
            The register value (int, long, bit string) to be written.
        addr : int
            The register address.
        size : int
            Bit size/length of the value to be written to the register.
        offset : int
            Offset of the value to be written to the register (in number of bits).

        Returns
        -------
        nothing
        '''
        div_offset, mod_offset = divmod(offset, 8)
        div_size, mod_size = divmod(size + mod_offset, 8)
        if mod_size:
            div_size += 1
        if mod_offset == 0 and mod_size == 0:
            reg = BitLogic.from_value(0, size=div_size * 8)
        else:
            ret = self._intf.read(self._base_addr + addr + div_offset, size=div_size)
            reg = BitLogic()
            reg.frombytes(ret.tostring())
        reg[size + mod_offset - 1:mod_offset] = value
        self._intf.write(self._base_addr + addr + div_offset, data=array.array('B', reg.tobytes()))

    def get_value(self, addr, size, offset, **kwargs):
        '''Reading a value of any arbitrary size (max. unsigned int 64) and offset from a register

        Parameters
        ----------
        addr : int
            The register address.
        size : int
            Bit size/length of the value.
        offset : int
            Offset of the value to be written to the register (in number of bits).

        Returns
        -------
        reg : int
            Register value.
        '''
        div_offset, mod_offset = divmod(offset, 8)
        div_size, mod_size = divmod(size + mod_offset, 8)
        if mod_size:
            div_size += 1
        ret = self._intf.read(self._base_addr + addr + div_offset, size=div_size)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        return reg[size + mod_offset - 1:mod_offset].tovalue()

    def set_bytes(self, data, addr, **kwargs):
        '''Writing bytes of any arbitrary size

        Parameters
        ----------
        data : iterable
            The data (byte array) to be written.
        addr : int
            The register address.

        Returns
        -------
        nothing
        '''
        self._intf.write(self._conf['base_addr'] + addr, data)

    def get_bytes(self, addr, size, **kwargs):
        '''Reading bytes of any arbitrary size

        Parameters
        ----------.
        addr : int
            The register address.
        size : int
            Byte length of the value.

        Returns
        -------
        data : iterable
            Byte array.
        '''
        return self._intf.read(self._conf['base_addr'] + addr, size)

    def set_configuration(self, conf):
        if conf:
            for reg, value in conf.iteritems():
                self[reg] = value

    def get_configuration(self):
        conf = {}
        for reg in self._registers.iterkeys():
            descr = self._registers[reg]['descr']
            if not ('properties' in descr and [i for i in write_only if i in descr['properties']]) and not ('properties' in descr and [i for i in read_only if i in descr['properties']]):
                conf[reg] = self[reg]
        return conf

    def add_property(self, attribute):
        # create local setter and getter with a particular attribute name
#         getter = lambda self: self._get(attribute)
#         setter = lambda self, value: self._set(attribute, value)
        # Workaround: obviously dynamic properties catch exceptions
        # Print error message and return None

        def getter(self):
            try:
                return self._get(attribute)
            except Exception, e:
                logging.error(e)
                return None

        def setter(self, value):
            try:
                return self._set(attribute, value)
            except Exception, e:
                logging.error(e)
                return None
        # construct property attribute and add it to the class
        setattr(self.__class__, attribute, property(fget=getter, fset=setter, doc=attribute + ' register'))

    def set_default(self):
        for reg, value in self._registers.iteritems():
            if 'default' in value and not ('properties' in value['descr'] and [i for i in read_only if i in self._registers[reg]['descr']['properties']]):
                self._set(reg, value['default'])

    def _get(self, reg):
        descr = deepcopy(self._registers[reg]['descr'])
        if 'properties' in descr and [i for i in write_only if i in descr['properties']]:
            # allows a lazy-style of programming
            if 'default' in self._registers[reg]:
                return self._set(reg, self._registers[reg]['default'])
            else:
                descr.setdefault('offset', 0)
                return self._set(reg, self.get_value(**descr))
            # raise error when doing read on write-only register
#             raise IOError('Register is write-only')
            # return None to prevent misuse
#             return None
        else:
            if 'properties' in descr and [i for i in is_byte_array if i in descr['properties']]:
                ret_val = self.get_bytes(**descr)
                ret_val = array.array('B', ret_val).tolist()
            else:
                descr.setdefault('offset', 0)
                curr_val = self._register_values._asdict()[reg]
                if not self.is_initialized:  # this test allows attributes to be set in the __init__ method
                    ret_val = curr_val
                else:
                    ret_val = self.get_value(**descr)
                    if curr_val is not None and 'properties' in descr and not [i for i in read_only if i in descr['properties']] and curr_val != ret_val:
                        raise ValueError('Read value was not expected: read: %s, expected: %s' % (str(ret_val), str(curr_val)))
            return ret_val

    def _set(self, reg, value):
        descr = deepcopy(self._registers[reg]['descr'])
        if 'properties' in descr and [i for i in read_only if i in descr['properties']]:
            raise IOError('Register is read-only')
        if 'properties' in descr and [i for i in is_byte_array if i in descr['properties']]:
            if not isinstance(value, collections.Iterable):
                raise ValueError('For array byte_register iterable object is needed')
            value = array.array('B', value).tolist()
            self.set_bytes(value, **descr)
            self._register_values = self._register_values._replace(**{reg: value})
        else:
            descr.setdefault('offset', 0)
            value = value if isinstance(value, (int, long)) else int(value, base=2)
            try:
                self.set_value(value, **descr)
            except ValueError:
                raise
            else:
                self._register_values = self._register_values._replace(**{reg: value})

    def __getitem__(self, name):
        return self._get(name)

    def __setitem__(self, name, value):
        return self._set(name, value)

    def __getattr__(self, name):
        '''called only on last resort if there are no attributes in the instance that match the name
        '''
        if name.isupper():
            _ = self._register_values._asdict()[name]

        def method(*args, **kwargs):
            nsplit = name.split('_', 1)
            if len(nsplit) == 2 and nsplit[0] == 'set' and nsplit[1].isupper() and len(args) == 1 and not kwargs:
                self[nsplit[1]] = args[0]  # returns None
            elif len(nsplit) == 2 and nsplit[0] == 'get' and nsplit[1].isupper() and not args and not kwargs:
                return self[nsplit[1]]
            else:
                raise AttributeError("%r object has no attribute %r" % (self.__class__, name))
        return method

    def __setattr__(self, name, value):
        if name.isupper():
            _ = self._register_values._asdict()[name]
        super(RegisterHardwareLayer, self).__setattr__(name, value)
