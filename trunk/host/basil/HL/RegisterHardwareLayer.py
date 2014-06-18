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


class RegisterHardwareLayer(HardwareLayer):
    '''Register Hardware Layer.

    Implementation of advanced register operations.
    '''
    _registers = {}

    def __init__(self, intf, conf):
        super(RegisterHardwareLayer, self).__init__(intf, conf)
        for item in self._registers.iterkeys():
            self.add_property(item)

    def init(self):
        pass

    def add_property(self, attribute):
        # create local setter and getter with a particular attribute name
        getter = lambda self: self.get(attribute)
        setter = lambda self, value: self.set(attribute, value)

        # construct property attribute and add it to the class
        setattr(self.__class__, attribute, property(fget=getter, fset=setter, doc=attribute + ' register'))

    def set_default(self):
        for reg in self._registers.iterkeys():
            self.set(reg, self._registers[reg]['default'])

    def get(self, reg):
        descr = self._registers[reg]['descr']
        descr.setdefault('offset', 0)
        curr_val = self._registers[reg].setdefault('current', None)
        ret_val = self._get_value(**descr)
        if curr_val and curr_val != ret_val:
            raise ValueError('Read value is not expected')
        return ret_val

    def set(self, reg, value):
        descr = self._registers[reg]['descr']
        descr.setdefault('offset', 0)
        self._registers[reg].update({'current': value if isinstance(value, (int, long)) else int(value, base=2)})
        self._set_value(value, **descr)
