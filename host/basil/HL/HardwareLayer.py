#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from basil.dut import Base


class HardwareLayer(Base):

    _intf = None
    _base_addr = None

    def __init__(self, intf, conf):
        Base.__init__(self, conf)
        self._intf = intf
        self._base_addr = conf['base_addr']
