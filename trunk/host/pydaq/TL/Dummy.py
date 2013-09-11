from TL.TransferLayer import TransferLayer


class Dummy (TransferLayer):

    def __init__(self, conf):
        TransferLayer.__init__(self, conf)

    def init(self):
        print "Init Dummy TransferLayer"
        print "Conf:", str(self._conf)

    def write(self, addr, data):
        #import traceback
        #for line in traceback.format_stack():
        #    print line.strip()

        print "DummyTransferLayer.write addr:", addr, "data:", data

    def read(self, addr, size):
        print "DummyTransferLayer.read addr:", addr, "size:", size
