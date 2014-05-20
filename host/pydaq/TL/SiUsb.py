#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from TL.TransferLayer import TransferLayer
import SiLibUSB


class SiUsb (TransferLayer):

    BASE_ADDRESS_I2C = 0x00000
    HIGH_ADDRESS_I2C = BASE_ADDRESS_I2C + 256

    BASE_ADDRESS_EXTERNAL = 0x10000
    HIGH_ADDRESS_EXTERNAL = 0x10000 + 0x10000

    BASE_ADDRESS_BLOCK = 0x0001000000000000
    HIGH_ADDRESS_BLOCK = 0xffffffffffffffff

    _sidev = None

    def __init__(self, conf):
        TransferLayer.__init__(self, conf)
        #print self.__class__.__name__ ,"connecting to board:", conf['board_id']

    def init(self):
        self._sidev = SiLibUSB.SiUSBDevice()
        if 'bit_file' in self._conf.keys():
            print "FPGA Programming:", self._sidev.DownloadXilinx(self._conf['bit_file'])

    def write(self, addr, data):
        if(addr >= self.BASE_ADDRESS_I2C and addr < self.HIGH_ADDRESS_I2C):
            self._sidev.WriteI2C(addr - self.BASE_ADDRESS_I2C, data)
        elif(addr >= self.BASE_ADDRESS_EXTERNAL and addr < self.HIGH_ADDRESS_EXTERNAL):
            #print "SiUsb() addr=0x%x-0x%x, data="%(addr,self.BASE_ADDRESS_EXTERNAL),data
            self._sidev.WriteExternal(addr - self.BASE_ADDRESS_EXTERNAL, data)
        elif(addr >= self.BASE_ADDRESS_BLOCK and addr < self.HIGH_ADDRESS_BLOCK):
            self._sidev.FastBlockWrite(data)

    def read(self, addr, size):
        if(addr >= self.BASE_ADDRESS_I2C and addr < self.HIGH_ADDRESS_I2C):
            return self._sidev.ReadI2C(addr - self.BASE_ADDRESS_I2C, size)
        elif(addr >= self.BASE_ADDRESS_EXTERNAL and addr < self.HIGH_ADDRESS_EXTERNAL):
            data=self._sidev.ReadExternal(addr - self.BASE_ADDRESS_EXTERNAL, size)
            #print "SiUsb() addr=0x%x-0x%x, data="%(addr,self.BASE_ADDRESS_EXTERNAL),data
            return data
        elif(addr >= self.BASE_ADDRESS_BLOCK and addr < self.HIGH_ADDRESS_BLOCK):
            return self._sidev.FastBlockRead(size)
