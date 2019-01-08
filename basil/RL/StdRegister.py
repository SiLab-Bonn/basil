#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging
from basil.RL.Register import Register

logger = logging.getLogger(__name__)

class StdRegister(Register):
    def __init__(self, driver, conf):
        
        logger.warning('StdRegister has been depricated and is replaced by Register. BE AWARE: Offset point to LSB possition. Elements in repeat have diffrent orderd MSB..LSB.')
        
        super(StdRegister, self).__init__(driver, conf)
        
        if 'fields' in self._conf:
            for field in self._conf['fields']:

                if field['offset'] + 1 < field['size']:
                    raise ValueError("Register " + self._conf['name'] + ":" + field['name'] + ": Invalid offset value. Specify MSB position.")

    def init(self):
        super(StdRegister, self).init()
        self.set_configuration(self._init)

    def _construct_reg(self):

        for field in self._fields:
            offs = self._fields_conf[field]['offset']

            if 'repeat' in self._fields_conf[field]:
                for i, sub_field in enumerate(self._fields[field]):
                    bvstart = offs - i * self._get_field_config(field)['size']
                    bvstop = bvstart - len(sub_field._construct_reg()) + 1
#                     self._bv[bvstart:bvstop] = sub_field._construct_reg()
                    self._bv.set_slice_ba(bvstart, bvstop, sub_field._construct_reg())
            else:

                bvsize = len(self._fields[field])
                bvstart = offs
                bvstop = offs - bvsize + 1
#                 self._bv[bvstart:bvstop] = self._fields[field]
                self._bv.set_slice_ba(bvstart, bvstop, self._fields[field])

        return self._bv

    def _deconstruct_reg(self, reg):
        for field in self._fields:
            offs = self._get_field_config(field)['offset']
            bvsize = self._get_field_config(field)['size']
            bvstart = offs
            bvstop = offs - bvsize + 1
            if 'repeat' in self._get_field_config(field):
                size = self._get_field_config(field)['size']
                for i, ifield in enumerate(self._fields[field]):
                    ifield.set(reg[bvstart - size * i:bvstop - size * i])
            else:
                self._fields[field] = reg[bvstart:bvstop]
