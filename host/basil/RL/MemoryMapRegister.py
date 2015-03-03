#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


from basil.RL.StdRegister import StdRegister
from collections import Iterable


class MemoryMapRegister(StdRegister):

    def __init__(self, driver, conf):
        StdRegister.__init__(self, driver, conf)
#         self._fields = conf['fields']

#        for field in self._field_conf:
#            bv = BitLogic( size = field['size'] )

#            if 'offset' in field:
#                bv.offset = field['offset']
#            else:
#                bv.offset = field['address']*conf['width']+field['position']
#
#            self._fields[ field['name'] ] = bv

    def Write(self, args=None):
        reg_sel = list()
        if(args is None):
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
#         print self.__class__.__name__ ,': Writing to driver. addr:', self._addr, ' data:'
#         print 'memory_map_register',args
#         self._drv.write( self._addr, self._construct_reg())

    def WriteByAddress(self, addr):
        print 'WriteByAddress'
        pass
