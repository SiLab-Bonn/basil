#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Base


class TransferLayer(Base):
    '''Transfer Layer implements minimum API needed access to hardware.
    On error ``raise IOError``.
    '''

    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)

    def init(self):
        '''Initialize and connect to hardware.
        '''
        super(TransferLayer, self).init()

    def read(self):
        '''Read access.

        :rtype: None
        '''
        raise NotImplementedError("read() not implemented")

    def write(self, data):
        '''Write access.

        :param data: array/list of bytes
        :type data: iterable
        :rtype: None

        '''
        raise NotImplementedError("write() not implemented")
