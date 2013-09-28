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

from RL.RegisterLayer import RegisterLayer
from utils.BitLogic import BitLogic
from utils import utils


class StdRegister(RegisterLayer):

    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)
        self._size = conf['size']
        self._fields = dict()

        if 'fields' in conf:
            for field in conf['fields']:
                bv = BitLogic(size=field['size'])

                if 'offset' in field:
                    bv.offset = field['offset']
                else:
                    bv.offset = field['address'] * conf['width'] + field['position']

                self._fields[field['name']] = bv
        else:
            bv = BitLogic(size=self._conf['size'])
            bv.offset = self._conf['size'] - 1
            self._fields[conf['name']] = bv

    def __getitem__(self, items):
        #print '__getitem__', items
        return self._fields[items]

    def __setslice__(self, i, j, sequence):
        return self.__setitem__(slice(i, j), sequence)

    def __setitem__(self, key, value):
        if isinstance(key, slice):
            reg = self._construct_reg()
            reg[key.start:key.stop] = value
            self._deconstruct_reg(reg)
        elif isinstance(key, str):
            self._fields[key][self._fields[key].size - 1:0] = value
        elif isinstance(key, int):
            reg = self._construct_reg()
            reg[key] = value
            self._deconstruct_reg(reg)
        else:
            raise TypeError("Invalid argument type.")

    def __str__(self):
        fields = dict()
        full = dict()
        
        reg = self._construct_reg()
        full[self._conf['name']] = str(len(reg)) + 'b' + str(reg)

        for field in self._fields:
            if field != self._conf['name']:
                fields[field] = str(len(self._fields[field])) + 'b' + str(self._fields[field])
        
        return str([full, fields])

    def set(self, value):
        bv = BitLogic(intVal=value, size=self._size)
        self._deconstruct_reg(bv)

    def write(self):
        reg = self._construct_reg()
        ba = utils.bitvector_to_byte_array(reg)
        #print reg, ba
        self._drv.set_data(0, ba)
        
    def read(self):
        raise NotImplementedError("To be implemented.")
        #return self._drv.read()  # ????? //byte array

    def _construct_reg(self):
        bv = BitLogic(size=self._size)
        for field in self._fields:
            off = self._fields[field].offset
            bvsize = len(self._fields[field])
            bvstart = off
            bvstop = off - bvsize + 1
            bv[bvstart:bvstop] = self._fields[field]
        return bv

    def _deconstruct_reg(self, new_reg):
        for field in self._fields:
            off = self._fields[field].offset
            bvsize = len(self._fields[field])
            bvstart = off
            bvstop = off - bvsize + 1
            self._fields[field].setValue(bitstring=str(new_reg[bvstart:bvstop]))
