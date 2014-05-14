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

import struct
from bitarray import bitarray


class BitLogic(bitarray):
    def __new__(cls, *args, **kwargs):
        if 'endian' in kwargs:
            endian = kwargs.pop('endian')
            ba = super(BitLogic, cls).__new__(cls, *args, endian=endian, **kwargs)
        else:
            ba = super(BitLogic, cls).__new__(cls, *args, endian='little', **kwargs)  # set little endian by default
        if args and isinstance(args[0], (int, long)):
            ba.setall(False)
        return ba

    @classmethod
    def from_value(cls, value, size=None, fmt='Q', **kwargs):
        '''
        Factory method

        For format characters see: https://docs.python.org/2/library/struct.html
        '''
        bl = cls(**kwargs)  # size is 0 by default
        bl.fromvalue(value=value, size=size, fmt=fmt)
        return bl

    def fromvalue(self, value, size=None, fmt='Q'):
        '''
        Append from a int/long number.
        '''
        self.frombytes(struct.pack(fmt, value))
        if size:
            if size > self.length():
                bitarray.extend(self, (size - self.length()) * [0])
            else:
                bitarray.__delitem__(self, slice(size, self.length()))  # or use __delslice__() (deprecated)

    def __getitem__(self, key):
        if isinstance(key, slice):
            return bitarray.__getitem__(self, self._swap_slice_indices(key))
        elif isinstance(key, (int, long)):
            return bitarray.__getitem__(self, key)
        else:
            raise TypeError("Invalid argument type")

    def __str__(self):
        return bitarray.__str__(self)[10:-2]

    def __setitem__(self, key, item):
        if isinstance(key, slice):
            if isinstance(item, (int, long)):
                slc = self._swap_slice_indices(key)
                bl = BitLogic.from_value(value=item, size=slc.stop - slc.start)
                bitarray.__setitem__(self, self._swap_slice_indices(key), bitarray.__getitem__(bl, slice(None, None)))
            elif isinstance(item, bitarray):
                bitarray.__setitem__(self, self._swap_slice_indices(key), bitarray.__getitem__(item, slice(None, None)))
            else:
                raise TypeError("Invalid argument type")
        elif isinstance(key, (int, long)):
            return bitarray.__setitem__(self, key, item)
        else:
            raise TypeError("Invalid argument type")

    def _swap_slice_indices(self, slc):
        '''
        Swap slice indices
        '''
        if not slc.start:
            stop = self.length()
        else:
            stop = slc.start + 1
        if not slc.stop:
            start = 0
        else:
            start = slc.stop
        step = slc.step
        return slice(start, stop, step)


