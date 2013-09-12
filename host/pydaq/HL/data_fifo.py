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


class data_fifo(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def init(self):
        self.reset()

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def get_size(self):
        ret = self._intf.read(self._conf['base_addr'] + 1, 3)
        return ret[0] * (2 ** 16) + ret[1] * (2 ** 8) + ret[2]

    def get_data(self, size='all'):
        if(size == 'all'):
            size = self.get_size()
        return self._intf.read(self._conf['base_data_addr'], size * 2)

    def get_error_count(self):
        return self._intf.read(self._conf['base_addr'] + 4, 1)[0]
