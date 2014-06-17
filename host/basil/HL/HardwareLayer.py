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

    def _set_value(self, value, addr, size=8, offset=0):  # TODO: allow bit string for value (e.g. '10011110')
        '''Writing a value of any arbitrary size (max. unsigned int 64) and offset to a register

        Parameters
        ----------
        value : int
            The register value to be written.
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
        if not size:
            raise ValueError('Size must be greater than zero')
        if value.bit_length() > size:
            raise ValueError('Bit length of value is too big for given size')
        div, mod = divmod(size + offset, 8)
        if mod:
            div += 1
        ret = self._intf.read(self._base_addr + addr, size=div)
        reg = BitLogic()
        reg.frombytes(ret.tostring())
        reg[size + offset - 1:offset] = BitLogic.from_value(value)[size - 1:0]  # offset + size + 1:offset
        self._intf.write(self._base_addr + addr, data=reg.tobytes())

    def _get_value(self, addr, size=8, offset=0):
        '''Reading a value of any arbitrary size (max. unsigned int 64) and offset from a register

        Parameters
        ----------
        addr : int
            The register address.
        size : int
            Bit size/length of the value to be written to the register.
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
        value : iterable
            The data () to be written.
        addr : int
            The register address.

        Returns
        -------
        nothing
        '''
        raise NotImplementedError('Has to be implemented')

    def _get_data(self, addr):
        '''Reading bytes of any arbitrary size

        Parameters
        ----------.
        addr : int
            The register address.

        Returns
        -------
        nothing
        '''
        raise NotImplementedError('Has to be implemented')
