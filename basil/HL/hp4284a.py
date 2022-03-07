#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.scpi import scpi


class hp4284A(scpi):
    """
    Interface to the Hewlett-Packard Precision LCR-meter with additional functionality
    """

    def __init__(self, intf, conf):
        super().__init__(intf, conf)
