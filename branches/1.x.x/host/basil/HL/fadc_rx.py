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
from struct import pack, unpack


class fadc_rx(HardwareLayer):
    '''Fast ADC channel receiver
    '''
    def __init__(self, intf, conf):
        super(fadc_rx, self).__init__(intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_align_to_sync(self, value=False):
        '''
        Align data taking to a synchronization signal, reset signal is the synchronization signal (hard coded connection in Verilog source code)
        '''
        current = self._intf.read(self._conf['base_addr'] + 2, 1)[0]
        self._intf.write(self._conf['base_addr'] + 2, [(current & 0xfe) | value])

    def get_align_to_sync(self):
        return True if (self._intf.read(self._conf['base_addr'] + 2, 1)[0] & 0x01) else False

    def set_data_count(self, count):
        self._intf.write(self._conf['base_addr'] + 3, unpack('BBBB', pack('>L', count))[1:4])

    def get_data_count(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 3)
        return ret[0] * (2 ** 16) + ret[1] * (2 ** 8) + ret[2]

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 1)[0] & 0x01) else False
