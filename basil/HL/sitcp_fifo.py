#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import struct
import array

import numpy as np

from basil.HL.HardwareLayer import HardwareLayer


class sitcp_fifo(HardwareLayer):
    ''' SiTCP driver that mimics the RegisterHardwareLayer BRAM and SRAM FIFO interfaces.

    No firmware module is available for this driver.
    This is just a driver that replaces BRAM and SRAM FIFO when the SiTCP transfer layer is used.
    '''
    _version = 0

    def __getitem__(self, name):
        if name == "RESET":
            self._intf.reset()  # returns None
        elif name == 'VERSION':
            return self._version
        elif name == 'FIFO_SIZE':
            return self._intf._get_tcp_data_size()
        else:
            super(sitcp_fifo, self).__getitem__(name)

    def __setitem__(self, name, value):
        if name == "RESET":
            self._intf.reset()
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
            super(sitcp_fifo, self).__setattr__(name, value)

    def get_data(self):
        ''' Reading data from SiTCP FIFO (via TCP).

        Returns
        -------
        array : numpy.ndarray
            Array of unsigned integers (32 bit).
        '''
        fifo_size = self._intf._get_tcp_data_size()
        fifo_int_size = int((fifo_size - (fifo_size % 4)) / 4)
        data = self._intf._get_tcp_data(fifo_int_size * 4)
        return np.frombuffer(data, dtype=np.dtype('<u4'))

    def set_data(self, data):
        ''' Sending data to via TCP.

        Parameters
        ----------
        data : array
            Array of unsigned integers (32 bit).
        '''
        data = array.array('B', struct.unpack("{}B".format(len(data) * 4), struct.pack("{}I".format(len(data)), *data)))
        self._intf._send_tcp_data(data)
