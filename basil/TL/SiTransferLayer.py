#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.TL.TransferLayer import TransferLayer


class SiTransferLayer(TransferLayer):
    '''Multiplexing Transfer Layer implements abstract methods to access
    hardware with multiple endpoints.
    On error ``raise IOError``.
    '''

    def __init__(self, conf):
        super(SiTransferLayer, self).__init__(conf)

    def init(self):
        '''Initialize and connect to hardware.
        '''
        super(SiTransferLayer, self).init()

    def read(self, addr, size):
        '''Read access.

        :param addr: start transfer address
        :type addr: int
        :param size: size of transfer
        :type size: int
        :returns: data byte array
        :rtype: array.array('B')

        '''
        pass

    def write(self, addr, data):
        '''Write access.

        :param addr: start transfer address
        :type addr: int
        :param data: array/list of bytes
        :type data: iterable
        :rtype: None

        '''
        pass
