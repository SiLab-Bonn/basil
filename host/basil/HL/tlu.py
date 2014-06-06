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

from basil.HL.HardwareLayer import HardwareLayer
from struct import pack, unpack_from
from array import array


trigger_modes = {
    0: 'external trigger',
    1: 'TLU no handshake',
    2: 'TLU simple handshake',
    3: 'TLU trigger data handshake'
}


class tlu(HardwareLayer):
    '''TLU controller interface
    '''
    def __init__(self, intf, conf):
        super(tlu, self).__init__(intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))
        self.reset()

    def get_lost_data_counter(self):
        ret = self._intf.read(self._conf['base_addr'], size=1)
        return unpack_from('B', ret)[0]

    def set_trigger_mode(self, value):
        if value not in trigger_modes.iterkeys():
            raise ValueError('Trigger mode does not exist')
        ret = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = unpack_from('B', ret)[0]
        reg = (value & 0x03) | (reg & 0xfc)
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def set_trigger_msb_first(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x04
        else:
            reg &= ~0x04
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def set_veto(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x08
        else:
            reg &= ~0x08
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def set_trigger_data_delay(self, value):
        if value < 0 or value > 15:
            raise ValueError('Value exceeds limits')
        ret = self._intf.read(self._conf['base_addr'] + 1, size=1)
        reg = unpack_from('B', ret)[0]
        reg = ((value & 0x0f) << 4) | (reg & 0x0f)
        self._intf.write(self._conf['base_addr'] + 1, data=(reg,))

    def set_trigger_clock_cycles(self, value):
        if value < 0 or value > 31:
            raise ValueError('Value exceeds limits')
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        reg = (value & 0x1f) | (reg & 0xe0)
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_tlu_reset(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x20
        else:
            reg &= ~0x20
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_invert_trigger(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x40
        else:
            reg &= ~0x40
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_write_timestamp(self, value):
        ret = self._intf.read(self._conf['base_addr'] + 2, size=1)
        reg = unpack_from('B', ret)[0]
        if value:
            reg |= 0x80
        else:
            reg &= ~0x80
        self._intf.write(self._conf['base_addr'] + 2, data=(reg,))

    def set_trigger_low_timeout(self, value):
        self._intf.write(self._conf['base_addr'] + 3, array.array('B', pack('B', value)))  # alternatively: unpack('B', pack('B', value))

    def get_current_tlu_trigger_number(self):
        '''Reading current trigger number.
        '''
        ret = self._intf.read(self._conf['base_addr'] + 4, size=4)
        return unpack_from('I', ret)[0]

    def set_trigger_counter(self, value):
        '''Setting trigger counter.
        '''
        self._intf.write(self._conf['base_addr'] + 8, array.array('B', pack('I', value)))

    def get_trigger_counter(self):
        '''Reading trigger counter.
        '''
        ret = self._intf.read(self._conf['base_addr'] + 8, size=4)
        return unpack_from('I', ret)[0]
