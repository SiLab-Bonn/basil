#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Base


class HardwareLayer(Base):
    '''Hardware Layer.

    Implementation of very basic register operations.
    '''
    def __init__(self, intf, conf):
        super(HardwareLayer, self).__init__(conf)
        # interface not required
        if intf is not None:
            self._intf = intf
            self._base_addr = conf['base_addr']
