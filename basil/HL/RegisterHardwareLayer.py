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

from basil.utils.BitLogic import BitLogic
from basil.HL.HardwareLayer import HardwareLayer


# description attributes
read_only = ['read_only', 'read-only', 'readonly', 'ro']
write_only = ['write_only', 'write-only', 'writeonly', 'wo']
is_byte_array = ['byte_array', 'byte-array', 'bytearray']


class RegisterHardwareLayer(HardwareLayer, dict):
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
        for reg in self._registers.iterkeys():
            self.add_property(reg)
            dict.__setitem__(self, reg, None)  # set values, but not writing to the interface

    def init(self):
        # reset on initialization
#         self.RESET = 0
        if 'VERSION' in self._registers:
            version = str(self.VERSION)
        else:
            version = None
        logging.info("Initializing %s (firmware version: %s), module %s" % (self.name, version if 'VERSION' in self._registers else 'n/a', self.__class__.__module__))
        if self._require_version and not eval(version + self._require_version):
            raise Exception("FPGA module %s does not satisfy version requirements (read: %s, require: %s)" % (self.__class__.__module__, version, self._require_version.strip()))
        for reg, value in self._registers.iteritems():
            if reg in self._init:
                self[reg] = self._init[reg]
            elif 'default' in value and not ('properties' in value['descr'] and [i for i in read_only if i in value['descr']['properties']]):
                self[reg] = value['default']
            else:  # do nothing here, no value to write
                pass
#                 self[reg] = None

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
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._base_addr + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        reg[size + offset - 1:offset] = value
        self._intf.write(self._base_addr + addr, data=array.array('B', reg.tobytes()))

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
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._base_addr + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        return reg[size + offset - 1:offset].tovalue()

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
                self._set(reg, self._registers[reg]['default'])
            else:
                self._set(reg, 0)
            # raise error when doing read on write-only register
#             raise IOError('Register is write-only')
            # return None to prevent misuse
            return None
        else:
            if 'properties' in descr and [i for i in is_byte_array if i in descr['properties']]:
                ret_val = self.get_bytes(**descr)
                ret_val = array.array('B', ret_val).tolist()
#                 curr_val = dict.__getitem__(self, reg)
            else:
                descr.setdefault('offset', 0)
                ret_val = self.get_value(**descr)
                curr_val = dict.__getitem__(self, reg)
#                 curr_val = self.setdefault(reg, None)
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
            dict.__setitem__(self, reg, value)
        else:
            descr.setdefault('offset', 0)
            try:
                self.set_value(value, **descr)
            except ValueError:
                raise
            else:
                dict.__setitem__(self, reg, value if isinstance(value, (int, long)) else int(value, base=2))

    def __getitem__(self, name):
        return self._get(name)

    def __setitem__(self, name, value):
        return self._set(name, value)

    def __getattr__(self, name):
        '''called only on last resort if there are no attributes in the instance that match the name
        '''
        if name.isupper() and name not in self._registers:
            raise ValueError('%s register does not exist in %s' % (name, self.__class__))

        def method(*args, **kwargs):
            nsplit = name.split('_', 1)
            if len(nsplit) == 2 and nsplit[0] == 'set' and len(args) == 1 and not kwargs:
                self[nsplit[1]] = args[0]  # returns None
            elif len(nsplit) == 2 and nsplit[0] == 'get' and not args and not kwargs:
                return self[nsplit[1]]
            else:
                raise AttributeError("%r object has no attribute %r" % (self.__class__, name))
        return method

    def __setattr__(self, name, value):
        if name.isupper() and name not in self._registers:
            raise ValueError('%s register does not exist in %s' % (name, self.__class__))
        return dict.__setattr__(self, name, value)
