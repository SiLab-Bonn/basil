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

from pydaq import Base


class TransferLayer(Base):
    '''Transfer Layer
    '''
    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)

    def read(self, addr, size):
        pass

    def write(self, addr, data):
        pass

    def init(self):
        pass
