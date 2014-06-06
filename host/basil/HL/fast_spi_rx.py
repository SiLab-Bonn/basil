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

from HL.HardwareLayer import HardwareLayer


class fast_spi_rx(HardwareLayer):
    '''Fast SPI interface
    '''
    def __init__(self, intf, conf):
        super(fast_spi_rx, self).__init__(intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def set_en(self, value=True):
        current = self._intf.read(self._conf['base_addr'] + 2, 1)[0]
        self._intf.write(self._conf['base_addr'] + 2, [(current & 0xfe) | value])

    def get_en(self):
        return True if (self._intf.read(self._conf['base_addr'] + 2, 1)[0] & 0x01) else False

    def get_lost_count(self):
        return self._intf.read(self._conf['base_addr'] + 3, 1)[0]
