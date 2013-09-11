from HL.HardwareLayer import HardwareLayer


class gpio(HardwareLayer):

    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def set_direction(self, direction):
        pass

    def get_direction(self):
        pass

    def write(self, value):
        pass

    def read(self):
        pass
