#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 304                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-10 17:49:43 #$:
#


from basil.HL.HardwareLayer import HardwareLayer

from copy import deepcopy

read_only = ['read-only', 'readonly', 'ro']
write_only = ['write-only', 'writeonly', 'wo']


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

    '''
    _registers = {}

    def __init__(self, intf, conf):
        super(RegisterHardwareLayer, self).__init__(intf, conf)
        for item in self._registers.iterkeys():
            self.add_property(item)

    def init(self):
        for reg in self._registers.itervalues():
            # clear values
            if 'current' in reg:
                reg['current'] = None
            # set values from init
            if reg in self._init:
                self[reg] = self._init[reg]

    def set_configuration(self, conf):
        if conf:
            for reg, value in conf.iteritems():
                self[reg] = value

    def get_configuration(self):
        conf = {}
        for reg in self._registers.iterkeys():
            descr = self._registers[reg]['descr']
            if not ('properties' in descr and [i for i in write_only if i in descr['properties']]):
                conf[reg] = self[reg]
        return conf

    def add_property(self, attribute):
        # create local setter and getter with a particular attribute name
        getter = lambda self: self._get(attribute)
        setter = lambda self, value: self._set(attribute, value)

        # construct property attribute and add it to the class
        setattr(self.__class__, attribute, property(fget=getter, fset=setter, doc=attribute + ' register'))

    def set_default(self):
        for reg, value in self._registers.iteritems():
            if 'default' in value and not ('properties' in value['descr'] and [i for i in read_only if i in self._registers[reg]['descr']['properties']]):
                self._set(reg, value['default'])

    def _get(self, reg):
        descr = deepcopy(self._registers[reg]['descr'])
        if 'properties' in descr and [i for i in write_only if i in descr['properties']]:
            #raise IOError('Register is write-only')
            # allows a lazy style of programming
            if 'default' in self._registers[reg]:
                self._set(reg, self._registers[reg]['default'])
            else:
                self._set(reg, 0)
            # return nothing to prevent misuse
        else:
            descr.setdefault('offset', 0)
            ret_val = self._get_value(**descr)
            curr_val = self._registers[reg].setdefault('current', None)
            if curr_val and curr_val != ret_val:
                raise ValueError('Read value is not expected', curr_val, ret_val)
            return ret_val

    def _set(self, reg, value):
        descr = deepcopy(self._registers[reg]['descr'])
        if 'properties' in descr and [i for i in read_only if i in descr['properties']]:
            raise IOError('Register is read-only')
        descr.setdefault('offset', 0)
        try:
            self._set_value(value, **descr)
        except ValueError:
            raise
        else:
            self._registers[reg].update({'current': value if isinstance(value, (int, long)) else int(value, base=2)})

    def __getitem__(self, name):
        return self._get(name)

    def __setitem__(self, name, value):
        return self._set(name, value)

    def __getattr__(self, name):
        '''called only on last resort if there are no attributes in the instance that match the name
        '''
        def method(*args, **kargs):
            nsplit = name.split('_')
            if(len(nsplit) == 2):
                if(nsplit[0] == 'set' and len(args) == 1):
                    self[nsplit[1]] = args[0]
                elif(nsplit[0] == 'get'):
                    return self[nsplit[1]]
                else:
                    raise AttributeError("%r object has no attribute %r" % (self.__class__, name))
            else:
                raise AttributeError("%r object has no attribute %r" % (self.__class__, name))
        return method
