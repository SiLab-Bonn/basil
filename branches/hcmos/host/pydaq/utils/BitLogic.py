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

from bitarray import bitarray


class BitLogic():
    def __init__(self,*args, **kwargs):
        ##bitarray.__init__(self,kwargs["size"])  ## this does not work
        if len(args)!=0:
            raise TypeError("Invalid arguent")
        if kwargs.has_key("size"):
            self.ba=bitarray(kwargs["size"])
            del kwargs["size"]
        elif len(kwargs)==0:
            self.ba=bitarray()
        if len(kwargs)!=0:
            raise TypeError("Invalid arguent")
        self.size=len(self.ba)
    def __len__(self):
        return self.size
    
    def __str__(self):
        return str(self.ba)[10:-2]

    def swap_bits(self):
        svec = str(self)
        return BitLogic(bitstring=svec[::-1])

    def __getslice__(self, i, j):
        ret = self.ba[self.size-j, self.size-i + 1]
        return ret

    def __getitem__(self, key):
        if isinstance(key, int):
            return self.ba[self.size - 1 - key]
        else:
            raise TypeError("Invalid argument type.")

    def __setitem__(self, key, item):
        if isinstance(key, slice):
            if isinstance(item, (int, long)):
                self.ba[self.size-key.start - 1:self.size-key.stop]=bitarray(format(item, '0%db'%(key.start-key.stop + 1)))
            elif isinstance(item, BitLogic):
                print "__setitem__", item.ba, str(item.ba)
                self.ba[self.size-key.start - 1:self.size-key.stop]=item.ba
            else:
                raise TypeError("Invalid argument type.")
        elif isinstance(key, int):
            self.ba[self.size - 1 - key] = item
        else:
            raise TypeError("Invalid argument type.")
