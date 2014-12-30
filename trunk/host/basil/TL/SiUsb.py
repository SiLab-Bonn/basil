#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import os

from basil.TL.TransferLayer import TransferLayer
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

    def init(self, **kwargs):
        self._init.setdefault('board_id', None)
        self._init.setdefault('avoid_download', False)
        if self._init['board_id'] and int(self._init['board_id']) >= 0:
            self._sidev = SiUSBDevice.from_board_id(self._init['board_id'])
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
        if 'bit_file' in self._init.keys():
            if 'avoid_download' in self._init.keys() and self._init['avoid_download'] is True and self._sidev.XilinxAlreadyLoaded():
                print "FPGA already programmed, skipping download"
            else:
                if os.path.exists(self._init['bit_file']):
                    bit_file = self._init['bit_file']
                elif os.path.exists(os.path.join(os.path.dirname(self.parent.conf_path), self._init['bit_file'])):
                    bit_file = os.path.join(os.path.dirname(self.parent.conf_path), self._init['bit_file'])
                else:
                    raise ValueError('No such bit file: %s' % self._init['bit_file'])
                print "Programming FPGA: %s ... %s" % (self._init['bit_file'], 'SUCCESS' if self._sidev.DownloadXilinx(bit_file) else 'FAILED')
        else:
            if not self._sidev.XilinxAlreadyLoaded():
                raise ValueError('FPGA not initialized, bit_file not specified')
            else:
                print "Programming FPGA: bit_file not specified"

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

    def get_configuration(self):
        conf = dict(self._init)
        conf['board_id'] = self._sidev.board_id
        return conf

    def close(self):
        self._sidev.dispose()
