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


class TransferLayer(Base):
    '''Transfer Layer
    '''
    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)

    def read(self, addr, size):
        pass

    def write(self, addr, data):
        pass
