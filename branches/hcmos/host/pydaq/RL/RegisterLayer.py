#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#


from pydaq import Base


class RegisterLayer(Base):

    def __init__(self, driver, conf):
        Base.__init__(self, conf)
        self._drv = driver

    def __getattr__(self, name):
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
