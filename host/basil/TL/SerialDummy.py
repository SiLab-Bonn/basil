#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.TL.TransferLayer import TransferLayer


class SerialDummy(TransferLayer):
    '''Dummy class for serial device
    '''
    def write(self, addr, data):
        pass

    def read(self, addr, size):
        pass
