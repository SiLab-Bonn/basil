#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
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

    def tovalue(self, fmt='Q'):
        '''
        Convert bitstring to a int/long number.
        '''
        format_size = struct.calcsize(fmt)
        if self.length() > format_size * 8:
            raise ValueError('Cannot convert to number')
        ba = self.copy()
        ba.extend((format_size * 8 - self.length()) * [0])
        return struct.unpack_from(fmt, ba.tobytes())[0]

    def __getitem__(self, key):
        if isinstance(key, slice):
            return bitarray.__getitem__(self, self._swap_slice_indices(key))
        elif isinstance(key, (int, long)):
            return bitarray.__getitem__(self, key)
        else:
            raise TypeError("Invalid argument type")

    def __str__(self):
        if self.endian() == 'little':
            return self.to01()[::-1]
        else:
            return self.to01()

    def __setitem__(self, key, item):
        if isinstance(key, slice):
            if isinstance(item, bitarray):
                bitarray.__setitem__(self, self._swap_slice_indices(key), item)
            elif isinstance(item, (int, long)):
                slc = self._swap_slice_indices(key)
                bl = BitLogic.from_value(value=item, size=slc.stop - slc.start)
                bitarray.__setitem__(self, slc, bl)
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

    def set_slice_ba(self, start, stop, item):
        bitarray.__setitem__(self, slice(stop, start + 1), item)
