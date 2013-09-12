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


class spi(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_data_size(self, size):
        raise NotImplementedError("To be implemented.")

    def get_data_size(self):
        raise NotImplementedError("To be implemented.")

    def set_wait(self, wait_cyc):
        raise NotImplementedError("To be implemented.")

    def get_wait(self):
        raise NotImplementedError("To be implemented.")

    def set_repeat(self, wait_cyc):
        raise NotImplementedError("To be implemented.")

    def get_repeat(self):
        raise NotImplementedError("To be implemented.")

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'], 1)[0] & 0x01) else False

    def set_data(self, data, addr=0):
        self._intf.write(self._conf['base_addr'] + 8 + addr, data)

    def get_data(self, size=None, addr=0):
        if(size == None):
            size = self._conf['mem_bytes']

        return self._intf.read(self._conf['base_addr'] + 8 + self._conf['mem_bytes'], size)
