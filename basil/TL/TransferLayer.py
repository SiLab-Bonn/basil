#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import abc

from basil.dut import Base


class TransferLayer(Base):
    '''Transfer Layer implements minimum API needed access to hardware.
    On error ``raise IOError``.
    '''
    __metaclass__ = abc.ABCMeta

    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)

    def init(self):
        '''Initialize and connect to hardware.
        '''
        pass

    @abc.abstractmethod
    def read(self):
        '''Read access.

        :rtype: None
        '''
        pass

    @abc.abstractmethod
    def write(self, data):
        '''Write access.

        :param data: array/list of bytes
        :type data: iterable
        :rtype: None

        '''
        pass
