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

from BitVector import BitVector


class BitLogic(BitVector):

    def __init__(self, *args, **kwargs):
        BitVector.__init__(self, *args, **kwargs)

    def swap_bits(self):
        svec = str(self)
        return BitLogic(bitstring=svec[::-1])

    def __getslice__(self, i, j):
        ret = BitVector.__getslice__(self, j, i + 1)
        return BitLogic(bitstring=str(ret)).swap_bits()

    def __getitem__(self, key):
        if isinstance(key, int):
            return BitVector.__getitem__(self, self.size - 1 - key)
        else:
            raise TypeError("Invalid argument type.")

    def __setitem__(self, key, item):

        if isinstance(key, slice):
            if isinstance(item, (int, long)):
                BitVector.__setitem__(self, slice(key.stop, key.start + 1), BitVector(bitstring=str(BitVector(size=key.start - key.stop + 1, intVal=item))[::-1]))
            elif isinstance(item, BitVector):
                BitVector.__setitem__(self, slice(key.stop, key.start + 1), BitVector(bitstring=str(item)[::-1]))
            else:
                raise TypeError("Invalid argument type.")
        elif isinstance(key, int):
            return BitVector.__setitem__(self, self.size - 1 - key, item)
        else:
            raise TypeError("Invalid argument type.")
