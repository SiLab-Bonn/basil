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

from basil.dut import Base
from basil.utils.BitLogic import BitLogic


class HardwareLayer(Base):

    _intf = None
    _base_addr = None

    def __init__(self, intf, conf):
        Base.__init__(self, conf)
        self._intf = intf
        self._base_addr = conf['base_addr']

    def _set(self, value, addr, size=8, offset=0):
        if not size:
            raise ValueError('Size must be greater than zero')
        if value.bit_length() > size:
            raise ValueError('Bit length of value is too big for given size')
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._conf['base_addr'] + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        reg[size + offset - 1:offset] = BitLogic.from_value(value)[size - 1:0]  # offset + size + 1:offset
        self._intf.write(self._conf['base_addr'] + addr, data=reg.tobytes())

    def _get(self, addr, size=8, offset=0):
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._conf['base_addr'] + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        return reg[size + offset - 1:offset].tovalue()
