from HL.HardwareLayer import HardwareLayer
from struct import pack, unpack


class fadc_rx(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def start(self):
        self._intf.write(self._conf['base_addr'] + 1, [0])

    def set_data_count(self, count):
        self._intf.write(self._conf['base_addr'] + 3, unpack('BBBB', pack('>L', count))[1:4])

    def get_data_count(self):
        ret = self._intf.read(self._conf['base_addr'] + 3, 3)
        return ret[0] * (2 ** 16) + ret[1] * (2 ** 8) + ret[2]
