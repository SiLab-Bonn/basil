#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Base

class TransferLayer(Base):
    '''Transfer Layer implements simple API to abstract access to physical hardware.
    On error ``raise IOError``.
    '''
    
    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)

    def init(self):
        '''Initialize and connect to hardware.
        '''   
        pass
        
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
