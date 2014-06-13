#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 261                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-06 15:16:45 #$:
#

from basil.TL.TransferLayer import TransferLayer
import basil.utils.SimSiLibUsb as SiLibUSB

class SimSiUsb (TransferLayer):
    '''SiLab USB device
    '''
    BASE_ADDRESS_I2C = 0x00000
    HIGH_ADDRESS_I2C = BASE_ADDRESS_I2C + 256

    BASE_ADDRESS_EXTERNAL = 0x10000
    HIGH_ADDRESS_EXTERNAL = 0x10000 + 0x10000

    BASE_ADDRESS_BLOCK = 0x0001000000000000
    HIGH_ADDRESS_BLOCK = 0xffffffffffffffff

    _sidev = None

    def __init__(self, conf):
        super(SimSiUsb, self).__init__(conf)

    def init(self):
        self._sidev = SiLibUSB.SiUSBDevice()
        if 'bit_file' in self._conf.keys():
            print "FPGA Programming:", self._sidev.DownloadXilinx(self._conf['bit_file'])

    def write(self, addr, data):
        if(addr >= self.BASE_ADDRESS_I2C and addr < self.HIGH_ADDRESS_I2C):
            self._sidev.WriteI2C(addr - self.BASE_ADDRESS_I2C, data)
        elif(addr >= self.BASE_ADDRESS_EXTERNAL and addr < self.HIGH_ADDRESS_EXTERNAL):
            self._sidev.WriteExternal(addr - self.BASE_ADDRESS_EXTERNAL, data)
        elif(addr >= self.BASE_ADDRESS_BLOCK and addr < self.HIGH_ADDRESS_BLOCK):
            self._sidev.FastBlockWrite(data)

    def read(self, addr, size):
        if(addr >= self.BASE_ADDRESS_I2C and addr < self.HIGH_ADDRESS_I2C):
            return self._sidev.ReadI2C(addr - self.BASE_ADDRESS_I2C, size)
        elif(addr >= self.BASE_ADDRESS_EXTERNAL and addr < self.HIGH_ADDRESS_EXTERNAL):
            data = self._sidev.ReadExternal(addr - self.BASE_ADDRESS_EXTERNAL, size)
            return data
        elif(addr >= self.BASE_ADDRESS_BLOCK and addr < self.HIGH_ADDRESS_BLOCK):
            return self._sidev.FastBlockRead(size)
