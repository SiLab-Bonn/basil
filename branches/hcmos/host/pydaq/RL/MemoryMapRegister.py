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

from RL.StdRegister import StdRegister
from collections import Iterable
import string


class MemoryMapRegister(StdRegister):

    def __init__(self, driver, conf):
        StdRegister.__init__(self, driver, conf)
        self.bit_map={}
        if conf.has_key("fields"):
            for field in conf["fields"]:
                if "name" in field and "bit_map" in field:
                  self.bit_map[field["name"]]=field["bit_map"]

    def __setitem__(self, key, value):
        print '__setitem__', key, " ",value
        if isinstance(key, slice):
            reg = self._construct_reg()
            reg[key.start:key.stop] = value
            self._deconstruct_reg(reg)
        elif isinstance(key, str):
            print dir(self.bit_map[key])
            if self.bit_map.has_key(key) :
                
                for k,v in self.bit_map[key].iteritems():
                    if value & (0x1 << v) == 0:
                        v=0
                    else:
                        v=1
                    self._fields[key][string.atoi(k)]= v
            else:
              self._fields[key][self._fields[key].size - 1:0] = value
        elif isinstance(key, int):
            reg = self._construct_reg()
            reg[key] = value
            self._deconstruct_reg(reg)
        else:
            raise TypeError("Invalid argument type.")


    def Write(self, args=None):
        print self._fields
        reg_sel = list()

        if(args == None):
            reg_sel = list([0, 1, 2, 3, 4, 5])  # TODO
        elif isinstance(args, Iterable):
            reg_sel = list(args)
        else:
            reg_sel.append(args)

        print reg_sel

        if isinstance(reg_sel[0], str):
            pass
        elif isinstance(reg_sel[0], int):
            map(self.WriteByAddress, reg_sel)
        else:
            raise TypeError("Invalid argument type.")
        #print self.__class__.__name__ ,': Writing to driver. addr:', self._addr, ' data:'
        #print 'memory_map_register',args
        #self._drv.write( self._addr, self._construct_reg())

    def WriteByAddress(self, addr):
        print 'WriteByAddress'
        pass
