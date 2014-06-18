#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from basil.TL.TransferLayer import TransferLayer
import array

from struct import unpack


class Dummy(TransferLayer):
    '''Dummy device
    '''
    mem = dict()  # dummy memory, keys are addresses, values are of type int

    def __init__(self, conf):
        super(Dummy, self).__init__(conf)

    def init(self):
        print "Init Dummy TransferLayer"
        print "Conf:", str(self._conf)

    def write(self, addr, data):
        #import traceback
        #for line in traceback.format_stack():
        #    print line.strip()
        print "DummyTransferLayer.write addr:", hex(addr), "data:", data
        for curr_addr, d in enumerate(data, start=addr):
            self.mem[curr_addr] = array.array('B', [d] )[0] #unpack('B', d)[0]

    def read(self, addr, size):
        print "DummyTransferLayer.read addr:", hex(addr), "size:", size
        return array.array('B', [self.mem[curr_addr] if curr_addr in self.mem else 0 for curr_addr in range(addr, addr + size)])
