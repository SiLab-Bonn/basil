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

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from struct import pack, unpack_from
from array import array


trigger_modes = {
    'EXTERNAL': 0,  # external trigger
    'NO_HANDSHAKE': 1,  # TLU no handshake
    'SIMPLE_HANDSHALKE': 2,  # TLU simple handshake
    'DATA_HANDSHAKE': 3  # TLU trigger data handshake
}


class tlu(RegisterHardwareLayer):
    '''TLU controller interface
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'TRIGGER_MODE': {'descr': {'addr': 1, 'size': 2, 'offset': 0}},
                  'TRIGGER_DATA_MSB_FIRST': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},
                  'EN_VETO': {'descr': {'addr': 1, 'size': 1, 'offset': 3}},
                  'TRIGGER_DATA_DELAY': {'descr': {'addr': 1, 'size': 4, 'offset': 4}},
                  'TRIGGER_CLOCK_CYCLES': {'descr': {'addr': 2, 'size': 5, 'offset': 0}},
                  'EN_TLU_RESET': {'descr': {'addr': 2, 'size': 1, 'offset': 5}},
                  'EN_INVERT_TRIGGER': {'descr': {'addr': 2, 'size': 1, 'offset': 6}},
                  'EN_WRITE_TIMESTAMP': {'descr': {'addr': 2, 'size': 1, 'offset': 7}},
                  'TRIGGER_LOW_TIMEOUT': {'descr': {'addr': 3, 'size': 8}},
                  'CURRENT_TLU_TRIGGER_NUMBER': {'descr': {'addr': 4, 'size': 32, 'properties': ['ro']}},
                  'TRIGGER_COUNTER': {'descr': {'addr': 8, 'size': 32}},
    }

    def __init__(self, intf, conf):
        super(tlu, self).__init__(intf, conf)

#    def init(self):
#        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], (0,))

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
        self._intf.write(self._conf['base_addr'] + 3, array('B', pack('B', value)))  # alternatively: unpack('B', pack('B', value))

    def get_current_tlu_trigger_number(self):
        '''Reading current trigger number.
        '''
        ret = self._intf.read(self._conf['base_addr'] + 4, size=4)
        return unpack_from('I', ret)[0]

    def set_trigger_counter(self, value):
        '''Setting trigger counter.
        '''
        self._intf.write(self._conf['base_addr'] + 8, array('B', pack('I', value)))

    def get_trigger_counter(self):
        '''Reading trigger counter.
        '''
        ret = self._intf.read(self._conf['base_addr'] + 8, size=4)
        return unpack_from('I', ret)[0]
