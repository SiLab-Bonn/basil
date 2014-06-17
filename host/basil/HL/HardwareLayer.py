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
    '''Hardware Layer.

    Implementation of very basic register operations.
    '''
    _intf = None
    _base_addr = None

    def __init__(self, intf, conf):
        super(HardwareLayer, self).__init__(conf)
        self._intf = intf
        self._base_addr = conf['base_addr']

    def init(self):
        pass

    def _set_value(self, value, addr, size, offset):
        '''Writing a value of any arbitrary size (max. unsigned int 64) and offset to a register

        Parameters
        ----------
        value : int, str
            The register value (int, long, bit string) to be written.
        addr : int
            The register address.
        size : int
            Bit size/length of the value to be written to the register.
        offset : int
            Offset of the value to be written to the register (in number of bits).

        Returns
        -------
        nothing
        '''
        if not size and isinstance(value, (int, long)):
            raise ValueError('Size must be greater than zero')
        if isinstance(value, (int, long)) and value.bit_length() > size:
            raise ValueError('Value is too big for given size')
        elif isinstance(value, basestring) and size and len(value) != size:
            raise ValueError('Bit string does not match to the given size')
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._base_addr + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        if isinstance(value, (int, long)):
            reg[size + offset - 1:offset] = BitLogic.from_value(value, size=size)
        elif isinstance(value, basestring):
            reg[size + offset - 1:offset] = BitLogic(value)
        else:
            raise ValueError('Type not supported')
        self._intf.write(self._base_addr + addr, data=reg.tobytes())

    def _get_value(self, addr, size, offset):
        '''Reading a value of any arbitrary size (max. unsigned int 64) and offset from a register

        Parameters
        ----------
        addr : int
            The register address.
        size : int
            Bit size/length of the value.
        offset : int
            Offset of the value to be written to the register (in number of bits).

        Returns
        -------
        reg : int
            Register value.
        '''
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._base_addr + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        return reg[size + offset - 1:offset].tovalue()

    def _set_data(self, data, addr):
        '''Writing bytes of any arbitrary size

        Parameters
        ----------
        data : iterable
            The data (byte array) to be written.
        addr : int
            The register address.

        Returns
        -------
        nothing
        '''
        self._intf.write(self._conf['base_addr'] + addr, data)

    def _get_data(self, addr, size):
        '''Reading bytes of any arbitrary size

        Parameters
        ----------.
        addr : int
            The register address.
        size : int
            Byte length of the value.

        Returns
        -------
        data : iterable
            Byte array.
        '''
        return self._intf.read(self._conf['base_addr'] + addr, size)
