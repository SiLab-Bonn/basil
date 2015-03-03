#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.TL.TransferLayer import TransferLayer
import array


class Dummy(TransferLayer):
    '''Dummy device
    '''
    mem = {}  # dummy memory dictionary, keys are addresses, values are of type int

    def __init__(self, conf):
        super(Dummy, self).__init__(conf)
        print 'DummyTransferLayer.__init__'

    def init(self):
        print "DummyTransferLayer.init "
        print "DummyTransferLayer configuration:", str(self._conf)
        print 'DummyTransferLayer: clear dummy memory'
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
        print "DummyTransferLayer.write addr:", hex(addr), "data:", data
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
        print "DummyTransferLayer.read addr:", hex(addr), "size:", size
        return array.array('B', [self.mem[curr_addr] if curr_addr in self.mem else 0 for curr_addr in range(addr, addr + size)])
