#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 369                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-18 16:12:59 #$:
#

from basil.TL.TransferLayer import TransferLayer


class SerialDummy(TransferLayer):
    '''Dummy class for serial device
    ''' 
    def write(self, addr, data):
        pass

    def read(self, addr, size):
        pass