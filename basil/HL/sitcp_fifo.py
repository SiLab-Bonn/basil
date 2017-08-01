#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
from time import sleep

import numpy as np

from basil.HL.HardwareLayer import HardwareLayer


class sitcp_fifo(HardwareLayer):
    ''' SiTCP driver that mimics the RegisterHardwareLayer BRAM and SRAM FIFO interfaces.
    '''
    _version = 0

    def __getitem__(self, name):
        if key == "RESET":
            self._intf.reset_fifo()
        elif name == 'VERSION':
            return array('B', struct.pack('I', _version))
        elif name == 'FIFO_SIZE':
            return array('B', struct.pack('I', self._intf._get_tcp_data_size()))
        else:
            super(sitcp_fifo, self).__getitem__(name)

    def __setitem__(self, name, value):
        if key == "RESET":
            self._intf.reset_fifo()
        else:
            super(sitcp_fifo, self).__setitem__(name, value)

    def __getattr__(self, name):
        '''called only on last resort if there are no attributes in the instance that match the name
        '''
        if name.isupper():
            return self[name]
        else:
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
            self[name] = value
        else:
            super(RhlHandle, self).__setattr__(name, value)
