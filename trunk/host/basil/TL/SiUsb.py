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
from SiLibUSB import GetUSBBoards, SiUSBDevice


class SiUsb (TransferLayer):
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
        super(SiUsb, self).__init__(conf)

    def init(self):
        if 'board_id' in self._conf.keys():
            self._sidev = SiUSBDevice.from_board_id(self._conf['board_id'])
        else:
            # search for any available device
            devices = GetUSBBoards()
            if not devices:
                raise IOError('Can\'t find USB board. Connect or reset USB board!')
            else:
                print 'Found following USB boards: {}'.format(', '.join(('%s with ID %s (FW %s)' % (device.board_name, filter(type(device.board_id).isdigit, device.board_id), filter(type(device.fw_version).isdigit, device.fw_version))) for device in devices))
                if len(devices) > 1:
                    raise ValueError('Please specify ID of USB board')
                self._sidev = devices[0]
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
