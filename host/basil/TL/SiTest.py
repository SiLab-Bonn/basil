#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


from basil.TL.SiTransferLayer import SiTransferLayer


class SiTest (SiTransferLayer):

    def __init__(self, conf):
        super(SiTest, self).__init__(conf)

    def write(self, addr, data):
        pass

    def read(self, addr, size):
        pass


if __name__ == '__main__':
    print 'CC'