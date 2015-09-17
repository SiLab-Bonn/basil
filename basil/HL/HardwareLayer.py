#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Base


class HardwareLayer(Base):
    '''Hardware layer (HL) base class
    '''
    def __init__(self, intf, conf):
        super(HardwareLayer, self).__init__(conf)
        # interface not required for some cases
        if intf is not None:
            self._intf = intf
