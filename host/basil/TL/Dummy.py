#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.TL.TransferLayer import TransferLayer
import array
import logging

class Dummy(TransferLayer):
    '''Dummy device
    '''
    mem = {}  # dummy memory dictionary, keys are addresses, values are of type int

    def __init__(self, conf):
        super(Dummy, self).__init__(conf)
        
    def init(self):
        logging.debug("DummyTransferLayer.init configuration: %s" % str(self._conf))
        self.mem = {}

    def write(self, addr, data):
        '''Write to dummy memory

        Parameters
        ----------
        addr : int
            The register address.
        data : list, tuple
            Data (byte array) to be written.

        Returns
        -------
        nothing
        '''
        logging.debug("DummyTransferLayer.write addr: %s data: %s" % (hex(addr), data))
        for curr_addr, d in enumerate(data, start=addr):
            self.mem[curr_addr] = array.array('B', [d])[0]  # write int

    def read(self, addr, size):
        '''
        Parameters
        ----------
        addr : int
            The register address.
        size : int
            Length of data to be read (number of bytes).

        Returns
        -------
        array : array
            Data (byte array) read from memory. Returns 0 for each byte if it hasn't been written to.
        '''
        logging.debug("DummyTransferLayer.read addr: %s size: %s" % (hex(addr), size))
        return array.array('B', [self.mem[curr_addr] if curr_addr in self.mem else 0 for curr_addr in range(addr, addr + size)])
