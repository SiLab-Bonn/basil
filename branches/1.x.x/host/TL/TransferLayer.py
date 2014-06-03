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

    def __init__(self, conf):
        Base.__init__(self, conf)

    def read(self, addr, size):
        pass

    def write(self, addr, data):
        pass

    def init(self):
        pass
