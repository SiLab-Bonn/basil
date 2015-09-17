#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Base


class RegisterLayer(Base):
    def __init__(self, driver, conf):
        super(RegisterLayer, self).__init__(conf)
        self._drv = driver

    def __getattr__(self, name):
        if not hasattr(getattr(self._drv, name), '__call__'):
            return getattr(self._drv, name)

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

            attr = getattr(self._drv, name)
            return attr(*arg, **kargs)

        return method
