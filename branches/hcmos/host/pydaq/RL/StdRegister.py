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

    _bv = None

    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)
        self._size = conf['size']
        self._fields = dict()

        if 'fields' in self._conf:
            for field in self._conf['fields']:
                if 'repeat' in field:
                    reg_list = []
                    for _ in range(field['repeat']):
                        reg = StdRegister(None, field)
                        reg_list.append(reg)
                    self._fields[field['name']] = reg_list
                else:
                    bv = BitLogic(size=field['size'])
                    self._fields[field['name']] = bv

        self._bv = BitLogic(size=self._conf['size'])

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

            if 'bit_order' in self._get_filed_config(key):
                new_val = BitLogic(size=len(self._fields[key]))
                for i, bit in enumerate(self._get_filed_config(key)['bit_order']):
                    new_val[len(self._fields[key]) - 1 - i] = self._fields[key][bit]

                self._fields[key] = new_val

        elif isinstance(key, int):
            reg = self._construct_reg()
            reg[key] = value
            self._deconstruct_reg(reg)
        else:
            raise TypeError("Invalid argument type.")

    def __len__(self):
        return self._conf['size']

    def __str__(self):
        fields = dict()
        full = dict()

        reg = self._construct_reg()
        full[self._conf['name']] = str(len(reg)) + 'b' + str(reg)

        for field in self._fields:
            if 'repeat' in self._get_filed_config(field):
                for i, sub_reg in enumerate(self._fields[field]):
                    fields[str(field) + '[' + str(i) + ']'] = str(sub_reg)
            else:
                fields[field] = str(len(self._fields[field])) + 'b' + str(self._fields[field])

        if self._fields:
            return str([full, fields])
        else:
            return str(full)

    def set(self, value):
        if isinstance(value, int):
            bv = BitLogic(intVal=value, size=self._size)
        else:
            bv = BitLogic(bitstring=str(value))  ## TODO: added binary string ex "10100101". Should it be like "8b10100101"?
        self._deconstruct_reg(bv)

    def write(self):
        reg = self._construct_reg()
        ba = utils.bitvector_to_byte_array(reg)
        self._drv.set_data(0, ba)

    def read(self):
        raise NotImplementedError("To be implemented.")

    def _construct_reg(self):
        for field in self._fields:
            off = self._get_filed_config(field)['offset']
            if 'repeat' in self._get_filed_config(field):
                for i, sub_filed in enumerate(self._fields[field]):
                    bvstart = off - i * self._get_filed_config(field)['size']
                    bvstop = bvstart - len(sub_filed._construct_reg()) + 1
                    self._bv[bvstart:bvstop] = sub_filed._construct_reg()
            else:
                bvsize = len(self._fields[field])
                bvstart = off
                bvstop = off - bvsize + 1
                self._bv[bvstart:bvstop] = self._fields[field]
        return self._bv

    def _deconstruct_reg(self, new_reg):
        for field in self._fields:
            off = self._get_filed_config(field)['offset']
            if 'repeat' in self._get_filed_config(field):
                for i, sub_field in enumerate(self._fields[field]):
                    bvstart = off - i * self._get_filed_config(field)['size']
                    bvstop = bvstart - self._get_filed_config(field)['size'] + 1
                    sub_field._deconstruct_reg(new_reg[bvstart:bvstop])
            else:
                bvsize = len(self._fields[field])
                bvstart = off
                bvstop = off - bvsize + 1
                self._fields[field].setValue(bitstring=str(new_reg[bvstart:bvstop]))

    def _get_filed_config(self, field):
        if 'fields' in self._conf:
            return next((x for x in self._conf['fields'] if x['name'] == field), None)
        else:
            return ''
