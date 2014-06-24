#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 367                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-18 16:10:35 #$:
#

from basil.dut import Base
from basil.utils.BitLogic import BitLogic

from array import array


class Dummy(HardwareLayer):
    '''Dummy Hardware Layer.

    Implementation of very basic register operations.
    '''
    def __init__(self, intf, conf):
        pass

    def init(self):
        pass

