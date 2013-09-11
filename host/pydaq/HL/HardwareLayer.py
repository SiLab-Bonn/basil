from pydaq import Base


class HardwareLayer(Base):

    _intf = None
    _base_addr = None

    def __init__(self, intf, conf):
        Base.__init__(self, conf)
        self._intf = intf
        self._base_addr = conf['base_addr']
