#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import struct
from bitarray import bitarray


class BitLogic(bitarray):
    def __new__(cls, *args, **kwargs):
        '''Initialize BitLogic with size (int) or bit string
        '''
        endian = kwargs.pop('endian', 'little')
        try:
            _ = int(args[0], base=2)
        except (TypeError, IndexError):
            # init by length
            ba = bitarray.__new__(cls, *args, endian=endian, **kwargs)
            # init to 0
            ba.setall(False)
        else:
            # init by bit string
            ba = bitarray.__new__(cls, args[0][::-1], *args[1:], endian=endian, **kwargs)
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
        if size and value.bit_length() > size:
            raise ValueError('Value is too big for given size')
        self.frombytes(struct.pack(fmt, value))
        if size:
            if not isinstance(size, (int, long)) or not size > 0:
                raise ValueError('Size must be greater than zero')
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

    def __str__(self):
        if self.endian() == 'little':
            return self.to01()[::-1]
        else:
            return self.to01()

    def __getitem__(self, key):
        slc = self._swap_slice_indices(key)
        # returns bool if index access, else bitarray
        return bitarray.__getitem__(self, slc)

    def __setitem__(self, key, item):
        '''Indexing and slicing

        Note: the length must not be changed
        '''
        length = self.length()
        try:
            # item is bit string
            _ = int(item, base=2)
        except TypeError:
            if type(item) in (int, long):
                # item is number, bool
                slc = self._swap_slice_indices(key, make_slice=True)
                size = slc.stop - slc.start
                bl = BitLogic.from_value(value=item, size=size)
                bitarray.__setitem__(self, slc, bl)
            else:
                # item is bitarray, list, tuple, bool
                # make slice if item is no bool, otherwise assignment will be casted to bool, and is most likely True
                slc = self._swap_slice_indices(key, make_slice=True if (type(item) not in (bool, )) else False)
                bitarray.__setitem__(self, slc, item)
        else:
            slc = self._swap_slice_indices(key, make_slice=True)
            bl = BitLogic(item)
            bitarray.__setitem__(self, slc, bl)
        if self.length() != length:
            raise ValueError('Unexpected length for slice assignment')

    def _swap_slice_indices(self, slc, make_slice=False):
        '''Swap slice indices

        Change slice indices from Verilog slicing (e.g. IEEE 1800-2012) to Python slicing.
        '''
        try:
            start = slc.start
            stop = slc.stop
            slc_step = slc.step
        except AttributeError:
            if make_slice:
                if slc < 0:
                    slc += self.length()
                return slice(slc, slc + 1)
            else:
                return slc
        else:
            if not start and start != 0:
                slc_stop = self.length()
            elif start < 0:
                slc_stop = self.length() + start + 1
            else:
                slc_stop = start + 1
            if not stop and stop != 0:
                slc_start = 0
            elif stop < 0:
                slc_start = self.length() + stop
            else:
                slc_start = stop
            return slice(slc_start, slc_stop, slc_step)

    def set_slice_ba(self, start, stop, item):
        bitarray.__setitem__(self, slice(stop, start + 1), item)
