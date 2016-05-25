#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from collections import Callable

from basil.dut import Base


class RegisterLayer(Base):
    def __init__(self, driver, conf):
        super(RegisterLayer, self).__init__(conf)
        self._drv = driver

    def init(self):
        super(RegisterLayer, self).init()

    def __getattr__(self, name):
        if not self.is_initialized:  # this test allows attributes to be set in the __init__ method
            super(RegisterLayer, self).__getattr__(name)
        else:
            attr = getattr(self._drv, name)
            # for compatibility with RegisterHardwareLayer:
            # prevent wrting to a register twice
            if not isinstance(attr, Callable):
                return attr

            def method(*args, **kargs):
                arg = ()
                if 'arg_names' in self._conf:
                    for i in range(len(args)):
                        kargs[self._conf['arg_names'][i]] = args[i]
                else:
                    arg = args

                if 'arg_add' in self._conf:
                    for argn in self._conf['arg_add']:
                        kargs[argn] = self._conf['arg_add'][argn]

                return attr(*arg, **kargs)

            return method

    def __setattr__(self, name, value):
        if not self.is_initialized:  # this test allows attributes to be set in the __init__ method
            super(RegisterLayer, self).__setattr__(name, value)
        else:
            try:
                setattr(self._drv, name, value)
            except:
                super(RegisterLayer, self).__setattr__(name, value)
